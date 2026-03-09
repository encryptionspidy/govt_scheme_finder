import NodeCache from "node-cache";
import { env } from "../../config/env.js";

const cache = new NodeCache({
  stdTTL: env.cacheTtlSeconds,
  checkperiod: 120,
  useClones: false
});

export const cacheWrap = async (key, producer, ttl = env.cacheTtlSeconds) => {
  const cached = cache.get(key);
  if (cached !== undefined) {
    return cached;
  }

  const value = await producer();
  cache.set(key, value, ttl);
  return value;
};

export const cacheDeleteByPrefix = (prefix) => {
  const keys = cache.keys().filter((key) => key.startsWith(prefix));
  if (keys.length > 0) {
    cache.del(keys);
  }
};

export const cacheInstance = cache;
