import { CreateTemplateSchema } from "@ironlog/shared";
import type { NextRequest } from "next/server";

export async function parseCreateTemplate(request: NextRequest) {
  const body = await request.json();
  return CreateTemplateSchema.parse(body);
}
