// BE-403 MVP decision: reminder preference persistence (per-user/per-subscription
// mode + daysBefore) is documented in the API contract but not yet implemented
// in the database. Until that schema lands, every ACTIVE subscription uses this
// single fixed lead time.
export const RENEWAL_REMINDER_DAYS_BEFORE = 3;

export const RENEWAL_REMINDER_QUEUE = 'subscription-renewal-reminder';

export const RENEWAL_DISCOVERY_JOB = 'renewal-reminder-discovery';

export const RENEWAL_SEND_JOB = 'send-renewal-reminder';

export const RENEWAL_DISCOVERY_SCHEDULER_ID = 'renewal-reminder-discovery';

// '0 0 * * *' = every day at 00:00 UTC. The application treats
// next_renewal_date as a UTC instant consistently; there is no per-user
// timezone subsystem in v1.
export const RENEWAL_DISCOVERY_CRON_PATTERN = '0 0 * * *';
