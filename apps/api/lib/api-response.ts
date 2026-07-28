import { NextResponse } from "next/server";
import { ZodError } from "zod";
import type { ApiResponse } from "@ironlog/shared";
import { AuthError } from "@/middleware/auth";

export function ok<T>(data: T, status = 200) {
  return NextResponse.json<ApiResponse<T>>({ success: true, data }, { status });
}

export function fail(code: string, message: string, status: number, details?: unknown) {
  return NextResponse.json<ApiResponse<never>>(
    { success: false, error: { code, message, details } },
    { status }
  );
}

export function handleRouteError(error: unknown) {
  if (error instanceof AuthError) {
    return fail("UNAUTHORIZED", error.message, 401);
  }
  if (error instanceof ZodError) {
    return fail("VALIDATION_ERROR", "Invalid request body", 400, error.flatten());
  }
  console.error(error);
  return fail("INTERNAL_ERROR", "Something went wrong", 500);
}
