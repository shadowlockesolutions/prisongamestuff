class_name FoodDatabase
extends Node

var foods: Dictionary = {}

func load_from_json(path: String) -> void:
	foods.clear()
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("FoodDatabase: cannot open %s" % path)
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("FoodDatabase: invalid JSON root")
		return
	for food in parsed.get("foods", []):
		foods[food["id"]] = food

func get_food(item_id: StringName) -> Dictionary:
	return foods.get(str(item_id), {})
