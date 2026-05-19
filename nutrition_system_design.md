# Road to Vostok Realistic Nutrition & Calorie System Design

## 1) System Architecture Overview

Design this as a **set of focused subsystems** rather than one giant player script.

- **NutritionSystem (orchestrator):** central coordinator that owns current survival-state values, receives gameplay events, and advances metabolism ticks.
- **FoodDatabase:** loads item definitions from data files (JSON/CFG/Resources) and exposes lookup by `item_id`.
- **DigestionModel:** simulates stomach contents, absorption timing, and conversion into metabolic pools.
- **MetabolismModel:** burns calories/hydration based on activity + context, applies fatigue/energy changes.
- **StatusEffectModel:** translates physiological state into gameplay modifiers (stamina regen, sway, healing rate, cognition penalties).
- **ConditionModel:** applies food quality/spoilage outcomes (illness risk, vomiting, nutrient loss).
- **PersistenceAdapter:** save/load snapshot of all stateful pools and timers.

### Key Principles

- **Data-driven:** food/item properties live in config, not code.
- **Event-driven:** ingest gameplay events (`sprinted`, `temperature_changed`, `damage_taken`) and process in coarse intervals.
- **Two-rate simulation:**
  - fast loop for immediate player feedback (e.g., every 0.25–0.5s),
  - slow loop for metabolic digestion and long-term effects (e.g., every 5–10s).
- **Future-ready interfaces:** expose stable APIs so body temp/disease/sleep can inject modifiers without rewriting core metabolism.

---

## 2) Recommended Node Structure (Godot/GDScript)

```text
Player
├── SurvivalController (Node)
│   ├── NutritionSystem (Node)
│   │   ├── MetabolismModel (Resource/Node)
│   │   ├── DigestionModel (Resource/Node)
│   │   ├── StatusEffectModel (Resource/Node)
│   │   ├── ConditionModel (Resource/Node)
│   │   └── FoodDatabase (Node/Autoload service)
│   └── FatigueSystem (optional split now or later)
└── UI Hooks (HUD widgets subscribe to signals)
```

### Why this structure

- Keeps survival simulation independent from combat/movement code.
- Allows partial reuse for AI survivors later.
- Supports easy testing by mocking activity events and stepping simulation manually.

---

## 3) Suggested Data Models

## 3.1 Core Runtime State (`NutritionState`)

- `calorie_reserve_kcal: float` (long-term storage)
- `hydration_liters: float`
- `electrolyte_index: float` (0..1)
- `stomach_fill_ml: float`
- `stomach_capacity_ml: float`
- `blood_glucose_energy: float` (short-term carbs energy proxy)
- `fatigue_index: float` (0..1)
- `nutrition_quality_7d: float` (rolling average)
- `protein_debt: float` (tracks recovery deficit over time)
- `malnutrition_flags: bitmask`

## 3.2 Digestion Entry (`StomachEntry`)

- `item_id: StringName`
- `remaining_mass_g: float`
- `remaining_volume_ml: float`
- `digestion_curve_id: StringName`
- `macro_remaining: {carb_g, fat_g, protein_g, sodium_mg}`
- `water_ml_remaining: float`
- `spoilage_state_at_consumption`
- `absorption_modifier`
- `time_in_stomach_s`

## 3.3 Activity Snapshot (`MetabolicInput`)

- `movement_mode: enum` (idle/walk/jog/sprint/crouch)
- `carried_kg: float`
- `ambient_temp_c: float`
- `is_wet / clothing_insulation`
- `combat_intensity: float`
- `injury_load: float`
- `sleep_debt_hours: float`
- `illness_factor: float`

---

## 4) Example Food Database Structure (Data-Driven)

Use one primary data source (JSON or `.tres`/`.res`) and load into typed structs.

```json
{
  "version": 1,
  "foods": [
    {
      "id": "canned_beans",
      "name": "Canned Beans",
      "mass_g": 415,
      "volume_ml": 380,
      "calories_kcal": 360,
      "water_ml": 250,
      "macros": { "carb_g": 54, "fat_g": 2, "protein_g": 21, "sodium_mg": 1100 },
      "digestion": {
        "gastric_emptying": "medium",
        "carb_release": "steady",
        "satiety_score": 0.75
      },
      "quality": {
        "shelf_life_h": 8760,
        "spoilage_curve": "canned_low_risk",
        "contamination_risk": 0.01
      },
      "effects": {
        "instant_hydration_ml": 40,
        "mental_comfort": 0.05
      }
    }
  ]
}
```

### Required item fields (minimum)

- identity: `id`, `name`, `category`
- physical: `mass_g`, `volume_ml`
- nutrition: `calories_kcal`, `carb_g`, `fat_g`, `protein_g`, `sodium_mg`, `water_ml`
- digestion: emptying speed + absorption profile
- quality: shelf life, spoilage curve, contamination probabilities
- gameplay tags: stimulant/alcohol/hot/cold/preserved

---

## 5) Metabolism Update Logic

## 5.1 Base Equation (per tick)

`energy_burn = BMR_tick + activity_cost + load_cost + thermal_cost + injury_cost + sleep_debt_cost`

`hydration_loss = basal_water_loss + sweat_loss + respiration_loss + illness_loss`

Where each term is composed by multipliers from current state + external systems.

## 5.2 Activity Cost Model

Prefer table-driven multipliers instead of hardcoding if/else blocks:

