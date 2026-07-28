import type { NextRequest } from "next/server";
import { requireAuth } from "@/middleware/auth";
import { parseCreateTemplate } from "@/validators/template";
import { templateService } from "@/services/templateService";
import { ok, handleRouteError } from "@/lib/api-response";

export async function GET(request: NextRequest) {
  try {
    const { uid } = await requireAuth(request);
    const templates = await templateService.listForUser(uid);
    return ok(templates);
  } catch (error) {
    return handleRouteError(error);
  }
}

export async function POST(request: NextRequest) {
  try {
    const { uid } = await requireAuth(request);
    const input = await parseCreateTemplate(request);
    const template = await templateService.createForUser(uid, input);
    return ok(template, 201);
  } catch (error) {
    return handleRouteError(error);
  }
}
