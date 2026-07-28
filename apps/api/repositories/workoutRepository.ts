import { adminDb } from "@/lib/firebase-admin";
import type { CreateWorkoutInput, Workout } from "@ironlog/shared";

const collection = () => adminDb.collection("workouts");

export const workoutRepository = {
  async listByUser(userId: string, limit = 50): Promise<Workout[]> {
    const snapshot = await collection().where("userId", "==", userId).get();

    return snapshot.docs
      .map((doc) => doc.data() as Workout)
      .sort((a, b) => b.startedAt.localeCompare(a.startedAt))
      .slice(0, limit);
  },

  async create(userId: string, input: CreateWorkoutInput): Promise<Workout> {
    const ref = collection().doc();
    const now = new Date().toISOString();

    const workout: Workout = {
      id: ref.id,
      userId,
      templateId: input.templateId ?? null,
      name: input.name,
      exercises: input.exercises,
      startedAt: input.startedAt,
      completedAt: input.completedAt ?? null,
      durationSeconds: null,
      notes: input.notes,
      createdAt: now,
      updatedAt: now,
    };

    await ref.set(workout);
    return workout;
  },
};
