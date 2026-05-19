class_name ConditionModel
extends RefCounted

func quality_to_absorption(quality_state: Dictionary) -> float:
	var spoilage := quality_state.get("spoilage", "fresh")
	match spoilage:
		"stale":
			return 0.95
		"spoiled":
			return 0.7
		"contaminated":
			return 0.55
		_:
			return 1.0

func illness_risk(quality_state: Dictionary) -> float:
	var spoilage := quality_state.get("spoilage", "fresh")
	match spoilage:
		"stale": return 0.02
		"spoiled": return 0.2
		"contaminated": return 0.35
		_: return 0.0
