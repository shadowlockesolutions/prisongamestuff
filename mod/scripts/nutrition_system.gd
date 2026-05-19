class_name NutritionSystem
extends Node

signal nutrition_state_changed(state_dict)
signal effects_changed(modifiers)
signal consumed_item(item_id)

@export var foods_path := "res://mod/data/foods.json"
@export var config_path := "res://mod/config/metabolism_config.json"

var state := NutritionTypes.NutritionState.new()
var stomach: Array = []
var metabolic_input := {
	"movement_mode": NutritionTypes.MODES.idle,
	"carried_kg": 0.0,
	"ambient_temp_c": 15.0,
	"is_wet": false,
	"clothing_insulation": 1.0,
	"combat_intensity": 0.0,
	"injury_load": 0.0,
	"sleep_debt_hours": 0.0,
	"illness_factor": 0.0
}

var config := {}
var food_db := FoodDatabase.new()
var digestion_model := DigestionModel.new()
var metabolism_model := MetabolismModel.new()
var status_model := StatusEffectModel.new()
var condition_model := ConditionModel.new()
var persistence := PersistenceAdapter.new()

var slow_tick_s := 5.0
var _slow_accum := 0.0

func _ready() -> void:
	add_child(food_db)
	food_db.load_from_json(foods_path)
	config = _load_json(config_path)

func _process(delta: float) -> void:
	_slow_accum += delta
	if _slow_accum < slow_tick_s:
		return
	_slow_accum = 0.0
	var absorbed := digestion_model.process(stomach, state, slow_tick_s)
	_apply_absorption(absorbed)
	_apply_metabolism(slow_tick_s)
	var mods := status_model.compute_modifiers(state)
	emit_signal("effects_changed", mods)
	emit_signal("nutrition_state_changed", state.to_dict())

func consume(item_id: StringName, quality_state := {}) -> bool:
	var def := food_db.get_food(item_id)
	if def.is_empty():
		return false
	if state.stomach_fill_ml + float(def.get("volume_ml", 0.0)) > state.stomach_capacity_ml * 1.25:
		return false
	var e := NutritionTypes.StomachEntry.new()
	e.item_id = item_id
	e.remaining_mass_g = def.get("mass_g", 0.0)
	e.remaining_volume_ml = def.get("volume_ml", 0.0)
	e.digestion_curve_id = StringName(def.get("digestion", {}).get("gastric_emptying", "medium"))
	e.carb_g = def.get("macros", {}).get("carb_g", 0.0)
	e.fat_g = def.get("macros", {}).get("fat_g", 0.0)
	e.protein_g = def.get("macros", {}).get("protein_g", 0.0)
	e.sodium_mg = def.get("macros", {}).get("sodium_mg", 0.0)
	e.water_ml_remaining = def.get("water_ml", 0.0)
	e.spoilage_state = quality_state.get("spoilage", "fresh")
	e.absorption_modifier = condition_model.quality_to_absorption(quality_state)
	stomach.append(e)
	state.stomach_fill_ml += e.remaining_volume_ml
	emit_signal("consumed_item", item_id)
	return true

func _apply_absorption(abs: Dictionary) -> void:
	state.blood_glucose_energy += abs.get("carb_g", 0.0) * 2.5
	state.calorie_reserve_kcal += abs.get("fat_g", 0.0) * 9.0 + abs.get("protein_g", 0.0) * 4.0 + abs.get("carb_g", 0.0) * 1.5
	state.hydration_liters = min(3.5, state.hydration_liters + abs.get("water_ml", 0.0) / 1000.0)
	state.electrolyte_index = clamp(state.electrolyte_index + abs.get("sodium_mg", 0.0) / 8000.0, 0.0, 1.0)
	state.protein_debt = max(0.0, state.protein_debt - abs.get("protein_g", 0.0) * 0.005)

func _apply_metabolism(dt_s: float) -> void:
	var kcal_burn := metabolism_model.compute_kcal_burn(state, metabolic_input, dt_s, config)
	var water_loss := metabolism_model.compute_water_loss(state, metabolic_input, dt_s, config)
	if state.blood_glucose_energy > 0.0:
		state.blood_glucose_energy = max(0.0, state.blood_glucose_energy - kcal_burn * 0.5)
		state.calorie_reserve_kcal = max(0.0, state.calorie_reserve_kcal - kcal_burn * 0.5)
	else:
		state.calorie_reserve_kcal = max(0.0, state.calorie_reserve_kcal - kcal_burn)
	state.hydration_liters = max(0.0, state.hydration_liters - water_loss)
	state.fatigue_index = clamp(state.fatigue_index + 0.002 + (1.0 - clamp(state.hydration_liters / 2.0, 0.0, 1.0)) * 0.005, 0.0, 1.0)
	state.protein_debt = min(1.0, state.protein_debt + 0.001)

func set_movement_mode(mode: int) -> void:
	metabolic_input.movement_mode = mode

func set_combat_intensity(v: float) -> void:
	metabolic_input.combat_intensity = clamp(v, 0.0, 1.0)

func set_environment(temp_c: float, wet: bool, insulation: float) -> void:
	metabolic_input.ambient_temp_c = temp_c
	metabolic_input.is_wet = wet
	metabolic_input.clothing_insulation = insulation

func set_injury_load(v: float) -> void:
	metabolic_input.injury_load = clamp(v, 0.0, 1.0)

func set_sleep_debt(hours: float) -> void:
	metabolic_input.sleep_debt_hours = max(0.0, hours)

func set_carried_kg(v: float) -> void:
	metabolic_input.carried_kg = max(0.0, v)

func build_save() -> Dictionary:
	return persistence.snapshot(state, stomach, metabolic_input)

func _load_json(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var p = JSON.parse_string(f.get_as_text())
	if typeof(p) != TYPE_DICTIONARY:
		return {}
	return p
