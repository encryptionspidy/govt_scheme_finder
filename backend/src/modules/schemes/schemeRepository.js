import { queryAll, queryOne, run, withTransaction } from "../../infrastructure/db/sqlite.js";

const parseJson = (value, fallback) => {
  try {
    if (value == null || value === "") return fallback;
    return JSON.parse(value);
  } catch (_error) {
    return fallback;
  }
};

const aggregateBySchemeId = (rows, mapper) => {
  const map = new Map();
  for (const row of rows) {
    const key = row.scheme_id;
    if (!map.has(key)) {
      map.set(key, []);
    }
    map.get(key).push(mapper(row));
  }
  return map;
};

const buildSchemeEntity = (row, joins) => {
  const localized = parseJson(row.metadata, {}).localized || {};
  const title = localized.title || { en: row.name, ta: "" };
  const shortDescription = localized.shortDescription || { en: row.description, ta: "" };

  const eligibilityRules = joins.eligibility.get(row.id) || [];
  const states = parseJson(row.states, []);
  const tags = joins.tags.get(row.id) || parseJson(row.tags_text, []);

  const firstRule = eligibilityRules[0] || {};
  const benefits = joins.benefits.get(row.id) || [];

  return {
    id: row.id,
    title,
    shortDescription,
    category: row.category || "Uncategorized",
    subcategory: row.subcategory || null,
    ministry: row.ministry || null,
    state: states[0] || "All India",
    targetBeneficiaries: parseJson(row.target_beneficiaries, []),
    benefits: {
      en: benefits.map((item) => item.benefit_description).join(" "),
      ta: ""
    },
    benefitItems: benefits,
    eligibility: {
      ageRange: [firstRule.age_min ?? null, firstRule.age_max ?? null],
      gender: firstRule.gender || "any",
      incomeMax: firstRule.income_limit ?? null,
      occupations: Array.from(
        new Set(eligibilityRules.map((rule) => rule.occupation).filter(Boolean))
      ),
      states: Array.from(
        new Set(eligibilityRules.map((rule) => rule.state).filter(Boolean).concat(states))
      ),
      casteCategories: Array.from(
        new Set(eligibilityRules.map((rule) => rule.caste_category).filter(Boolean))
      )
    },
    eligibilityRules,
    requiredDocuments: joins.documents.get(row.id) || [],
    tags,
    applicationUrl: row.application_link,
    officialSource: row.official_source,
    lastDate: row.last_updated,
    source: row.official_source,
    metadata: parseJson(row.metadata, {})
  };
};

const loadJoins = (schemeIds) => {
  if (schemeIds.length === 0) {
    return {
      benefits: new Map(),
      eligibility: new Map(),
      documents: new Map(),
      tags: new Map()
    };
  }

  const placeholders = schemeIds.map((_, index) => `:id${index}`).join(", ");
  const params = Object.fromEntries(schemeIds.map((id, index) => [`:id${index}`, id]));

  const benefits = aggregateBySchemeId(
    queryAll(`SELECT * FROM benefits WHERE scheme_id IN (${placeholders})`, params),
    (row) => ({
      id: row.id,
      benefit_type: row.benefit_type,
      benefit_description: row.benefit_description,
      amount: row.amount
    })
  );

  const eligibility = aggregateBySchemeId(
    queryAll(`SELECT * FROM eligibility_rules WHERE scheme_id IN (${placeholders})`, params),
    (row) => ({
      id: row.id,
      gender: row.gender,
      age_min: row.age_min,
      age_max: row.age_max,
      income_limit: row.income_limit,
      state: row.state,
      occupation: row.occupation,
      caste_category: row.caste_category
    })
  );

  const documents = aggregateBySchemeId(
    queryAll(`SELECT * FROM documents WHERE scheme_id IN (${placeholders})`, params),
    (row) => row.document_name
  );

  const tagsRows = queryAll(
    `
    SELECT st.scheme_id, t.tag_name
    FROM scheme_tags st
    JOIN tags t ON t.id = st.tag_id
    WHERE st.scheme_id IN (${placeholders})
    `,
    params
  );
  const tags = aggregateBySchemeId(tagsRows, (row) => row.tag_name);

  return { benefits, eligibility, documents, tags };
};

