/**
 * k6 load test for Subscription Track — DP-5 phase 7.
 *
 * RUN FROM THE DEV WORKSTATION ONLY, against the project's own Azure VM.
 * Never from the production host itself (the generator would compete with the
 * app for the same 2 vCPU) and never against anything else.
 *
 *   BASE_URL=https://<prod-domain> \
 *   TEST_EMAIL=loadtest@example.com TEST_PASSWORD='...' \
 *   k6 run infra/loadtest/loadtest.js
 *
 * Flow per iteration: login -> GET profile -> list subscriptions ->
 * create a mock subscription -> delete it. Everything it creates, it deletes.
 *
 * Every request carries a `name` tag that is a ROUTE TEMPLATE, never a URL
 * with an id in it. k6 tags become Prometheus labels in the k6 output and are
 * matched against the API's own `route` label in Grafana; a raw path here
 * would blow up cardinality on both sides (see apps/server/docs/metrics.md).
 */
import http from 'k6/http';
import { check, fail, sleep } from 'k6';
import { Counter, Rate } from 'k6/metrics';

const BASE_URL = (__ENV.BASE_URL || 'http://127.0.0.1:8080').replace(/\/+$/, '');
const TEST_EMAIL = __ENV.TEST_EMAIL;
const TEST_PASSWORD = __ENV.TEST_PASSWORD;

/**
 * Logging in on every iteration is the literal flow, but a login is a bcrypt
 * comparison: on a 2 vCPU burstable VM it costs more CPU than the other four
 * requests combined, so at 100 VUs the run measures bcrypt and nothing else.
 *
 * Default: each VU logs in once and reuses its token, re-authenticating only
 * if the API answers 401. Set LOGIN_EACH_ITERATION=true to run the flow
 * exactly as written — which is a useful separate experiment, not the one that
 * tells you whether the subscription endpoints are fast.
 */
const LOGIN_EACH_ITERATION = (__ENV.LOGIN_EACH_ITERATION || 'false') === 'true';

const loginFailures = new Counter('login_failures');
const flowCompleted = new Rate('flow_completed');
const createSkipped = new Counter('create_skipped_no_card');

export const options = {
  // 10 -> 50 -> 100 VUs, a short stress peak, then a cooldown that stays long
  // enough for the Grafana panels to show recovery rather than a cliff.
  stages: [
    { duration: '1m', target: 10 },   // warm-up: JIT, connection pool, Prisma
    { duration: '2m', target: 50 },   // nominal
    { duration: '2m', target: 100 },  // expected peak
    { duration: '1m', target: 150 },  // stress: past what the VM is sized for
    { duration: '2m', target: 0 },    // cooldown
  ],
  thresholds: {
    http_req_failed: ['rate<0.01'],
    'http_req_duration{expected_response:true}': ['p(95)<1000'],
    // Per-endpoint, so a slow write cannot hide behind fast reads.
    'http_req_duration{name:POST /auth/login}': ['p(95)<2000'],
    'http_req_duration{name:GET /users/me}': ['p(95)<800'],
    'http_req_duration{name:GET /subscriptions}': ['p(95)<1000'],
    'http_req_duration{name:POST /subscriptions}': ['p(95)<1500'],
    'http_req_duration{name:DELETE /subscriptions/:id}': ['p(95)<1000'],
    flow_completed: ['rate>0.95'],
    login_failures: ['count<10'],
  },
  // Burstable VM: a connection storm at the start of a stage is not the
  // signal we are after.
  noConnectionReuse: false,
  discardResponseBodies: false,
};

export function setup() {
  if (!TEST_EMAIL || !TEST_PASSWORD) {
    fail('TEST_EMAIL and TEST_PASSWORD must be set — see infra/loadtest/README.md');
  }
  const probe = http.get(`${BASE_URL}/health/ready`, { tags: { name: 'GET /health/ready' } });
  if (probe.status !== 200) {
    fail(`${BASE_URL}/health/ready answered ${probe.status}; refusing to load an unready target`);
  }
  return { baseUrl: BASE_URL };
}

