class_name FoodInfoPanel
extends Control

@onready var item_name_label: Label = %ItemName
@onready var calories_label: Label = %Calories
@onready var hydration_label: Label = %Hydration
@onready var macros_label: Label = %Macros
@onready var digestion_label: Label = %Digestion
@onready var sodium_label: Label = %Sodium
@onready var weight_label: Label = %Weight
@onready var volume_label: Label = %Volume

var food_db: FoodDatabase

func set_food_database(db: FoodDatabase) -> void:
	food_db = db

func show_item(item_id: StringName) -> void:
	if food_db == null:
		return
	var food := food_db.get_food(item_id)
	if food.is_empty():
		item_name_label.text = "Unknown Item"
		return

	item_name_label.text = str(food.get("name", item_id))
	calories_label.text = "Calories: %d kcal" % int(food.get("calories_kcal", 0))
	hydration_label.text = "Hydration: %d ml" % int(food.get("water_ml", 0))
	var macros := food.get("macros", {})
	macros_label.text = "Macros: C %dg | F %dg | P %dg" % [
		int(macros.get("carb_g", 0)),
		int(macros.get("fat_g", 0)),
		int(macros.get("protein_g", 0))
	]
	sodium_label.text = "Sodium: %d mg" % int(macros.get("sodium_mg", 0))
	digestion_label.text = "Digestion: %s" % str(food.get("digestion", {}).get("gastric_emptying", "medium"))
	weight_label.text = "Weight: %dg" % int(food.get("mass_g", 0))
	volume_label.text = "Volume: %dml" % int(food.get("volume_ml", 0))
