import { CreateWeightLogSchema } from "@ironlog/shared";
import type { NextRequest } from "next/server";

export async function parseCreateWeightLog(request: NextRequest) {
  const body = await request.json();
  return CreateWeightLogSchema.parse(body);
}
