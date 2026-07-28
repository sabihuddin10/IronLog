import { auth } from "@/lib/firebase-client";
import type { ApiResponse, Workout, CreateWorkoutInput } from "@ironlog/shared";

const API_URL = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:3002";

async function request<T>(path: string, init?: RequestInit): Promise<T> {
  const token = await auth.currentUser?.getIdToken();

  const res = await fetch(`${API_URL}${path}`, {
    ...init,
    headers: {
      "Content-Type": "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...init?.headers,
    },
  });

  const body = (await res.json()) as ApiResponse<T>;

  if (!body.success) {
    throw new Error(body.error.message);
  }

  return body.data;
}

export const api = {
  listWorkouts: () => request<Workout[]>("/api/workouts"),
  createWorkout: (input: CreateWorkoutInput) =>
    request<Workout>("/api/workouts", { method: "POST", body: JSON.stringify(input) }),
};
