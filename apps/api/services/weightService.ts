import { weightRepository } from "@/repositories/weightRepository";
import type { CreateWeightLogInput } from "@ironlog/shared";

export const weightService = {
  listForUser(userId: string) {
    return weightRepository.listByUser(userId);
  },

  createForUser(userId: string, input: CreateWeightLogInput) {
    return weightRepository.create(userId, input);
  },
};
