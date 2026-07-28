// One-off Firestore seed script for the myharmic-2 Firebase project.
// Run with: node scripts/seed.mjs   (from apps/api)
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
import { cert, initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore } from "firebase-admin/firestore";

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
const db = getFirestore(app);

const now = () => new Date().toISOString();
const daysAgo = (n) => new Date(Date.now() - n * 86_400_000).toISOString();

// Single source of truth, shared with the Flutter app's local mock data.
const EXERCISE_LIBRARY_PATH = join(
  __dirname,
  "..",
  "..",
  "mobile",
  "assets",
  "data",
  "exercises.json",
);

async function seedExercises() {
  const collection = db.collection("exercises");
  const library = JSON.parse(readFileSync(EXERCISE_LIBRARY_PATH, "utf8"));

  // Drop any exercises from an older seed run that don't match the current
  // library (e.g. the previous `global-*` id scheme) so the collection
  // doesn't accumulate stale/duplicate entries.
  const currentIds = new Set(library.map((e) => e.id));
  const existingSnapshot = await collection.where("ownerId", "==", null).get();
  const stale = existingSnapshot.docs.filter((doc) => !currentIds.has(doc.id));
  await Promise.all(stale.map((doc) => doc.ref.delete()));

  let written = 0;
  for (const exercise of library) {
    await collection.doc(exercise.id).set({
      id: exercise.id,
      ownerId: null,
      name: exercise.name,
      muscleGroup: exercise.category,
      equipment: exercise.equipment ?? null,
      isCustom: false,
      muscles: exercise.muscles ?? [],
      createdAt: now(),
    });
    written++;
  }

  console.log(`exercises: ${written} written (${stale.length} stale removed)`);
}

async function seedTemplates(uid) {
  const templates = [
    {
      id: "template-push-day",
      name: "Push Day",
      exercises: [
        { exerciseId: "ex-barbell-bench-press", exerciseName: "Barbell Bench Press", order: 0, targetSets: 4, targetReps: 8 },
        { exerciseId: "ex-overhead-press", exerciseName: "Overhead Press", order: 1, targetSets: 3, targetReps: 8 },
        { exerciseId: "ex-triceps-pushdown", exerciseName: "Triceps Pushdown", order: 2, targetSets: 3, targetReps: 12 },
      ],
    },
    {
      id: "template-leg-day",
      name: "Leg Day",
      exercises: [
        { exerciseId: "ex-barbell-back-squat", exerciseName: "Barbell Back Squat", order: 0, targetSets: 4, targetReps: 6 },
        { exerciseId: "ex-romanian-deadlift", exerciseName: "Romanian Deadlift", order: 1, targetSets: 3, targetReps: 10 },
        { exerciseId: "ex-walking-lunge", exerciseName: "Walking Lunge", order: 2, targetSets: 3, targetReps: 12 },
      ],
    },
    {
      id: "template-pull-day",
      name: "Pull Day",
      exercises: [
        { exerciseId: "ex-conventional-deadlift", exerciseName: "Conventional Deadlift", order: 0, targetSets: 3, targetReps: 5 },
        { exerciseId: "ex-pull-up", exerciseName: "Pull-Up", order: 1, targetSets: 4, targetReps: 8 },
        { exerciseId: "ex-barbell-row", exerciseName: "Barbell Row", order: 2, targetSets: 3, targetReps: 10 },
      ],
    },
  ];

  for (const t of templates) {
    await db.collection("templates").doc(t.id).set({
      id: t.id,
      userId: uid,
      name: t.name,
      exercises: t.exercises,
      createdAt: now(),
      updatedAt: now(),
    });
  }
  console.log(`templates: seeded ${templates.length} for demo user`);
}

