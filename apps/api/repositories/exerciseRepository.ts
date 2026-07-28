import { adminDb } from "@/lib/firebase-admin";
import type { CreateExerciseInput, Exercise } from "@ironlog/shared";

const collection = () => adminDb.collection("exercises");

export const exerciseRepository = {
  async listForUser(userId: string): Promise<Exercise[]> {
    const [globalSnap, customSnap] = await Promise.all([
      collection().where("ownerId", "==", null).get(),
      collection().where("ownerId", "==", userId).get(),
    ]);

    return [...globalSnap.docs, ...customSnap.docs].map((doc) => doc.data() as Exercise);
  },

  async create(userId: string, input: CreateExerciseInput): Promise<Exercise> {
    const ref = collection().doc();
    const exercise: Exercise = {
      id: ref.id,
      ownerId: userId,
      name: input.name,
      muscleGroup: input.muscleGroup,
      equipment: input.equipment,
      isCustom: true,
      muscles: [],
      createdAt: new Date().toISOString(),
    };

    await ref.set(exercise);
    return exercise;
  },
};
