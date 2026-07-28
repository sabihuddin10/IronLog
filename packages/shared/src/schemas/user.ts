import { z } from "zod";

export const UserSchema = z.object({
  id: z.string(),
  email: z.string().email(),
  displayName: z.string().min(1).max(80),
  unitPreference: z.enum(["kg", "lb"]).default("kg"),
  createdAt: z.string().datetime(),
  updatedAt: z.string().datetime(),
});

export const UpdateUserSchema = UserSchema.pick({
  displayName: true,
  unitPreference: true,
}).partial();

export type User = z.infer<typeof UserSchema>;
export type UpdateUserInput = z.infer<typeof UpdateUserSchema>;
