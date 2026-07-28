import { adminDb } from "@/lib/firebase-admin";
import type { CreateTemplateInput, Template } from "@ironlog/shared";

const collection = () => adminDb.collection("templates");

export const templateRepository = {
  async listByUser(userId: string): Promise<Template[]> {
    const snapshot = await collection().where("userId", "==", userId).get();
    return snapshot.docs.map((doc) => doc.data() as Template);
  },

  async create(userId: string, input: CreateTemplateInput): Promise<Template> {
    const ref = collection().doc();
    const now = new Date().toISOString();
    const template: Template = {
      id: ref.id,
      userId,
      name: input.name,
      exercises: input.exercises,
      createdAt: now,
      updatedAt: now,
    };

    await ref.set(template);
    return template;
  },

  async delete(userId: string, templateId: string): Promise<void> {
    const ref = collection().doc(templateId);
    const doc = await ref.get();
    if (!doc.exists || (doc.data() as Template).userId !== userId) {
      return;
    }
    await ref.delete();
  },
};
