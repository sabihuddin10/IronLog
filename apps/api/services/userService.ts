import { userRepository } from "@/repositories/userRepository";
import type { UpdateUserInput } from "@ironlog/shared";

export const userService = {
  async getOrCreateProfile(userId: string, email: string) {
    return userRepository.createIfMissing(userId, email);
  },

  updateProfile(userId: string, input: UpdateUserInput) {
    return userRepository.update(userId, input);
  },
};
