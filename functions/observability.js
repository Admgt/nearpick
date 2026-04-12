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

function getContextDataValue(data) {
  if (!data || typeof data !== "object") {
    return null;
  }

  const value = data.contextId;
  return typeof value === "string" ? value : null;
}

function normalizeContextId(value) {
  if (typeof value !== "string") {
    return null;
  }

  const trimmed = value.trim();
  if (!trimmed) {
    return null;
  }

  return trimmed.slice(0, 120);
}

function createContextId(source) {
  const headers = source?.headers ?? source?.rawRequest?.headers;
  const correlationId = getHeaderValue(headers, "x-correlation-id");
  const normalizedCorrelationId = normalizeContextId(correlationId);
  if (normalizedCorrelationId) {
    return normalizedCorrelationId;
  }

  const requestId = getHeaderValue(headers, "x-request-id");
  const normalizedRequestId = normalizeContextId(requestId);
  if (normalizedRequestId) {
    return normalizedRequestId;
  }

  const traceContext = getHeaderValue(headers, "x-cloud-trace-context");
  const traceId = normalizeContextId(traceContext?.split("/")[0]);
  if (traceId) {
    return traceId;
  }

  const dataContextId = normalizeContextId(getContextDataValue(source?.data));
  if (dataContextId) {
    return dataContextId;
  }

  const sourceId = normalizeContextId(source?.id);
  if (sourceId) {
    return sourceId;
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
