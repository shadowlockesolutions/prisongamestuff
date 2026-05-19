class_name PersistenceAdapter
extends RefCounted

const SAVE_VERSION := 1

func snapshot(state, stomach: Array, input: Dictionary) -> Dictionary:
	var entries: Array = []
	for e in stomach:
		entries.append(e.to_dict())
	return {
		"nutrition_save_version": SAVE_VERSION,
		"state": state.to_dict(),
		"stomach": entries,
		"input": input
	}
