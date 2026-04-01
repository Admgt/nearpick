const {asDate} = require("./security_helpers");

function asStringArray(value) {
  if (!Array.isArray(value)) {
    return [];
  }

  return value.filter((entry) => typeof entry === "string");
}

function readCategoryCount(container, key, category) {
  const source = container?.[key];
  if (!source || typeof source !== "object" || !category) {
    return 0;
  }

  const value = source[category];
  return Number.isFinite(value) ? Number(value) : 0;
}

function readCategoryDate(container, key, category) {
  const source = container?.[key];
  if (!source || typeof source !== "object" || !category) {
    return null;
  }

  return asDate(source[category]);
}

function hasRecentNegativeSignal({dismissCount, lastDismissedAt, now}) {
  if (dismissCount < 2 || !lastDismissedAt) {
    return false;
  }

  const ageMs = now.getTime() - lastDismissedAt.getTime();
  return ageMs >= 0 && ageMs <= 14 * 24 * 60 * 60 * 1000;
}

function resolveNotificationSegment({
  category,
  userProfile,
  implicitPrefs,
  negativePrefs,
  now = new Date(),
}) {
  const normalizedCategory =
    typeof category === "string" ? category.trim() : "";
  if (!normalizedCategory) {
    return {eligible: false, reason: "missing-category", segment: null};
  }

  const favoriteCategories = asStringArray(userProfile?.favoriteCategories);
  const implicitViews = readCategoryCount(
      implicitPrefs,
      "categoryViews",
      normalizedCategory,
  );
  const dismissCount = readCategoryCount(
      negativePrefs,
      "categoryDismissals",
      normalizedCategory,
  );
  const lastDismissedAt = readCategoryDate(
      negativePrefs,
      "categoryLastDismissedAt",
      normalizedCategory,
  );

  if (hasRecentNegativeSignal({dismissCount, lastDismissedAt, now})) {
    return {
      eligible: false,
      reason: "recent-negative-signal",
      segment: null,
    };
  }

  if (favoriteCategories.includes(normalizedCategory)) {
    return {
      eligible: true,
      reason: "favorite-category",
      segment: "favorite_category",
    };
  }

  if (implicitViews >= 3) {
    return {
      eligible: true,
      reason: "implicit-interest",
      segment: "implicit_interest",
    };
  }

  return {eligible: false, reason: "no-segment-match", segment: null};
}

module.exports = {
  hasRecentNegativeSignal,
  resolveNotificationSegment,
};
