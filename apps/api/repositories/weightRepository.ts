import { adminDb } from "@/lib/firebase-admin";
import type { CreateWeightLogInput, WeightLog } from "@ironlog/shared";

const collection = () => adminDb.collection("weightLogs");

export const weightRepository = {
  async listByUser(userId: string, limit = 100): Promise<WeightLog[]> {
    const snapshot = await collection().where("userId", "==", userId).get();

    return snapshot.docs
      .map((doc) => doc.data() as WeightLog)
      .sort((a, b) => b.loggedAt.localeCompare(a.loggedAt))
      .slice(0, limit);
  },

  async create(userId: string, input: CreateWeightLogInput): Promise<WeightLog> {
    const ref = collection().doc();
    const entry: WeightLog = {
      id: ref.id,
      userId,
      weight: input.weight,
      unit: input.unit,
      loggedAt: input.loggedAt,
      notes: input.notes,
      createdAt: new Date().toISOString(),
    };

    await ref.set(entry);
    return entry;
  },
};
