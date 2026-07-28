import { z } from "zod";

export const ExerciseMuscleGroupSchema = z.enum([
  "chest",
  "back",
  "shoulders",
  "biceps",
  "triceps",
  "legs",
  "glutes",
  "core",
  "cardio",
  "full_body",
]);

export const MuscleEngagementSchema = z.object({
  muscle: z.string(),
  percentage: z.number().int().min(0).max(100),
});

export const ExerciseSchema = z.object({
  id: z.string(),
  ownerId: z.string().nullable(),
  name: z.string().min(1).max(100),
  muscleGroup: ExerciseMuscleGroupSchema,
  equipment: z.string().max(60).optional(),
  isCustom: z.boolean().default(false),
  muscles: z.array(MuscleEngagementSchema).default([]),
  createdAt: z.string().datetime(),
});

export const CreateExerciseSchema = ExerciseSchema.pick({
  name: true,
  muscleGroup: true,
  equipment: true,
});

export type MuscleEngagement = z.infer<typeof MuscleEngagementSchema>;
export type Exercise = z.infer<typeof ExerciseSchema>;
export type CreateExerciseInput = z.infer<typeof CreateExerciseSchema>;
export type ExerciseMuscleGroup = z.infer<typeof ExerciseMuscleGroupSchema>;
