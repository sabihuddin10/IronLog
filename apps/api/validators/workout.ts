import { CreateWorkoutSchema } from "@ironlog/shared";
import type { NextRequest } from "next/server";

export async function parseCreateWorkout(request: NextRequest) {
  const body = await request.json();
  return CreateWorkoutSchema.parse(body);
}
