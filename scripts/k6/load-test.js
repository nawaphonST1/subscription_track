import http from 'k6/http';
import { check, group, sleep } from 'k6';
import { Counter, Rate, Trend } from 'k6/metrics';

// ============================================================================
// Custom Metrics for Deep Performance & Ceiling Analysis
// ============================================================================
const dashboardLatency = new Trend('dashboard_total_latency', true);
const creepScoreLatency = new Trend('creep_score_latency', true);
const cacheMissLatency = new Trend('cache_miss_calculation_latency', true);
const mutationLatency = new Trend('subscription_mutation_latency', true);
const successfulOperations = new Counter('successful_operations');
const failedOperations = new Counter('failed_operations');
const errorRate = new Rate('system_error_rate');

// ============================================================================
// Test Execution Configuration
// Profiles:
//   - combined (default): Realistic baseline -> Peak load -> Ceiling Stress -> Recovery
//   - realistic: 10 - 50 VUs with realistic user think times (0.5s - 2s)
//   - ceiling: Aggressive ramp-up (50 -> 150 -> 350 -> 500 VUs) with rapid fire (0.05s think time)
//   - spike: Sudden traffic surge (0 -> 300 VUs in 10s)
// ============================================================================
const PROFILE = __ENV.TEST_PROFILE || 'combined';

function getStages(profile) {
  switch (profile) {
    case 'smoke':
      return [
        { duration: '10s', target: 2 }, // Quick 10s smoke test with 2 VUs
      ];
    case 'realistic':
      return [
        { duration: '30s', target: 15 }, // Warm-up
        { duration: '1m', target: 50 },  // Steady realistic daily traffic
        { duration: '30s', target: 0 },  // Cool-down
      ];
    case 'ceiling':
      // Fast, aggressive ramp-up to find system ceiling & breaking point
      return [
        { duration: '20s', target: 50 },   // Initial pressure
        { duration: '40s', target: 150 },  // Node.js Event Loop stress
        { duration: '40s', target: 300 },  // Database Connection Pool limit search
        { duration: '40s', target: 500 },  // Saturation / Breaking ceiling
        { duration: '30s', target: 0 },    // Recovery inspection
      ];
    case 'spike':
      return [
        { duration: '10s', target: 10 },
        { duration: '10s', target: 300 }, // Sudden spike
        { duration: '1m', target: 300 },  // Sustained spike
        { duration: '15s', target: 0 },
      ];
    case 'combined':
    default:
      return [
        // 1. Warm-up & Cache Priming (Realistic user pace)
        { duration: '30s', target: 20 },
        // 2. Peak Traffic Simulation (Heavy day load)
        { duration: '1m', target: 80 },
        // 3. Ceiling Stress Ramp-up (Aggressive high-throughput push)
        { duration: '1m', target: 200 },
        // 4. Overload / Saturation Peak (Testing max capacity)
        { duration: '45s', target: 350 },
        // 5. Ramp-down & Graceful Recovery
        { duration: '30s', target: 0 },
      ];
  }
}

export const options = {
  scenarios: {
    user_traffic: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: getStages(PROFILE),
      gracefulRampDown: '10s',
    },
  },
  thresholds: {
    // Overall HTTP errors must remain < 5% during stress and < 1% normally
    system_error_rate: ['rate<0.05'],
    http_req_failed: ['rate<0.05'],
    // 95% of requests should complete within 600ms (accounting for internet RTT to Azure VM)
    http_req_duration: ['p(95)<600', 'p(99)<1500'],
    // Dashboard bundle response time
    dashboard_total_latency: ['p(95)<800'],
    // Creep score (cached) response time
    creep_score_latency: ['p(95)<400'],
  },
};

// ============================================================================
// Helper: Extract auth token & user ID from NestJS wrapped response
// ============================================================================
function parseAuth(res) {
  try {
    const body = JSON.parse(res.body);
    const data = body.data || body;
    const token = data.token || data.access_token || body.token;
    const user = data.user || body.user;
    const userId = user ? user.id : null;
    return { token, userId };
  } catch (_) {
    return { token: null, userId: null };
  }
}

