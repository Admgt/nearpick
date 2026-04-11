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
      /match \/merchantStats\/\{merchantId\} \{[\s\S]*allow read: if canReadProtectedData\(\);[\s\S]*allow create, update, delete: if false;/,
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

test("reviews remain readable for signed-in clients", () => {
  assert.match(
      rules,
      /match \/reviews\/\{reviewId\} \{[\s\S]*allow read: if canReadProtectedData\(\);[\s\S]*allow create, update, delete: if false;/,
  );
});

test("users write policy now restricts self-updates to safe profile fields", () => {
  assert.match(
      rules,
      /match \/users\/\{userId\} \{[\s\S]*allow create: if request\.auth != null[\s\S]*isValidUserCreate\(\);[\s\S]*allow update: if isValidUserSelfUpdate\(userId\);[\s\S]*allow delete: if false;/,
  );
});

test("adminMessages allow owner or admin reads while client-side create stays denied", () => {
  assert.match(
      rules,
      /match \/users\/\{userId\}\/adminMessages\/\{messageId\} \{[\s\S]*allow read: if isAdmin\(\)[\s\S]*request\.auth\.uid == userId[\s\S]*allow create: if false;[\s\S]*allow update: if isValidAdminMessageReadUpdate\(userId\);[\s\S]*allow delete: if false;/,
  );
});

test("admin helper is available for protected reads", () => {
  assert.match(
      rules,
      /function isAdmin\(\) \{[\s\S]*request\.auth\.token\.admin == true/,
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

test("product owner updates stay blocked after reservation history", () => {
  assert.match(
      rules,
      /isValidProductOwnerUpdate\(productId\)[\s\S]*resource\.data\.hasReservations == true[\s\S]*request\.resource\.data\.hasReservations == false/,
  );
});