- `idle = 1.0x`
- `walk = 1.8x`
- `jog = 3.0x`
- `sprint = 6.0x`
- `crouch_move = 2.2x`

Then scale by carried weight and terrain/temperature modifiers.

## 5.3 Threshold Bands (for gameplay feel)

Use broad physiological bands to avoid micromanagement:

- **Fed/Hydrated:** normal performance
- **Low:** subtle penalties, more fatigue
- **Critical:** heavy penalties, shakiness, cognitive impairment
- **Emergency:** collapse risk/starvation progression

This keeps realism while preserving readability for players.

---

## 6) Digestion Simulation Approach

Model digestion as **queue-based stomach processing** with staged absorption:

1. Ingestion adds one or more `StomachEntry` records.
2. Each metabolism tick advances `time_in_stomach_s`.
3. Gastric emptying moves nutrients/water into absorption pool using curve type:
   - liquid = fast
   - simple carbs = fast spike + short tail
   - protein = medium sustained
   - fats = slow long tail
4. Absorption converts to:
   - `blood_glucose_energy` (short-term)
   - `calorie_reserve_kcal` (long-term)
   - `hydration_liters`
   - `electrolyte_index`

### Overeating behavior

If `stomach_fill_ml > stomach_capacity_ml`:

- apply movement/sprint penalties
- increase discomfort noise/breathing
- possible vomiting chance if far above capacity

---

## 7) Example GDScript Pseudocode

```gdscript
class_name NutritionSystem
extends Node

signal nutrition_state_changed(state)
signal nutrition_band_changed(calorie_band, hydration_band)
signal consumed_item(item_id)

var state: NutritionState
var stomach: Array[StomachEntry] = []
var food_db: FoodDatabase

var fast_tick_s := 0.5
var slow_tick_s := 5.0
var _fast_accum := 0.0
var _slow_accum := 0.0

func _process(delta: float) -> void:
    _fast_accum += delta
    _slow_accum += delta

    if _fast_accum >= fast_tick_s:
        _fast_accum = 0.0
        _apply_immediate_effects()

    if _slow_accum >= slow_tick_s:
        _slow_accum = 0.0
        var input := _build_metabolic_input()
        _advance_digestion(slow_tick_s)
        _apply_metabolism(input, slow_tick_s)
        _recompute_bands_and_modifiers()
        emit_signal("nutrition_state_changed", state)

func consume(item_id: StringName, quality_state: Dictionary) -> bool:
    var def := food_db.get_food(item_id)
    if not def:
        return false

    if state.stomach_fill_ml + def.volume_ml > state.stomach_capacity_ml * 1.25:
        return false # hard cap for anti-spam

    _add_stomach_entry(def, quality_state)
    emit_signal("consumed_item", item_id)
    return true

func _apply_metabolism(input: MetabolicInput, dt_s: float) -> void:
    var kcal_burn := metabolism_model.compute_kcal_burn(state, input, dt_s)
    var water_loss_l := metabolism_model.compute_water_loss(state, input, dt_s)

    _spend_energy(kcal_burn)
    state.hydration_liters = max(0.0, state.hydration_liters - water_loss_l)
    state.fatigue_index = fatigue_model.compute_fatigue(state, input, dt_s)
```

---

## 8) Save/Load Considerations

Persist both **aggregates** and **in-flight digestion**:

- `NutritionState` complete scalar fields
- full stomach queue with remaining nutrients/time
- active illness/food-poisoning timers
- rolling diet quality window or compressed accumulator
- versioned schema (`nutrition_save_version`)

### Backward compatibility

- Include migration layer for old save versions.
- Default missing fields to safe physiological mid-values.

---

## 9) Performance Optimization Ideas

- Tick heavy metabolism at 2–10s intervals, not every frame.
- Use event-driven recalculation for activity multipliers (only when stance/speed/load/temp changes).
- Precompute lookup tables for burn multipliers and digestion curves.
- Avoid per-item per-frame loops; process stomach entries only on slow tick.
- Cap stomach queue length via stack merging (same item + same quality).
- Use signal throttling for UI updates (e.g., 2–4 Hz max).

---

## 10) Expansion Hooks (Future Compatibility)

Expose extension points now:

- `register_metabolic_modifier(source_id, modifier_fn)`
- `register_absorption_modifier(source_id, modifier_fn)`
- `register_hydration_modifier(source_id, modifier_fn)`

Future systems can then inject effects cleanly:

- **Body temperature:** thermal stress adjusts kcal burn and water loss.
- **Disease:** nutrient absorption penalties, diarrhea dehydration spikes.
- **Stress:** appetite suppression, stimulant overuse crash behavior.
- **Injuries:** healing protein demand and resting calorie burden.
- **Sleep:** sleep debt multiplier for fatigue and metabolic inefficiency.
- **AI survival behavior:** reuse same data model for NPC decisions.

---

## 11) Balancing Philosophy (Realism Without Tedium)

- Hide exact numbers by default; show qualitative states + trend arrows.
- Reserve precision stats for advanced UI or difficulty mode.
- Use forgiving early thresholds and harsh late-stage collapse to create tension.
- Reward planning (meal quality + hydration strategy) over constant micromanagement.
- Make food identity meaningful (e.g., jerky ≠ candy ≠ noodles), but keep values understandable.

This produces an immersive survival loop where nutrition choices matter in combat, travel, recovery, and long-term endurance.