const filterInMemory = (items, filters) => {
  return items.filter((scheme) => {
    if (filters.q) {
      const q = filters.q.toLowerCase();
      const text = [
        scheme.title?.en,
        scheme.shortDescription?.en,
        scheme.category,
        scheme.ministry,
        ...(scheme.tags || [])
      ]
        .filter(Boolean)
        .join(" ")
        .toLowerCase();
      if (!text.includes(q)) return false;
    }

    if (filters.category && scheme.category?.toLowerCase() !== filters.category.toLowerCase()) {
      return false;
    }

    if (filters.beneficiaryType) {
      const target = filters.beneficiaryType.toLowerCase();
      const match = (scheme.targetBeneficiaries || []).some(
        (item) => item.toLowerCase() === target
      );
      if (!match) return false;
    }

    if (filters.ministry && (scheme.ministry || "").toLowerCase() !== filters.ministry.toLowerCase()) {
      return false;
    }

    if (filters.state) {
      const state = filters.state.toLowerCase();
      const states = scheme.eligibility?.states || [];
      const match = states.some((s) => {
        const lower = s.toLowerCase();
        return lower === state || lower === "all india";
      });
      if (!match) return false;
    }

    if (filters.tag) {
      const targetTag = filters.tag.toLowerCase();
      if (!(scheme.tags || []).some((tag) => tag.toLowerCase() === targetTag)) {
        return false;
      }
    }

    return true;
  });
};

