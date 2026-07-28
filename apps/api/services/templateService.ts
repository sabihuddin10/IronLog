import { templateRepository } from "@/repositories/templateRepository";
import type { CreateTemplateInput } from "@ironlog/shared";

export const templateService = {
  listForUser(userId: string) {
    return templateRepository.listByUser(userId);
  },

  createForUser(userId: string, input: CreateTemplateInput) {
    return templateRepository.create(userId, input);
  },

  deleteForUser(userId: string, templateId: string) {
    return templateRepository.delete(userId, templateId);
  },
};
