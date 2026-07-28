import { workoutRepository } from "@/repositories/workoutRepository";
import type { CreateWorkoutInput } from "@ironlog/shared";

export const workoutService = {
  listForUser(userId: string) {
    return workoutRepository.listByUser(userId);
  },

  createForUser(userId: string, input: CreateWorkoutInput) {
    return workoutRepository.create(userId, input);
  },
};
