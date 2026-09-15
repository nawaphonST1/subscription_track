/**
 * Worker runtime entrypoint boundary placeholder.
 *
 * Future phases (Phase 6 / ADD-ASYNC-01) will bootstrap the BullMQ worker
 * runtime from this entrypoint within the same monolithic codebase.
 * No queue implementation or fake worker behavior is included in this scaffold.
 */
async function bootstrapWorker(): Promise<void> {
  // Worker runtime bootstrap will be implemented in ADD-ASYNC-01.
}

if (require.main === module) {
  void bootstrapWorker();
}
