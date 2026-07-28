import type { NextRequest } from "next/server";
import { requireAuth } from "@/middleware/auth";
import { parseCreateWeightLog } from "@/validators/weight";
import { weightService } from "@/services/weightService";
import { ok, handleRouteError } from "@/lib/api-response";

export async function GET(request: NextRequest) {
  try {
    const { uid } = await requireAuth(request);
    const logs = await weightService.listForUser(uid);
    return ok(logs);
  } catch (error) {
    return handleRouteError(error);
  }
}

export async function POST(request: NextRequest) {
  try {
    const { uid } = await requireAuth(request);
    const input = await parseCreateWeightLog(request);
    const log = await weightService.createForUser(uid, input);
    return ok(log, 201);
  } catch (error) {
    return handleRouteError(error);
  }
}
