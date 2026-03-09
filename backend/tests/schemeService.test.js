import test from "node:test";
import assert from "node:assert/strict";

import { scoreScheme } from "../src/modules/schemes/schemeService.js";

test("scoreScheme gives high score for eligible profile", () => {
  const scheme = {
    id: "abc",
    eligibility: {
      ageRange: [18, 35],
      incomeMax: 300000,
      gender: "female",
      occupations: ["student"],
      states: ["Tamil Nadu"]
    }
  };

  const result = scoreScheme(scheme, {
    age: 22,
    income: 200000,
    gender: "female",
    occupation: "student",
    state: "Tamil Nadu"
  });

  assert.ok(result.recommendation.score >= 0.8);
});

test("scoreScheme gives lower score for non-eligible profile", () => {
  const scheme = {
    id: "xyz",
    eligibility: {
      ageRange: [18, 25],
      incomeMax: 100000,
      gender: "female",
      occupations: ["student"],
      states: ["Kerala"]
    }
  };

  const result = scoreScheme(scheme, {
    age: 40,
    income: 900000,
    gender: "male",
    occupation: "farmer",
    state: "Delhi"
  });

  assert.ok(result.recommendation.score < 0.4);
});
