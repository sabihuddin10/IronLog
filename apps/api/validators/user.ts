import { UpdateUserSchema } from "@ironlog/shared";
import type { NextRequest } from "next/server";

export async function parseUpdateUser(request: NextRequest) {
  const body = await request.json();
  return UpdateUserSchema.parse(body);
}
