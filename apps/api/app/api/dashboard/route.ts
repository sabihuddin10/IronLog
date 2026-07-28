import type { NextRequest } from "next/server";
import { requireAuth } from "@/middleware/auth";
import { workoutService } from "@/services/workoutService";
import { weightService } from "@/services/weightService";
import { ok, handleRouteError } from "@/lib/api-response";

export async function GET(request: NextRequest) {
  try {
    const { uid } = await requireAuth(request);
    const [workouts, weightLogs] = await Promise.all([
      workoutService.listForUser(uid),
      weightService.listForUser(uid),
    ]);

    return ok({
      totalWorkouts: workouts.length,
      lastWorkout: workouts[0] ?? null,
      latestWeight: weightLogs[0] ?? null,
      workoutsThisWeek: workouts.filter((w) => {
        const days = (Date.now() - new Date(w.startedAt).getTime()) / 86_400_000;
        return days <= 7;
      }).length,
    });
  } catch (error) {
    return handleRouteError(error);
  }
}
