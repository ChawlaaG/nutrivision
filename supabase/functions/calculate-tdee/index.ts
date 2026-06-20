// BACKEND LOGIC FOR CALCULATING DAILY GOAL
type Gender = 'male' | 'female';
type ActivityLevel = 'sedentary' | 'light' | 'moderate' | 'active' | 'athlete';

interface UserStats {
  weightKg: number;
  heightCm: number;
  age: number;
  gender: Gender;
  bodyFatPercent?: number; // Optional parameter for higher accuracy
}

export function calculateDailyCalories(stats: UserStats, activity: ActivityLevel, goal: 'loss' | 'maintain' | 'gain'): number {
  let bmr: number;

  if (stats.bodyFatPercent) {
    // Katch-McArdle Formula (Pro Athlete standard)
    const leanBodyMass = stats.weightKg * (1 - (stats.bodyFatPercent / 100));
    bmr = 370 + (21.6 * leanBodyMass);
  } else {
    // Mifflin-St Jeor Formula (Gold Standard generally)
    bmr = (10 * stats.weightKg) + (6.25 * stats.heightCm) - (5 * stats.age);
    bmr += (stats.gender === 'male' ? 5 : -161);
  }

  const multipliers: Record<ActivityLevel, number> = {
    sedentary: 1.2, light: 1.375, moderate: 1.55, active: 1.725, athlete: 1.9
  };

  const tdee = bmr * multipliers[activity];

  switch (goal) {
    case 'loss': return Math.round(tdee - 500); // Standard sustainable deficit
    case 'gain': return Math.round(tdee + 300);
    default: return Math.round(tdee);
  }
}

// Example usage / Handler wrapper (mocked for this file)
// In a real Supabase Edge Function, you would serve this via Deno.serve
/*
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

serve(async (req) => {
  const { stats, activity, goal } = await req.json();
  const calories = calculateDailyCalories(stats, activity, goal);
  return new Response(JSON.stringify({ calories }), { headers: { "Content-Type": "application/json" } });
})
*/
