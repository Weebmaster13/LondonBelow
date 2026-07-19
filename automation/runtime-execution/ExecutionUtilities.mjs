export function isPlainObject(value) {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

export function deepClone(value) {
  if (Array.isArray(value)) {
    return value.map((item) => deepClone(item));
  }

  if (isPlainObject(value)) {
    const output = {};
    for (const [key, child] of Object.entries(value)) {
      output[key] = deepClone(child);
    }
    return output;
  }

  return value;
}

export function deepFreeze(value) {
  if (Array.isArray(value)) {
    for (const item of value) {
      deepFreeze(item);
    }
    return Object.freeze(value);
  }

  if (isPlainObject(value)) {
    for (const child of Object.values(value)) {
      deepFreeze(child);
    }
    return Object.freeze(value);
  }

  return value;
}

export function result(ok, reason = null, failure = null, details = {}) {
  return { ok, reason, failure, ...details };
}

export function validateIdentifier(value, label) {
  return typeof value === "string" && value.trim() !== ""
    ? result(true)
    : result(false, `${label} invalid`, "InvalidIdentifier");
}

export function exactFields(value, fields, label) {
  if (!isPlainObject(value)) {
    return result(false, `${label} must be an object`, "SchemaMismatch");
  }

  for (const field of fields) {
    if (!(field in value)) {
      return result(false, `${label} missing ${field}`, "SchemaMismatch");
    }
  }

  for (const key of Object.keys(value)) {
    if (!fields.includes(key)) {
      return result(false, `${label} contains unsupported field ${key}`, "SchemaMismatch");
    }
  }

  return result(true);
}

export function stableSerialize(value) {
  if (Array.isArray(value)) {
    return `[${value.map((item) => stableSerialize(item)).join(",")}]`;
  }

  if (isPlainObject(value)) {
    return `{${Object.keys(value)
      .sort()
      .map((key) => `${JSON.stringify(key)}:${stableSerialize(value[key])}`)
      .join(",")}}`;
  }

  return JSON.stringify(value);
}
