import { exerciseRepository } from "@/repositories/exerciseRepository";
import type { CreateExerciseInput } from "@ironlog/shared";

export const exerciseService = {
  listForUser(userId: string) {
    return exerciseRepository.listForUser(userId);
  },

  createForUser(userId: string, input: CreateExerciseInput) {
    return exerciseRepository.create(userId, input);
  },
};