// ============================================================================
// Setup Lifecycle: Auto-detects URL, registers/authenticates test user
// ============================================================================
export function setup() {
  // 1. Auto-detect Target URL (detect 8080 direct vs 3000 nginx)
  let baseUrl = __ENV.TARGET_URL;
  if (!baseUrl) {
    const probe8080 = http.get('http://localhost:8080/health', { timeout: '2s' });
    if (probe8080.status === 200) {
      baseUrl = 'http://localhost:8080';
    } else {
      baseUrl = 'http://localhost:3000';
    }
  }

  console.log(`\n======================================================`);
  console.log(`[k6] Starting Subscription Track Load & Ceiling Test`);
  console.log(`[k6] Target Base URL : ${baseUrl}`);
  console.log(`[k6] Test Profile    : ${PROFILE}`);
  console.log(`======================================================\n`);

  // 2. Health check
  const healthRes = http.get(`${baseUrl}/health`, { timeout: '5s' });
  if (healthRes.status !== 200) {
    console.warn(`[k6 Warning] /health responded with status ${healthRes.status} at ${baseUrl}.`);
  }

  // 3. Setup Distributed User Pool
  const poolSize = parseInt(__ENV.USER_POOL_SIZE || '15', 10);
  console.log(`[k6 Setup] Initializing User Pool with ${poolSize} distinct test users...`);
  const regHeaders = { 'Content-Type': 'application/json' };
  const userPool = [];

  for (let i = 1; i <= poolSize; i++) {
    const testUser = {
      email: `k6_tester_pool_${i}@subscriptiontrack.dev`,
      password: 'Password123!',
      name: `K6 Tester ${i}`,
      monthly_income: 50000 + i * 1000,
      security_pin: '123456',
    };

    let userToken = null;
    let userId = null;
    let cardId = null;

    // Try register
    const regRes = http.post(
      `${baseUrl}/auth/register`,
      JSON.stringify(testUser),
      { headers: regHeaders, timeout: '10s' },
    );

    if (regRes.status === 201) {
      const authData = parseAuth(regRes);
      userToken = authData.token;
      userId = authData.userId;
    } else {
      // Fallback: Login
      const loginRes = http.post(
        `${baseUrl}/auth/login`,
        JSON.stringify({ email: testUser.email, password: testUser.password }),
        { headers: regHeaders, timeout: '10s' },
      );
      if (loginRes.status === 200) {
        const authData = parseAuth(loginRes);
        userToken = authData.token;
        userId = authData.userId;
      }
    }

    if (userToken) {
      const authHeaders = {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${userToken}`,
      };

      // Check existing active cards
      const activeCardsRes = http.get(`${baseUrl}/cards`, { headers: authHeaders });
      if (activeCardsRes.status === 200) {
        try {
          const cardsBody = JSON.parse(activeCardsRes.body);
          const cards = cardsBody.data || cardsBody;
          if (Array.isArray(cards) && cards.length > 0) {
            cardId = cards[0].id;
          }
        } catch (_) {}
      }

      // Link mock bank card if none
      if (!cardId) {
        const mockCardsRes = http.get(`${baseUrl}/cards/mock`, { headers: authHeaders });
        if (mockCardsRes.status === 200) {
          try {
            const body = JSON.parse(mockCardsRes.body);
            const mockCards = body.data || body;
            if (Array.isArray(mockCards) && mockCards.length > 0) {
              const linkRes = http.post(
                `${baseUrl}/cards/link`,
                JSON.stringify({ mock_card_id: mockCards[0].id }),
                { headers: authHeaders },
              );
              if (linkRes.status === 201 || linkRes.status === 200) {
                const cardData = JSON.parse(linkRes.body);
                const cardObj = cardData.data || cardData;
                cardId = cardObj.id || cardObj.card?.id;
              }
            }
          } catch (_) {}
        }
      }

      userPool.push({
        token: userToken,
        userId: userId,
        cardId: cardId,
      });
    }
  }

  if (userPool.length === 0) {
    throw new Error(
      `[k6 Setup Failed] Could not authenticate any test users in pool against ${baseUrl}.`,
    );
  }

  console.log(`[k6 Setup Complete] Ready with ${userPool.length} users in pool.\n`);

  return {
    baseUrl: baseUrl,
    userPool: userPool,
    profile: PROFILE,
  };
}

// ============================================================================
// Default Scenario: Realistic Multi-Journey User Execution
// ============================================================================
export default function (data) {
  const { baseUrl, userPool, profile } = data;
  const isCeilingMode = profile === 'ceiling' || profile === 'spike';

  // Distribute virtual users across the user pool to avoid cross-user cache thrashing
  const currentUser = userPool[(__VU - 1) % userPool.length];
  const { token, cardId } = currentUser;

  // Common headers with valid Bearer Token
  const authHeaders = {
    'Content-Type': 'application/json',
    Authorization: `Bearer ${token}`,
  };

  // --------------------------------------------------------------------------
  // Action 1: Public Catalog Discovery (~20% chance) - Tests 24h Preset Cache
  // --------------------------------------------------------------------------
  if (Math.random() < 0.2) {
    group('01_Public_Catalog_Browsing', () => {
      const pkgRes = http.get(`${baseUrl}/packages`, { headers: authHeaders });
      const ok = check(pkgRes, {
        'packages returned 200': (r) => r.status === 200,
        'packages response time < 100ms': (r) => r.timings.duration < 100,
      });

      if (!ok) {
        failedOperations.add(1);
        errorRate.add(1);
      } else {
        successfulOperations.add(1);
        errorRate.add(0);
      }
    });
  }

  // --------------------------------------------------------------------------
  // Action 2: Core Dashboard Experience (70-80% of normal user behavior)
  // Loads profile, cards, subscriptions, upcoming, and creep score concurrently.
  // Tests Security Auth Cache (180s) and Creep Score Cache (900s).
  // --------------------------------------------------------------------------
  group('02_Dashboard_Batch_Load', () => {
    const dashboardStart = Date.now();

    // Concurrent batch request mimicking Flutter client
    const responses = http.batch([
      ['GET', `${baseUrl}/users/me`, null, { headers: authHeaders, tags: { name: 'GetProfile' } }],
      ['GET', `${baseUrl}/cards`, null, { headers: authHeaders, tags: { name: 'GetCards' } }],
      ['GET', `${baseUrl}/subscriptions`, null, { headers: authHeaders, tags: { name: 'GetSubscriptions' } }],
      ['GET', `${baseUrl}/subscriptions/upcoming?limit=5`, null, { headers: authHeaders, tags: { name: 'GetUpcoming' } }],
      ['GET', `${baseUrl}/creep-score`, null, { headers: authHeaders, tags: { name: 'GetCreepScore' } }],
    ]);

    const dashboardDuration = Date.now() - dashboardStart;
    dashboardLatency.add(dashboardDuration);

    const [meRes, cardsRes, subsRes, upcomingRes, creepRes] = responses;

    const allOk = check(responses, {
      'users/me is 200': () => meRes.status === 200,
      'cards is 200': () => cardsRes.status === 200,
      'subscriptions is 200': () => subsRes.status === 200,
      'upcoming is 200': () => upcomingRes.status === 200,
      'creep-score is 200': () => creepRes.status === 200,
    });

    if (creepRes.status === 200) {
      creepScoreLatency.add(creepRes.timings.duration);
    }

    if (!allOk) {
      failedOperations.add(1);
      errorRate.add(1);
    } else {
      successfulOperations.add(1);
      errorRate.add(0);
    }
  });

  // --------------------------------------------------------------------------
  // Action 3: Savings Optimizer Exploration (~15% chance)
  // --------------------------------------------------------------------------
  if (Math.random() < 0.15) {
    group('03_Savings_Exploration', () => {
      const optRes = http.get(`${baseUrl}/savings/optimizer`, { headers: authHeaders });
      const ok = check(optRes, {
        'savings optimizer is 200': (r) => r.status === 200,
      });

      if (!ok) {
        failedOperations.add(1);
        errorRate.add(1);
      } else {
        successfulOperations.add(1);
        errorRate.add(0);
      }
    });
  }

  // --------------------------------------------------------------------------
  // Action 4: Data Mutation & Cache Eviction Stress (~10% chance)
  // Creates a subscription -> triggers Creep Score Eviction -> verifies Recalculation
  // --------------------------------------------------------------------------
  if (cardId && Math.random() < 0.1) {
    group('04_Mutation_And_Eviction_Flow', () => {
      const subPayload = JSON.stringify({
        name: `k6-sub-${__VU}-${Date.now()}`,
        category: 'Streaming',
        price: 399,
        billing_cycle: 'MONTHLY',
        payment_card_id: cardId,
      });

      // 1. Create subscription (Evicts cache:user:{id}:creep-score)
      const mutateStart = Date.now();
      const createRes = http.post(`${baseUrl}/subscriptions`, subPayload, { headers: authHeaders });
      mutationLatency.add(Date.now() - mutateStart);

      const createdOk = check(createRes, {
        'subscription created (201)': (r) => r.status === 201,
      });

      if (createdOk && createRes.body) {
        try {
          const resObj = JSON.parse(createRes.body);
          const createdSub = resObj.data || resObj;

          // 2. Immediately read Creep Score (Must calculate fresh from DB after eviction)
          const missStart = Date.now();
          const freshCreepRes = http.get(`${baseUrl}/creep-score`, { headers: authHeaders });
          cacheMissLatency.add(Date.now() - missStart);

          check(freshCreepRes, {
            'fresh creep score calculated (200)': (r) => r.status === 200,
          });

          // 3. Clean up test subscription to prevent unbounded database bloat
          if (createdSub && createdSub.id) {
            http.del(`${baseUrl}/subscriptions/${createdSub.id}`, null, { headers: authHeaders });
          }
        } catch (_) {}
      }
    });
  }

  // --------------------------------------------------------------------------
  // Think Time between iterations:
  // Realistic: 0.4s - 1.2s
  // Ceiling Stress: 0.05s - 0.15s (Pounding server to discover maximum RPS/Ceiling)
  // --------------------------------------------------------------------------
  if (isCeilingMode) {
    sleep(0.05 + Math.random() * 0.1);
  } else {
    sleep(0.4 + Math.random() * 0.8);
  }
}

// ============================================================================
// Teardown Lifecycle
// ============================================================================
export function teardown() {
  console.log(`\n======================================================`);
  console.log(`[k6] Load Test Completed Successfully.`);
  console.log(`======================================================\n`);
}
