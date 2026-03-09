import fs from "fs";
import path from "path";
import crypto from "crypto";

import axios from "axios";
import { load } from "cheerio";

const OUTPUT_PATH = process.env.MYSCHEME_OUTPUT_PATH || "./data/external/myscheme_raw.json";
const START_URL = process.env.MYSCHEME_START_URL || "https://www.myscheme.gov.in/search";
const MAX_PAGES = Number(process.env.MYSCHEME_MAX_PAGES || 8);
const TIMEOUT_MS = Number(process.env.MYSCHEME_TIMEOUT_MS || 15000);

const http = axios.create({ timeout: TIMEOUT_MS, maxRedirects: 5 });

const ensureDir = (filePath) => {
  const dir = path.dirname(filePath);
  fs.mkdirSync(dir, { recursive: true });
};

const absoluteUrl = (base, candidate) => {
  try {
    return new URL(candidate, base).toString();
  } catch (_error) {
    return null;
  }
};

const normalizeText = (value) => String(value || "").replace(/\s+/g, " ").trim();

const parseSchemaBlocks = ($, pageUrl) => {
  const out = [];
  $("script[type='application/ld+json']").each((_, el) => {
    const raw = $(el).text();
    if (!raw) return;
    try {
      const parsed = JSON.parse(raw);
      const list = Array.isArray(parsed) ? parsed : [parsed];
      for (const item of list) {
        const title = normalizeText(item?.name || item?.headline || "");
        const description = normalizeText(item?.description || "");
        if (!title || !description) continue;

        out.push({
          id: `myscheme-${crypto.createHash("md5").update(`${title}|${description}`).digest("hex")}`,
          title: { en: title, ta: "" },
          shortDescription: { en: description, ta: "" },
          category: "Government Scheme",
          ministry: normalizeText(item?.publisher?.name || item?.author?.name || ""),
          eligibility: { states: ["All India"] },
          applicationUrl: item?.url || pageUrl,
          officialSource: pageUrl,
          source: "myscheme"
        });
      }
    } catch (_error) {
      // Ignore malformed blocks and continue.
    }
  });
  return out;
};

const parseCardCandidates = ($, pageUrl) => {
  const out = [];
  const selectors = [
    "article",
    "[data-testid*='scheme']",
    "[class*='scheme-card']",
    "[class*='schemeCard']",
    ".card"
  ];

  for (const selector of selectors) {
    $(selector).each((_, el) => {
      const root = $(el);
      const title = normalizeText(
        root.find("h1, h2, h3, [class*='title'], [class*='name']").first().text()
      );
      const description = normalizeText(
        root.find("p, [class*='description'], [class*='summary']").first().text()
      );

      if (!title || !description) return;

      const href = root.find("a[href]").first().attr("href");
      const page = href ? absoluteUrl(pageUrl, href) : pageUrl;
      out.push({
        id: `myscheme-${crypto.createHash("md5").update(`${title}|${description}`).digest("hex")}`,
        title: { en: title, ta: "" },
        shortDescription: { en: description, ta: "" },
        category: "Government Scheme",
        eligibility: { states: ["All India"] },
        applicationUrl: page,
        officialSource: pageUrl,
        source: "myscheme"
      });
    });

    if (out.length > 0) break;
  }

  return out;
};

const parseNextUrls = ($, pageUrl) => {
  const out = [];
  const nextRel = $("a[rel='next']").attr("href");
  if (nextRel) {
    const url = absoluteUrl(pageUrl, nextRel);
    if (url) out.push(url);
  }

  $("a[href]").each((_, el) => {
    const anchor = $(el);
    const label = normalizeText(anchor.text()).toLowerCase();
    if (!["next", "next >", ">"].includes(label)) return;
    const href = anchor.attr("href");
    if (!href) return;
    const url = absoluteUrl(pageUrl, href);
    if (url) out.push(url);
  });

  return Array.from(new Set(out));
};

const dedupeById = (items) => {
  const seen = new Set();
  const out = [];
  for (const item of items) {
    if (seen.has(item.id)) continue;
    seen.add(item.id);
    out.push(item);
  }
  return out;
};

const crawl = async () => {
  const queue = [START_URL];
  const visited = new Set();
  const records = [];

  while (queue.length > 0 && visited.size < MAX_PAGES) {
    const pageUrl = queue.shift();
    if (!pageUrl || visited.has(pageUrl)) continue;
    visited.add(pageUrl);

    try {
      const response = await http.get(pageUrl, {
        headers: {
          "User-Agent": "SchemeFinderBot/1.0 (+https://myscheme.gov.in)",
          Accept: "text/html,application/xhtml+xml"
        }
      });

      const html = String(response.data || "");
      const $ = load(html);

      const schemaItems = parseSchemaBlocks($, pageUrl);
      const cardItems = parseCardCandidates($, pageUrl);
      records.push(...schemaItems, ...cardItems);

      const nextUrls = parseNextUrls($, pageUrl);
      for (const nextUrl of nextUrls) {
        if (!visited.has(nextUrl) && queue.length < MAX_PAGES * 2) {
          queue.push(nextUrl);
        }
      }

      console.log(`[myscheme_crawler] crawled: ${pageUrl}`);
    } catch (error) {
      console.warn(`[myscheme_crawler] failed: ${pageUrl} (${error.message})`);
    }
  }

  return dedupeById(records);
};

const run = async () => {
  const outputPath = path.resolve(process.cwd(), OUTPUT_PATH);
  ensureDir(outputPath);

  const records = await crawl();
  fs.writeFileSync(outputPath, JSON.stringify(records, null, 2));

  console.log(`[myscheme_crawler] output: ${outputPath}`);
  console.log(`[myscheme_crawler] records: ${records.length}`);
};

run();
