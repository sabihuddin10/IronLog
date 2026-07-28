import type { NextRequest } from "next/server";
import { requireAuth } from "@/middleware/auth";
import { parseCreateWorkout } from "@/validators/workout";
import { workoutService } from "@/services/workoutService";
import { ok, handleRouteError } from "@/lib/api-response";

export async function GET(request: NextRequest) {
  try {
    const { uid } = await requireAuth(request);
    const workouts = await workoutService.listForUser(uid);
    return ok(workouts);
  } catch (error) {
    return handleRouteError(error);
  }
}

export async function POST(request: NextRequest) {
  try {
    const { uid } = await requireAuth(request);
    const input = await parseCreateWorkout(request);
    const workout = await workoutService.createForUser(uid, input);
    return ok(workout, 201);
  } catch (error) {
    return handleRouteError(error);
  }
}
