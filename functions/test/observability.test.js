const test = require("node:test");
const assert = require("node:assert/strict");

const {
  buildHealthPayload,
  createContextId,
} = require("../observability");

test("createContextId prefers explicit correlation headers", () => {
  const contextId = createContextId({
    headers: {
      "x-correlation-id": "corr-123",
      "x-request-id": "req-456",
    },
  });

  assert.equal(contextId, "corr-123");
});

test("createContextId falls back to cloud trace context header", () => {
  const contextId = createContextId({
    headers: {
      "x-cloud-trace-context": "trace-123/span-1;o=1",
    },
  });

  assert.equal(contextId, "trace-123");
});

test("createContextId falls back to callable data contextId", () => {
  const contextId = createContextId({
    data: {
      contextId: "app-context-123",
    },
  });

  assert.equal(contextId, "app-context-123");
});

test("buildHealthPayload returns the expected minimum health schema", () => {
  const payload = buildHealthPayload({
    contextId: "ctx-1",
    firestoreStatus: "ok",
    latencyMs: 12,
    status: "ok",
  });

  assert.equal(payload.service, "nearpick-functions");
  assert.equal(payload.status, "ok");
  assert.equal(payload.contextId, "ctx-1");
  assert.equal(payload.latencyMs, 12);
  assert.deepEqual(payload.checks, {
    runtime: "ok",
    firestore: "ok",
  });
  assert.match(payload.timestamp, /^\d{4}-\d{2}-\d{2}T/);
});
