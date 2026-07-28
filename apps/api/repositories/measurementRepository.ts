import { adminDb } from "@/lib/firebase-admin";
import type { CreateMeasurementInput, Measurement } from "@ironlog/shared";

const collection = () => adminDb.collection("measurements");

export const measurementRepository = {
  async listByUser(userId: string, limit = 100): Promise<Measurement[]> {
    const snapshot = await collection().where("userId", "==", userId).get();

    return snapshot.docs
      .map((doc) => doc.data() as Measurement)
      .sort((a, b) => b.loggedAt.localeCompare(a.loggedAt))
      .slice(0, limit);
  },

  async create(userId: string, input: CreateMeasurementInput): Promise<Measurement> {
    const ref = collection().doc();
    const measurement: Measurement = {
      id: ref.id,
      userId,
      loggedAt: input.loggedAt,
      unit: input.unit,
      values: input.values,
      createdAt: new Date().toISOString(),
    };

    await ref.set(measurement);
    return measurement;
  },
};
