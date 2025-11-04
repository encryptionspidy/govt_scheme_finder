import NodeCache from "node-cache";
import { config } from "../config.js";

const cache = new NodeCache({ stdTTL: config.cache.ttlSeconds, checkperiod: 120 });

export const cacheWrap = async (key, producer, ttlSeconds = config.cache.ttlSeconds) => {
  const cached = cache.get(key);
  if (cached) {
    return cached;
  }

  const data = await producer();
  if (data !== undefined) {
    cache.set(key, data, ttlSeconds);
  }
  return data;
};

export const clearCache = () => cache.flushAll();
