class_name MetabolismModel
extends RefCounted

var mode_multipliers := {
	0: 1.0,
	1: 1.8,
	2: 3.0,
	3: 6.0,
	4: 2.2
}

func compute_kcal_burn(state, input: Dictionary, dt_s: float, cfg: Dictionary) -> float:
	var bmr_per_day := cfg.get("bmr_kcal_day", 1900.0)
	var bmr_tick := bmr_per_day * (dt_s / 86400.0)
	var mode_mul := mode_multipliers.get(input.get("movement_mode", 0), 1.0)
	var combat_mul := 1.0 + (input.get("combat_intensity", 0.0) * 0.4)
	var weight_mul := 1.0 + max(0.0, input.get("carried_kg", 0.0) - 15.0) * 0.012
	var temp_cost := abs(input.get("ambient_temp_c", 15.0) - cfg.get("thermal_neutral_temp_c", 15.0)) * cfg.get("temp_kcal_per_degree", 0.002)
	var injury_cost := input.get("injury_load", 0.0) * 0.2
	var sleep_cost := max(0.0, input.get("sleep_debt_hours", 0.0)) * 0.01
	return bmr_tick * mode_mul * combat_mul * weight_mul * (1.0 + temp_cost + injury_cost + sleep_cost)

func compute_water_loss(state, input: Dictionary, dt_s: float, cfg: Dictionary) -> float:
	var basal_per_day_l := cfg.get("water_loss_l_day", 2.2)
	var base := basal_per_day_l * (dt_s / 86400.0)
	var sweat := max(0.0, input.get("ambient_temp_c", 15.0) - 18.0) * 0.00002 * dt_s
	var mode := input.get("movement_mode", 0)
	if mode == 3:
		sweat += 0.00008 * dt_s
	elif mode == 2:
		sweat += 0.00003 * dt_s
	sweat *= 1.0 + input.get("combat_intensity", 0.0) * 0.5
	return base + sweat + input.get("illness_factor", 0.0) * 0.00003 * dt_s
