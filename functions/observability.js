const {randomUUID} = require("node:crypto");

function getHeaderValue(headers, name) {
  if (!headers || typeof headers !== "object") {
    return null;
  }

  const direct = headers[name];
  const normalized = headers[name.toLowerCase()];
  const value = direct ?? normalized;

  if (Array.isArray(value)) {
    return typeof value[0] === "string" ? value[0] : null;
  }

  return typeof value === "string" ? value : null;
}

function createContextId(source) {
  const headers = source?.headers ?? source?.rawRequest?.headers;
  const correlationId = getHeaderValue(headers, "x-correlation-id");
  if (correlationId && correlationId.trim().length > 0) {
    return correlationId.trim();
  }

  const requestId = getHeaderValue(headers, "x-request-id");
  if (requestId && requestId.trim().length > 0) {
    return requestId.trim();
  }

  const traceContext = getHeaderValue(headers, "x-cloud-trace-context");
  if (traceContext && traceContext.trim().length > 0) {
    return traceContext.split("/")[0].trim();
  }

  if (typeof source?.id === "string" && source.id.trim().length > 0) {
    return source.id.trim();
  }

  return randomUUID();
}

function serializeError(error) {
  if (!error) {
    return undefined;
  }

  return {
    code: typeof error.code === "string" ? error.code : undefined,
    message: typeof error.message === "string" ? error.message : String(error),
    name: typeof error.name === "string" ? error.name : undefined,
  };
}

function writeLog(method, severity, event, fields = {}, error) {
  const payload = {
    severity,
    event,
    timestamp: new Date().toISOString(),
    ...fields,
  };

  const serializedError = serializeError(error);
  if (serializedError) {
    payload.error = serializedError;
  }

  console[method](JSON.stringify(payload));
}

function logInfo(event, fields = {}) {
  writeLog("log", "INFO", event, fields);
}

function logWarn(event, fields = {}, error) {
  writeLog("warn", "WARNING", event, fields, error);
}

function logError(event, fields = {}, error) {
  writeLog("error", "ERROR", event, fields, error);
}

function buildHealthPayload({
  contextId,
  firestoreStatus,
  latencyMs,
  status,
}) {
  return {
    service: "nearpick-functions",
    status,
    timestamp: new Date().toISOString(),
    contextId,
    latencyMs,
    checks: {
      runtime: "ok",
      firestore: firestoreStatus,
    },
  };
}

module.exports = {
  buildHealthPayload,
  createContextId,
  logError,
  logInfo,
  logWarn,
};