export const schemeRepository = {
  async findAll(filters) {
    const page = Number(filters.page || 1);
    const limit = Number(filters.limit || 20);

    const rows = queryAll("SELECT * FROM schemes_v2 ORDER BY last_updated DESC");
    const ids = rows.map((row) => row.id);
    const joins = loadJoins(ids);
    const schemes = rows.map((row) => buildSchemeEntity(row, joins));

    const filtered = filterInMemory(schemes, filters);
    const offset = (page - 1) * limit;
    const items = filtered.slice(offset, offset + limit);

    return {
      items,
      total: filtered.length,
      page,
      limit,
      hasMore: offset + items.length < filtered.length
    };
  },

  async search(filters) {
    return this.findAll(filters);
  },

  async findById(id) {
    const row = queryOne("SELECT * FROM schemes_v2 WHERE id = :id", { ":id": id });
    if (!row) return null;
    const joins = loadJoins([id]);
    return buildSchemeEntity(row, joins);
  },

  async getCategories() {
    const rows = queryAll(
      `SELECT category, COUNT(*) AS count FROM schemes_v2 GROUP BY category ORDER BY count DESC`
    );
    return rows.map((row) => ({ category: row.category, count: Number(row.count) }));
  },

  async getBeneficiaryTypes() {
    const rows = queryAll("SELECT target_beneficiaries FROM schemes_v2");
    const counts = new Map();
    for (const row of rows) {
      const list = parseJson(row.target_beneficiaries, []);
      for (const item of list) {
        const key = String(item);
        counts.set(key, (counts.get(key) || 0) + 1);
      }
    }

    return Array.from(counts.entries())
      .map(([beneficiaryType, count]) => ({ beneficiaryType, count }))
      .sort((a, b) => b.count - a.count);
  },

  async getMinistries() {
    const rows = queryAll(
      `SELECT ministry, COUNT(*) AS count FROM schemes_v2 WHERE ministry IS NOT NULL GROUP BY ministry ORDER BY count DESC`
    );
    return rows.map((row) => ({ ministry: row.ministry, count: Number(row.count) }));
  },

  async upsertMany(payload) {
    await withTransaction(async () => {
      for (const record of payload.records) {
        const scheme = record.scheme;

        run(
          `
          INSERT OR REPLACE INTO schemes_v2 (
            id, name, description, ministry, category, subcategory,
            application_link, official_source, target_beneficiaries,
            states, tags_text, last_updated, updated_at
          ) VALUES (
            :id, :name, :description, :ministry, :category, :subcategory,
            :application_link, :official_source, :target_beneficiaries,
            :states, :tags_text, :last_updated, datetime('now')
          )
          `,
          {
            ":id": scheme.id,
            ":name": scheme.name,
            ":description": scheme.description,
            ":ministry": scheme.ministry,
            ":category": scheme.category,
            ":subcategory": scheme.subcategory,
            ":application_link": scheme.application_link,
            ":official_source": scheme.official_source,
            ":target_beneficiaries": JSON.stringify(scheme.target_beneficiaries || []),
            ":states": JSON.stringify(scheme.states || []),
            ":tags_text": JSON.stringify(scheme.tags_text || []),
            ":last_updated": scheme.last_updated
          }
        );

        run("DELETE FROM benefits WHERE scheme_id = :scheme_id", { ":scheme_id": scheme.id });
        run("DELETE FROM eligibility_rules WHERE scheme_id = :scheme_id", { ":scheme_id": scheme.id });
        run("DELETE FROM documents WHERE scheme_id = :scheme_id", { ":scheme_id": scheme.id });
        run("DELETE FROM scheme_tags WHERE scheme_id = :scheme_id", { ":scheme_id": scheme.id });
        run("DELETE FROM schemes_search_v2 WHERE scheme_id = :scheme_id", { ":scheme_id": scheme.id });

        for (const benefit of record.benefits) {
          run(
            `
            INSERT INTO benefits (scheme_id, benefit_type, benefit_description, amount)
            VALUES (:scheme_id, :benefit_type, :benefit_description, :amount)
            `,
            {
              ":scheme_id": scheme.id,
              ":benefit_type": benefit.benefit_type,
              ":benefit_description": benefit.benefit_description,
              ":amount": benefit.amount
            }
          );
        }

        for (const rule of record.eligibilityRules) {
          run(
            `
            INSERT INTO eligibility_rules
            (scheme_id, gender, age_min, age_max, income_limit, state, occupation, caste_category)
            VALUES (:scheme_id, :gender, :age_min, :age_max, :income_limit, :state, :occupation, :caste_category)
            `,
            {
              ":scheme_id": scheme.id,
              ":gender": rule.gender,
              ":age_min": rule.age_min,
              ":age_max": rule.age_max,
              ":income_limit": rule.income_limit,
              ":state": rule.state,
              ":occupation": rule.occupation,
              ":caste_category": rule.caste_category
            }
          );
        }

        for (const doc of record.documents) {
          run(
            `INSERT INTO documents (scheme_id, document_name) VALUES (:scheme_id, :document_name)`,
            {
              ":scheme_id": scheme.id,
              ":document_name": doc.document_name
            }
          );
        }

        for (const tag of record.tags) {
          run("INSERT OR IGNORE INTO tags (tag_name) VALUES (:tag_name)", {
            ":tag_name": tag
          });
          const tagRow = queryOne("SELECT id FROM tags WHERE tag_name = :tag_name", {
            ":tag_name": tag
          });
          if (tagRow) {
            run(
              "INSERT OR IGNORE INTO scheme_tags (scheme_id, tag_id) VALUES (:scheme_id, :tag_id)",
              {
                ":scheme_id": scheme.id,
                ":tag_id": tagRow.id
              }
            );
          }
        }

        const searchText = [
          scheme.name,
          scheme.description,
          scheme.category,
          scheme.subcategory,
          scheme.ministry,
          ...(record.tags || []),
          ...(scheme.target_beneficiaries || [])
        ]
          .filter(Boolean)
          .join(" ")
          .toLowerCase();

        run(
          "INSERT INTO schemes_search_v2 (scheme_id, search_text) VALUES (:scheme_id, :search_text)",
          {
            ":scheme_id": scheme.id,
            ":search_text": searchText
          }
        );
      }

      run(
        `
        INSERT OR REPLACE INTO ingestion_runs
        (run_id, source_path, imported_count, duplicate_count, validation_errors)
        VALUES (:run_id, :source_path, :imported_count, :duplicate_count, :validation_errors)
        `,
        {
          ":run_id": payload.run.run_id,
          ":source_path": payload.run.source_path,
          ":imported_count": payload.run.imported_count,
          ":duplicate_count": payload.run.duplicate_count,
          ":validation_errors": payload.run.validation_errors
        }
      );
    });
  }
};
