import type { NextRequest } from "next/server";
import { requireAuth } from "@/middleware/auth";
import { parseCreateMeasurement } from "@/validators/measurement";
import { measurementService } from "@/services/measurementService";
import { ok, handleRouteError } from "@/lib/api-response";

export async function GET(request: NextRequest) {
  try {
    const { uid } = await requireAuth(request);
    const measurements = await measurementService.listForUser(uid);
    return ok(measurements);
  } catch (error) {
    return handleRouteError(error);
  }
}

export async function POST(request: NextRequest) {
  try {
    const { uid } = await requireAuth(request);
    const input = await parseCreateMeasurement(request);
    const measurement = await measurementService.createForUser(uid, input);
    return ok(measurement, 201);
  } catch (error) {
    return handleRouteError(error);
  }
}
