import { CreateExerciseSchema } from "@ironlog/shared";
import type { NextRequest } from "next/server";

export async function parseCreateExercise(request: NextRequest) {
  const body = await request.json();
  return CreateExerciseSchema.parse(body);
}
