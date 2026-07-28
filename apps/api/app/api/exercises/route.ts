import type { NextRequest } from "next/server";
import { requireAuth } from "@/middleware/auth";
import { parseCreateExercise } from "@/validators/exercise";
import { exerciseService } from "@/services/exerciseService";
import { ok, handleRouteError } from "@/lib/api-response";

export async function GET(request: NextRequest) {
  try {
    const { uid } = await requireAuth(request);
    const exercises = await exerciseService.listForUser(uid);
    return ok(exercises);
  } catch (error) {
    return handleRouteError(error);
  }
}

export async function POST(request: NextRequest) {
  try {
    const { uid } = await requireAuth(request);
    const input = await parseCreateExercise(request);
    const exercise = await exerciseService.createForUser(uid, input);
    return ok(exercise, 201);
  } catch (error) {
    return handleRouteError(error);
  }
}
