class_name DigestionModel
extends RefCounted

var curve_rate_per_hour := {
	"liquid": 1.2,
	"fast": 0.8,
	"medium": 0.45,
	"slow": 0.2
}

func process(stomach: Array, state, dt_s: float) -> Dictionary:
	var absorbed := {"carb_g": 0.0, "fat_g": 0.0, "protein_g": 0.0, "sodium_mg": 0.0, "water_ml": 0.0}
	var dt_h := dt_s / 3600.0
	for i in range(stomach.size() - 1, -1, -1):
		var e = stomach[i]
		e.time_in_stomach_s += dt_s
		var rate := curve_rate_per_hour.get(str(e.digestion_curve_id), 0.35)
		var frac := clamp(rate * dt_h * e.absorption_modifier, 0.0, 1.0)
		absorbed.carb_g += e.carb_g * frac
		absorbed.fat_g += e.fat_g * frac
		absorbed.protein_g += e.protein_g * frac
		absorbed.sodium_mg += e.sodium_mg * frac
		absorbed.water_ml += e.water_ml_remaining * frac
		e.carb_g *= (1.0 - frac)
		e.fat_g *= (1.0 - frac)
		e.protein_g *= (1.0 - frac)
		e.sodium_mg *= (1.0 - frac)
		e.water_ml_remaining *= (1.0 - frac)
		e.remaining_volume_ml *= (1.0 - frac)
		e.remaining_mass_g *= (1.0 - frac)
		if e.remaining_mass_g <= 1.0:
			stomach.remove_at(i)
	state.stomach_fill_ml = 0.0
	for e in stomach:
		state.stomach_fill_ml += e.remaining_volume_ml
	return absorbed
