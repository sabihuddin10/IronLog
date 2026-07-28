import { CreateMeasurementSchema } from "@ironlog/shared";
import type { NextRequest } from "next/server";

export async function parseCreateMeasurement(request: NextRequest) {
  const body = await request.json();
  return CreateMeasurementSchema.parse(body);
}