/** VU-scoped token cache. Each VU is its own JS context, so this is per-VU. */
let token = null;

function login() {
  const response = http.post(
    `${BASE_URL}/auth/login`,
    JSON.stringify({ email: TEST_EMAIL, password: TEST_PASSWORD }),
    { headers: { 'Content-Type': 'application/json' }, tags: { name: 'POST /auth/login' } },
  );

  const ok = check(response, {
    'login returned 200/201': (r) => r.status === 200 || r.status === 201,
  });
  if (!ok) {
    loginFailures.add(1);
    return null;
  }
  // Responses are wrapped by the API's TransformInterceptor:
  //   { success, statusCode, data: { token, user }, timestamp }
  const body = response.json();
  return (body && body.data && body.data.token) || null;
}

function authHeaders() {
  return { headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' } };
}

export default function () {
  if (LOGIN_EACH_ITERATION || !token) {
    token = login();
  }
  if (!token) {
    flowCompleted.add(false);
    sleep(1);
    return;
  }

  // --- profile -------------------------------------------------------------
  let response = http.get(`${BASE_URL}/users/me`, {
    ...authHeaders(),
    tags: { name: 'GET /users/me' },
  });
  if (response.status === 401) {
    // Token expired mid-run; drop it and let the next iteration log in again.
    token = null;
    flowCompleted.add(false);
    return;
  }
  check(response, { 'profile 200': (r) => r.status === 200 });

  // --- list ----------------------------------------------------------------
  response = http.get(`${BASE_URL}/subscriptions`, {
    ...authHeaders(),
    tags: { name: 'GET /subscriptions' },
  });
  check(response, { 'list 200': (r) => r.status === 200 });

  // --- create --------------------------------------------------------------
  // A subscription must hang off a payment card, so look one up first. The
  // test account is expected to have at least one; without it the create and
  // delete steps are skipped and counted, rather than counted as failures of
  // the API.
  const cards = http.get(`${BASE_URL}/cards`, {
    ...authHeaders(),
    tags: { name: 'GET /cards' },
  });
  const cardList = cards.status === 200 ? (cards.json('data') || []) : [];
  const cardId = Array.isArray(cardList) && cardList.length > 0 ? cardList[0].id : null;

  if (!cardId) {
    createSkipped.add(1);
    flowCompleted.add(false);
    sleep(1);
    return;
  }

  const payload = JSON.stringify({
    payment_card_id: cardId,
    name: `k6-load-${__VU}-${__ITER}`,
    category: 'LoadTest',
    price: 1,
    billing_cycle: 'MONTHLY',
    notes: 'created by infra/loadtest/loadtest.js — safe to delete',
  });

  response = http.post(`${BASE_URL}/subscriptions`, payload, {
    ...authHeaders(),
    tags: { name: 'POST /subscriptions' },
  });
  const created = check(response, {
    'create 200/201': (r) => r.status === 200 || r.status === 201,
  });

  const createdId = created ? response.json('data.id') : null;

  // --- delete --------------------------------------------------------------
  // Tagged with the route TEMPLATE, not the id-bearing URL.
  let deleted = false;
  if (createdId) {
    response = http.del(`${BASE_URL}/subscriptions/${createdId}`, null, {
      ...authHeaders(),
      tags: { name: 'DELETE /subscriptions/:id' },
    });
    deleted = check(response, {
      'delete 200/204': (r) => r.status === 200 || r.status === 204,
    });
  }

  flowCompleted.add(Boolean(createdId) && deleted);

  // Think time. Without it, 100 VUs is 100 closed loops hammering as fast as
  // the server answers, which measures the generator as much as the target.
  sleep(1);
}

export function teardown() {
  // Nothing to clean up: every subscription created above is deleted in the
  // same iteration. An aborted run can leave rows named `k6-load-*`; the
  // README has the one-line cleanup.
}
