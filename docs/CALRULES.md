# App Specification v2: Validated Strength Training Calorie Engine

*Pasted by user 2026-07-27 as a proposed replacement for the resistance-training
calorie formulas in `apps/mobile/lib/utils/health_formulas.dart`. Saved verbatim
for reference. See the assistant's critical review appended at the bottom before
implementing anything from this document — it contains at least one confirmed
algebra error (the `C_f` correction factor) that moves numbers in the opposite
direction from its own stated goal.*

## System Design Architecture
This specification outlines a dual-state, calculation engine that separates Active Time Under Tension (TUT) from Inter-Set Homeostasis Recovery (Rest). It incorporates the Ainsworth Compendium of Physical Activities guidelines while introducing a Corrected Metabolic Equivalent (cMET) adjustment based on personal physical attributes.

---

## Step 1: Baseline Individual RMR Correction
Standard MET profiles assume a universal rest rate of 3.5 mL of oxygen per kg per minute (1 MET). To make your app medically accurate across all demographics, the engine must compute the user's true Corrected MET factor using the Mifflin-St Jeor Equation (proven more accurate than Harris-Benedict for modern populations).

### Inputs:
- Weight_KG (Float)
- Height_CM (Float)
- Age_Years (Int)
- Gender (String: "Male" | "Female")

### Formulas:

1. Mifflin-St Jeor Daily RMR (kcal/day):

   RMR_Male = (10 × Weight_KG) + (6.25 × Height_CM) - (5 × Age_Years) + 5

   RMR_Female = (10 × Weight_KG) + (6.25 × Height_CM) - (5 × Age_Years) - 161

2. Convert Daily RMR to Personalized Oxygen Baseline (mL/kg/min):

   Oxygen_Baseline = ( (RMR_Kcal/day / 1440) / 5 ) / Weight_KG × 1000

3. Demographic Correction Factor (C_f):

   C_f = 3.5 / Oxygen_Baseline

   (This scalar factor shifts standard database MET entries up or down to align with the user's specific metabolic pace.)

---

## Step 2: The Two-State Workout Model
A session is broken down into clean structural blocks: Active Set State (Time Under Tension) and Passive Rest State (Inter-Set Interval).

### State A: Active Set State (Time Under Tension)
- Set Duration: sports-science baseline cadence of 3.5 seconds per repetition plus a 3.0-second behavioral setup cushion.

  TUT_Seconds = (Reps × 3.5) + 3.0

- The Mechanical Load Bias: scale energy cost against heavy weights by modifying the compendium baseline MET with a relative load bonus:

  cMET_Active = (Base_MET × C_f) × (1 + (Weight_Lifted_KG / Weight_KG) × 0.12)

### State B: Passive Rest State (Inter-Set Interval)
- Interval Duration: raw timestamp difference between completion of Set N and start of Set N+1.
- Metabolic Multiplier: standard baseline sitting/standing metabolic overhead during recovery.

  cMET_Rest = 1.5 × C_f

---

## Step 3: Exercise Database Intensity Tier Mapping

| Database Tier | Baseline MET | Scientific Criteria & Codebook Alignments | Examples |
|---|---|---|---|
| Tier 1: Low | 3.5 | Compendium Code 02050: Light/moderate resistance training. Minimal axial loading, isolation patterns. | Bicep Curls, Lateral Raises, Tricep Extensions, Calf Raises. |
| Tier 2: Medium | 5.0 | Compendium Code 02052: Explicitly covers mid-tier compound machines and multi-joint benching variations. | Bench Press, Lat Pulldown, Leg Press, Seated Row. |
| Tier 3: High | 6.0 | Compendium Code 02054: Vigorous, full-body compound movements requiring spinal/core stabilization and extensive systemic oxygen recovery. | Conventional Deadlift, Barbell Squats, Barbell Lunges, Cleans. |

---

## Step 4: The Mathematical Execution Library

1. Per-Set Active Caloric Calculation:

   Kcal_Active = ( (cMET_Active × 3.5 × Weight_KG) / 200 ) × (TUT_Seconds / 60)

2. Per-Set Recovery Rest Caloric Calculation:

   Kcal_Rest = ( (cMET_Rest × 3.5 × Weight_KG) / 200 ) × (Rest_Time_Seconds / 60)

3. Cumulative Exercise Summary:

   Exercise_Total_Kcal = Σ Kcal_Active,i (i=1..Sets) + Σ Kcal_Rest,j (j=1..Sets-1)

4. The 10% EPOC Recovery Premium (The Smart Afterburn):

   Workout_Session_Total_Kcal = (Σ Exercise_Total_Kcal) × 1.10

---

## Complete Mathematical Reference Walkthrough

User Data Profile: Male, 25 years old, 178 cm, 85.8 kg.
Exercise Logged: Conventional Deadlift (Tier 3: Base MET 6.0).
Set Parameters: 70 kg for 5 Reps. Inter-set rest recorded at 90 seconds.

### Phase 1: Custom Correction Calculation
1. RMR = (10 × 85.8) + (6.25 × 178) - (5 × 25) + 5 = 858 + 1112.5 - 125 + 5 = 1850.5 kcal/day
2. Oxygen_Baseline = ((1850.5 / 1440) / 5) / 85.8 × 1000 = (1.285 / 5) / 85.8 × 1000 = 2.995 mL/kg/min
3. C_f = 3.5 / 2.995 = 1.168

### Phase 2: Active Set State Calculation
1. TUT_Seconds = (5 × 3.5) + 3.0 = 20.5 seconds
2. cMET_Active = (6.0 × 1.168) × (1 + (70/85.8) × 0.12) = 7.008 × 1.0979 = 7.694
3. Kcal_Active = ((7.694 × 3.5 × 85.8) / 200) × (20.5 / 60) = 11.55 × 0.3416 = 3.94 kcal

### Phase 3: Passive Rest State Calculation
1. cMET_Rest = 1.5 × 1.168 = 1.752
2. Kcal_Rest = ((1.752 × 3.5 × 85.8) / 200) × (90 / 60) = 2.63 × 1.5 = 3.94 kcal

---

## Sources cited in the original document
1. https://protealpes.com/en/outils/calories-musculation/
2. https://sites.google.com/site/compendiumofphysicalactivities/corrected-mets
3. https://www.repcountapp.com/calculators/calories
4. https://www.youtube.com/watch?v=xR7KSB9CjFc
5. https://olaben.com/blogs/olaben-blog/how-many-calories-do-you-burn-lifting-weights
6. https://www.forhers.com/resources/nutrition/calories-burned/lifting-weights
7. https://bitekit.app/tools/hiit-calorie-calculator
