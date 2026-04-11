const admin = require("firebase-admin");

function parseArgs(argv) {
  const args = {uid: null, email: null};
  for (let i = 0; i < argv.length; i += 1) {
    const current = argv[i];
    const next = argv[i + 1];
    if (current === "--uid" && next) {
      args.uid = next.trim();
      i += 1;
      continue;
    }
    if (current === "--email" && next) {
      args.email = next.trim();
      i += 1;
    }
  }
  return args;
}

async function resolveUser({uid, email}) {
  if (uid) {
    return admin.auth().getUser(uid);
  }
  if (email) {
    return admin.auth().getUserByEmail(email);
  }
  throw new Error("Adj meg --uid vagy --email parametert.");
}

async function main() {
  admin.initializeApp();

  const args = parseArgs(process.argv.slice(2));
  const user = await resolveUser(args);
  const existingClaims = user.customClaims ?? {};

  await admin.auth().setCustomUserClaims(user.uid, {
    ...existingClaims,
    admin: true,
  });

  await admin.firestore().collection("users").doc(user.uid).set({
    accountStatus: "active",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    displayName: user.displayName ?? "",
    email: user.email ?? "",
    role: "admin",
    statusUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
    statusUpdatedBy: "setup-script",
  }, {merge: true});

  process.stdout.write(
      `Admin claim beallitva: uid=${user.uid} email=${user.email ?? ""}\n`,
  );
}

main().catch((error) => {
  process.stderr.write(`${error.stack ?? error}\n`);
  process.exitCode = 1;
});
