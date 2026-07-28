import { measurementRepository } from "@/repositories/measurementRepository";
import type { CreateMeasurementInput } from "@ironlog/shared";

export const measurementService = {
  listForUser(userId: string) {
    return measurementRepository.listByUser(userId);
  },

  createForUser(userId: string, input: CreateMeasurementInput) {
    return measurementRepository.create(userId, input);
  },
};
