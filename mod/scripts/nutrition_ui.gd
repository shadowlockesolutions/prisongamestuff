class_name NutritionUI
extends Control

@export var nutrition_system_path: NodePath
@onready var nutrition_system: NutritionSystem = get_node_or_null(nutrition_system_path)

@onready var calories_value: Label = %CaloriesValue
@onready var hydration_value: Label = %HydrationValue
@onready var fatigue_value: Label = %FatigueValue
@onready var stomach_value: Label = %StomachValue
@onready var electrolytes_value: Label = %ElectrolytesValue
@onready var energy_value: Label = %EnergyValue

func _ready() -> void:
	if nutrition_system == null:
		push_warning("NutritionUI: nutrition_system_path is not set")
		return
	nutrition_system.nutrition_state_changed.connect(_on_nutrition_state_changed)
	_on_nutrition_state_changed(nutrition_system.state.to_dict())

func _on_nutrition_state_changed(state_dict: Dictionary) -> void:
	calories_value.text = "%d kcal" % int(round(state_dict.get("calorie_reserve_kcal", 0.0)))
	hydration_value.text = "%.2f L" % float(state_dict.get("hydration_liters", 0.0))
	fatigue_value.text = "%d%%" % int(round(float(state_dict.get("fatigue_index", 0.0)) * 100.0))
	stomach_value.text = "%d / %d ml" % [
		int(round(float(state_dict.get("stomach_fill_ml", 0.0)))),
		int(round(float(state_dict.get("stomach_capacity_ml", 1200.0))))
	]
	electrolytes_value.text = "%d%%" % int(round(float(state_dict.get("electrolyte_index", 0.0)) * 100.0))
	energy_value.text = "%d" % int(round(float(state_dict.get("blood_glucose_energy", 0.0))))
