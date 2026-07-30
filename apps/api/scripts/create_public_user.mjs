// One-off script: creates (or resets the password of) a single shared
// Firebase Auth account so the app can be demoed on other people's phones
// without handing out a personal login. Run with:
//   node scripts/create_public_user.mjs   (from apps/api)
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
import { cert, initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";

const __dirname = dirname(fileURLToPath(import.meta.url));

function loadEnv(path) {
  const text = readFileSync(path, "utf8");
  const env = {};
  for (const line of text.split("\n")) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#")) continue;
    const eq = trimmed.indexOf("=");
    if (eq === -1) continue;
    const key = trimmed.slice(0, eq).trim();
    let value = trimmed.slice(eq + 1).trim();
    if (value.startsWith('"') && value.endsWith('"')) {
      value = value.slice(1, -1);
    }
    env[key] = value;
  }
  return env;
}

const env = loadEnv(join(__dirname, "..", ".env.local"));

const app = initializeApp({
  credential: cert({
    projectId: env.FIREBASE_PROJECT_ID,
    clientEmail: env.FIREBASE_CLIENT_EMAIL,
    privateKey: env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, "\n"),
  }),
});

const auth = getAuth(app);

const EMAIL = "publicuser@ironlog.com";
const PASSWORD = "123456789";

async function main() {
  let userRecord;
  try {
    userRecord = await auth.getUserByEmail(EMAIL);
    await auth.updateUser(userRecord.uid, { password: PASSWORD });
    console.log(`public user already existed: ${userRecord.uid} (password reset)`);
  } catch {
    userRecord = await auth.createUser({
      email: EMAIL,
      password: PASSWORD,
      displayName: "Public Demo",
      emailVerified: true,
    });
    console.log(`public user created: ${userRecord.uid}`);
  }

  console.log("\nShared login:");
  console.log(`  email:    ${EMAIL}`);
  console.log(`  password: ${PASSWORD}`);
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
