class_name NutritionTypes
extends RefCounted

const MODES := {
	"idle": 0,
	"walk": 1,
	"jog": 2,
	"sprint": 3,
	"crouch": 4
}

class NutritionState:
	extends RefCounted
	var calorie_reserve_kcal: float = 1800.0
	var hydration_liters: float = 2.5
	var electrolyte_index: float = 0.9
	var stomach_fill_ml: float = 0.0
	var stomach_capacity_ml: float = 1200.0
	var blood_glucose_energy: float = 120.0
	var fatigue_index: float = 0.1
	var nutrition_quality_7d: float = 0.8
	var protein_debt: float = 0.0
	var malnutrition_flags: int = 0

	func to_dict() -> Dictionary:
		return {
			"calorie_reserve_kcal": calorie_reserve_kcal,
			"hydration_liters": hydration_liters,
			"electrolyte_index": electrolyte_index,
			"stomach_fill_ml": stomach_fill_ml,
			"stomach_capacity_ml": stomach_capacity_ml,
			"blood_glucose_energy": blood_glucose_energy,
			"fatigue_index": fatigue_index,
			"nutrition_quality_7d": nutrition_quality_7d,
			"protein_debt": protein_debt,
			"malnutrition_flags": malnutrition_flags
		}

	func from_dict(d: Dictionary) -> void:
		for k in d.keys():
			set(k, d[k])

class StomachEntry:
	extends RefCounted
	var item_id: StringName
	var remaining_mass_g: float
	var remaining_volume_ml: float
	var digestion_curve_id: StringName
	var carb_g: float
	var fat_g: float
	var protein_g: float
	var sodium_mg: float
	var water_ml_remaining: float
	var spoilage_state: String = "fresh"
	var absorption_modifier: float = 1.0
	var time_in_stomach_s: float = 0.0
	var quality_score: float = 1.0

	func to_dict() -> Dictionary:
		return {
			"item_id": str(item_id),
			"remaining_mass_g": remaining_mass_g,
			"remaining_volume_ml": remaining_volume_ml,
			"digestion_curve_id": str(digestion_curve_id),
			"carb_g": carb_g,
			"fat_g": fat_g,
			"protein_g": protein_g,
			"sodium_mg": sodium_mg,
			"water_ml_remaining": water_ml_remaining,
			"spoilage_state": spoilage_state,
			"absorption_modifier": absorption_modifier,
			"time_in_stomach_s": time_in_stomach_s,
			"quality_score": quality_score
		}