async function seedDemoUser() {
  const email = "demo@ironlog.app";
  const password = "IronLog123!";

  let userRecord;
  try {
    userRecord = await auth.getUserByEmail(email);
    console.log(`demo user already exists: ${userRecord.uid}`);
  } catch {
    userRecord = await auth.createUser({
      email,
      password,
      displayName: "Demo Lifter",
      emailVerified: true,
    });
    console.log(`demo user created: ${userRecord.uid}`);
  }

  const uid = userRecord.uid;

  await db.collection("users").doc(uid).set(
    {
      id: uid,
      email,
      displayName: "Demo Lifter",
      unitPreference: "kg",
      createdAt: now(),
      updatedAt: now(),
    },
    { merge: true },
  );

  const workouts = [
    {
      id: "demo-workout-1",
      name: "Push Day",
      daysAgo: 6,
      exercises: [
        {
          exerciseId: "ex-barbell-bench-press",
          exerciseName: "Barbell Bench Press",
          order: 0,
          sets: [
            { setNumber: 1, weight: 60, reps: 8, isWarmup: true, isPersonalRecord: false },
            { setNumber: 2, weight: 80, reps: 6, isWarmup: false, isPersonalRecord: false },
            { setNumber: 3, weight: 82.5, reps: 5, isWarmup: false, isPersonalRecord: true },
          ],
        },
        {
          exerciseId: "ex-overhead-press",
          exerciseName: "Overhead Press",
          order: 1,
          sets: [
            { setNumber: 1, weight: 40, reps: 8, isWarmup: false, isPersonalRecord: false },
            { setNumber: 2, weight: 42.5, reps: 6, isWarmup: false, isPersonalRecord: false },
          ],
        },
      ],
    },
    {
      id: "demo-workout-2",
      name: "Leg Day",
      daysAgo: 3,
      exercises: [
        {
          exerciseId: "ex-barbell-back-squat",
          exerciseName: "Barbell Back Squat",
          order: 0,
          sets: [
            { setNumber: 1, weight: 80, reps: 8, isWarmup: true, isPersonalRecord: false },
            { setNumber: 2, weight: 100, reps: 5, isWarmup: false, isPersonalRecord: false },
            { setNumber: 3, weight: 105, reps: 5, isWarmup: false, isPersonalRecord: true },
          ],
        },
      ],
    },
    {
      id: "demo-workout-3",
      name: "Pull Day",
      daysAgo: 1,
      exercises: [
        {
          exerciseId: "ex-conventional-deadlift",
          exerciseName: "Conventional Deadlift",
          order: 0,
          sets: [
            { setNumber: 1, weight: 100, reps: 5, isWarmup: true, isPersonalRecord: false },
            { setNumber: 2, weight: 130, reps: 5, isWarmup: false, isPersonalRecord: false },
            { setNumber: 3, weight: 140, reps: 3, isWarmup: false, isPersonalRecord: true },
          ],
        },
        {
          exerciseId: "ex-pull-up",
          exerciseName: "Pull-Up",
          order: 1,
          sets: [
            { setNumber: 1, weight: 0, reps: 10, isWarmup: false, isPersonalRecord: false },
            { setNumber: 2, weight: 0, reps: 8, isWarmup: false, isPersonalRecord: false },
          ],
        },
      ],
    },
  ];

  for (const workout of workouts) {
    const startedAt = daysAgo(workout.daysAgo);
    await db.collection("workouts").doc(workout.id).set({
      id: workout.id,
      userId: uid,
      templateId: null,
      name: workout.name,
      exercises: workout.exercises,
      startedAt,
      completedAt: startedAt,
      durationSeconds: 2700,
      notes: "",
      createdAt: startedAt,
      updatedAt: startedAt,
    });
  }
  console.log(`workouts: seeded ${workouts.length} for demo user`);

  const weighIns = [
    { id: "demo-weight-1", weight: 82.4, daysBack: 20 },
    { id: "demo-weight-2", weight: 81.9, daysBack: 13 },
    { id: "demo-weight-3", weight: 81.2, daysBack: 6 },
    { id: "demo-weight-4", weight: 80.8, daysBack: 1 },
  ];

  for (const entry of weighIns) {
    await db.collection("weightLogs").doc(entry.id).set({
      id: entry.id,
      userId: uid,
      weight: entry.weight,
      unit: "kg",
      loggedAt: daysAgo(entry.daysBack),
      notes: "",
      createdAt: daysAgo(entry.daysBack),
    });
  }
  console.log(`weightLogs: seeded ${weighIns.length} for demo user`);

  await seedTemplates(uid);

  console.log("\nDemo login:");
  console.log(`  email:    ${email}`);
  console.log(`  password: ${password}`);
}

async function main() {
  await seedExercises();
  await seedDemoUser();
  console.log("\nSeed complete.");
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
