const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");

const rules = fs.readFileSync(
    path.join(__dirname, "..", "..", "firestore.rules"),
    "utf8",
);

test("merchantStats remain readable for signed-in clients while writes stay denied", () => {
  assert.match(
      rules,
      /match \/merchantStats\/\{merchantId\} \{[\s\S]*allow read: if isSignedIn\(\);[\s\S]*allow create, update, delete: if false;/,
  );
});

test("reservation client updates remain denied", () => {
  assert.match(
      rules,
      /match \/reservations\/\{reservationId\} \{[\s\S]*allow update: if false;[\s\S]*allow delete: if false;/,
  );
});

test("review client writes remain denied", () => {
  assert.match(
      rules,
      /match \/reviews\/\{reviewId\} \{[\s\S]*allow create, update, delete: if false;/,
  );
});

test("product create keeps owned imagePath constraint", () => {
  assert.match(
      rules,
      /request\.resource\.data\.imagePath\.matches\([\s\S]*'\^products\/' \+ request\.auth\.uid \+ '\/' \+ productId \+ '\/\[\^\/\]\+\$'/,
  );
});

test("product updates still restrict writes to the interestCount delta", () => {
  assert.match(
      rules,
      /changedKeys\(\)[\s\S]*hasOnly\(\['interestCount'\]\)/,
  );
});
