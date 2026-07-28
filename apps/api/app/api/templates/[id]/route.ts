import type { NextRequest } from "next/server";
import { requireAuth } from "@/middleware/auth";
import { templateService } from "@/services/templateService";
import { ok, handleRouteError } from "@/lib/api-response";

export async function DELETE(request: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  try {
    const { uid } = await requireAuth(request);
    const { id } = await params;
    await templateService.deleteForUser(uid, id);
    return ok({ deleted: true });
  } catch (error) {
    return handleRouteError(error);
  }
}
