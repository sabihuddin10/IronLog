import type { NextRequest } from "next/server";
import { requireAuth } from "@/middleware/auth";
import { parseUpdateUser } from "@/validators/user";
import { userService } from "@/services/userService";
import { ok, fail, handleRouteError } from "@/lib/api-response";

export async function GET(request: NextRequest) {
  try {
    const { uid, email } = await requireAuth(request);
    if (!email) {
      return fail("NO_EMAIL", "Authenticated user has no email on record", 400);
    }
    const profile = await userService.getOrCreateProfile(uid, email);
    return ok(profile);
  } catch (error) {
    return handleRouteError(error);
  }
}

export async function PATCH(request: NextRequest) {
  try {
    const { uid } = await requireAuth(request);
    const input = await parseUpdateUser(request);
    const profile = await userService.updateProfile(uid, input);
    return ok(profile);
  } catch (error) {
    return handleRouteError(error);
  }
}
