const test = require("node:test");
const assert = require("node:assert/strict");

const {
  hasRecentNegativeSignal,
  resolveNotificationSegment,
} = require("../notification_segments");

test("favorite category users stay eligible for push", () => {
  const result = resolveNotificationSegment({
    category: "Pekseg",
    userProfile: {favoriteCategories: ["Pekseg", "Desszert"]},
    implicitPrefs: {},
    negativePrefs: {},
    now: new Date("2026-04-01T12:00:00.000Z"),
  });

  assert.deepEqual(result, {
    eligible: true,
    reason: "favorite-category",
    segment: "favorite_category",
  });
});

test("implicit category interest can qualify for push", () => {
  const result = resolveNotificationSegment({
    category: "Pekseg",
    userProfile: {},
    implicitPrefs: {
      categoryViews: {
        Pekseg: 4,
      },
    },
    negativePrefs: {},
    now: new Date("2026-04-01T12:00:00.000Z"),
  });

  assert.deepEqual(result, {
    eligible: true,
    reason: "implicit-interest",
    segment: "implicit_interest",
  });
});

test("recent repeated dismissals suppress push delivery", () => {
  const result = resolveNotificationSegment({
    category: "Pekseg",
    userProfile: {favoriteCategories: ["Pekseg"]},
    implicitPrefs: {
      categoryViews: {
        Pekseg: 8,
      },
    },
    negativePrefs: {
      categoryDismissals: {
        Pekseg: 2,
      },
      categoryLastDismissedAt: {
        Pekseg: new Date("2026-03-30T12:00:00.000Z"),
      },
    },
    now: new Date("2026-04-01T12:00:00.000Z"),
  });

  assert.deepEqual(result, {
    eligible: false,
    reason: "recent-negative-signal",
    segment: null,
  });
});

test("hasRecentNegativeSignal only blocks recent repeated dismissals", () => {
  assert.equal(
      hasRecentNegativeSignal({
        dismissCount: 1,
        lastDismissedAt: new Date("2026-03-30T12:00:00.000Z"),
        now: new Date("2026-04-01T12:00:00.000Z"),
      }),
      false,
  );

  assert.equal(
      hasRecentNegativeSignal({
        dismissCount: 3,
        lastDismissedAt: new Date("2026-03-01T12:00:00.000Z"),
        now: new Date("2026-04-01T12:00:00.000Z"),
      }),
      false,
  );
});
