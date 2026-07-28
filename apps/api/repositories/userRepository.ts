import { adminDb } from "@/lib/firebase-admin";
import type { UpdateUserInput, User } from "@ironlog/shared";

const collection = () => adminDb.collection("users");

export const userRepository = {
  async findById(userId: string): Promise<User | null> {
    const doc = await collection().doc(userId).get();
    return doc.exists ? (doc.data() as User) : null;
  },

  async createIfMissing(userId: string, email: string): Promise<User> {
    const ref = collection().doc(userId);
    const existing = await ref.get();
    if (existing.exists) {
      return existing.data() as User;
    }

    const now = new Date().toISOString();
    const user: User = {
      id: userId,
      email,
      displayName: email.split("@")[0] ?? "New Lifter",
      unitPreference: "kg",
      createdAt: now,
      updatedAt: now,
    };

    await ref.set(user);
    return user;
  },

  async update(userId: string, input: UpdateUserInput): Promise<User> {
    const ref = collection().doc(userId);
    const updatedAt = new Date().toISOString();
    await ref.set({ ...input, updatedAt }, { merge: true });
    const doc = await ref.get();
    return doc.data() as User;
  },
};
