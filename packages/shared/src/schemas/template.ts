import { z } from "zod";

export const TemplateExerciseSchema = z.object({
  exerciseId: z.string(),
  exerciseName: z.string(),
  order: z.number().int().nonnegative(),
  targetSets: z.number().int().positive(),
  targetReps: z.number().int().positive().optional(),
});

export const TemplateSchema = z.object({
  id: z.string(),
  userId: z.string(),
  name: z.string().min(1).max(120),
  exercises: z.array(TemplateExerciseSchema),
  createdAt: z.string().datetime(),
  updatedAt: z.string().datetime(),
});

export const CreateTemplateSchema = z.object({
  name: z.string().min(1).max(120),
  exercises: z.array(TemplateExerciseSchema).min(1),
});

export type TemplateExercise = z.infer<typeof TemplateExerciseSchema>;
export type Template = z.infer<typeof TemplateSchema>;
export type CreateTemplateInput = z.infer<typeof CreateTemplateSchema>;
