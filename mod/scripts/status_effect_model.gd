class_name StatusEffectModel
extends RefCounted

func compute_modifiers(state) -> Dictionary:
	var hydration_pct := clamp(state.hydration_liters / 3.0, 0.0, 1.0)
	var kcal_pct := clamp(state.calorie_reserve_kcal / 2200.0, 0.0, 1.0)
	var energy_pct := clamp(state.blood_glucose_energy / 180.0, 0.0, 1.0)
	var stamina_regen := 0.5 + hydration_pct * 0.25 + kcal_pct * 0.25
	var healing_rate := 0.5 + clamp(1.0 - state.protein_debt, 0.0, 1.0) * 0.5
	var sway := 1.0 + (1.0 - energy_pct) * 0.6 + state.fatigue_index * 0.8
	var cognition := clamp((hydration_pct * 0.6 + energy_pct * 0.4) - state.fatigue_index * 0.5, 0.1, 1.0)
	return {
		"stamina_regen_mul": stamina_regen,
		"healing_mul": healing_rate,
		"weapon_sway_mul": sway,
		"cognition_mul": cognition,
		"sprint_efficiency_mul": 1.0 - clamp(state.stomach_fill_ml / (state.stomach_capacity_ml * 1.4), 0.0, 0.25)
	}
