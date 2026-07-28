import { z } from "zod";

export const WeightLogSchema = z.object({
  id: z.string(),
  userId: z.string(),
  weight: z.number().positive(),
  unit: z.enum(["kg", "lb"]),
  loggedAt: z.string().datetime(),
  notes: z.string().max(300).optional(),
  createdAt: z.string().datetime(),
});

export const CreateWeightLogSchema = WeightLogSchema.pick({
  weight: true,
  unit: true,
  loggedAt: true,
  notes: true,
}).partial({ notes: true });

export const MeasurementSchema = z.object({
  id: z.string(),
  userId: z.string(),
  loggedAt: z.string().datetime(),
  unit: z.enum(["cm", "in"]),
  values: z.object({
    chest: z.number().positive().optional(),
    waist: z.number().positive().optional(),
    hips: z.number().positive().optional(),
    leftArm: z.number().positive().optional(),
    rightArm: z.number().positive().optional(),
    leftThigh: z.number().positive().optional(),
    rightThigh: z.number().positive().optional(),
    neck: z.number().positive().optional(),
  }),
  createdAt: z.string().datetime(),
});

export const CreateMeasurementSchema = MeasurementSchema.pick({
  loggedAt: true,
  unit: true,
  values: true,
});

export type WeightLog = z.infer<typeof WeightLogSchema>;
export type CreateWeightLogInput = z.infer<typeof CreateWeightLogSchema>;
export type Measurement = z.infer<typeof MeasurementSchema>;
export type CreateMeasurementInput = z.infer<typeof CreateMeasurementSchema>;
