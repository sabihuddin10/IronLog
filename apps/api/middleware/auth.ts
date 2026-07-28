import type { NextRequest } from "next/server";
import { adminAuth } from "@/lib/firebase-admin";

export class AuthError extends Error {
  constructor(message = "Unauthorized") {
    super(message);
    this.name = "AuthError";
  }
}

export type AuthContext = {
  uid: string;
  email: string | null;
};

export async function requireAuth(request: NextRequest): Promise<AuthContext> {
  const header = request.headers.get("authorization") ?? request.headers.get("Authorization");
  const token = header?.startsWith("Bearer ") ? header.slice("Bearer ".length) : null;

  if (!token) {
    throw new AuthError("Missing bearer token");
  }

  try {
    const decoded = await adminAuth.verifyIdToken(token);
    return { uid: decoded.uid, email: decoded.email ?? null };
  } catch {
    throw new AuthError("Invalid or expired token");
  }
}
