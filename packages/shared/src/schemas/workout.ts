import { z } from "zod";

export const WorkoutSetSchema = z.object({
  setNumber: z.number().int().positive(),
  weight: z.number().nonnegative(),
  reps: z.number().int().nonnegative(),
  rpe: z.number().min(1).max(10).optional(),
  isWarmup: z.boolean().default(false),
  isPersonalRecord: z.boolean().default(false),
});

export const WorkoutExerciseSchema = z.object({
  exerciseId: z.string(),
  exerciseName: z.string(),
  order: z.number().int().nonnegative(),
  sets: z.array(WorkoutSetSchema),
  notes: z.string().max(500).optional(),
});

export const WorkoutSchema = z.object({
  id: z.string(),
  userId: z.string(),
  templateId: z.string().nullable(),
  name: z.string().min(1).max(120),
  exercises: z.array(WorkoutExerciseSchema),
  startedAt: z.string().datetime(),
  completedAt: z.string().datetime().nullable(),
  durationSeconds: z.number().int().nonnegative().nullable(),
  notes: z.string().max(1000).optional(),
  createdAt: z.string().datetime(),
  updatedAt: z.string().datetime(),
});

export const CreateWorkoutSchema = z.object({
  templateId: z.string().nullable().optional(),
  name: z.string().min(1).max(120),
  exercises: z.array(WorkoutExerciseSchema).min(1),
  startedAt: z.string().datetime(),
  completedAt: z.string().datetime().nullable().optional(),
  notes: z.string().max(1000).optional(),
});

export type WorkoutSet = z.infer<typeof WorkoutSetSchema>;
export type WorkoutExercise = z.infer<typeof WorkoutExerciseSchema>;
export type Workout = z.infer<typeof WorkoutSchema>;
export type CreateWorkoutInput = z.infer<typeof CreateWorkoutSchema>;
