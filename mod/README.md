# Road to Vostok Survival Overhaul Mod (Nutrition Core)

This package is a complete, implementation-ready **nutrition/hydration/metabolism module** for integration into a Godot-based project.

## Included

- Data-driven food database (`mod/data/foods.json`)
- Runtime configuration (`mod/config/metabolism_config.json`)
- Modular GDScript systems:
  - `nutrition_system.gd`
  - `food_database.gd`
  - `digestion_model.gd`
  - `metabolism_model.gd`
  - `status_effect_model.gd`
  - `condition_model.gd`
  - `persistence_adapter.gd`
  - `nutrition_types.gd`

## Integration

1. Add `nutrition_system.gd` as a child node under your player survival controller.
2. Set data/config file paths in the exported variables.
3. Wire gameplay events to:
   - `set_movement_mode(mode)`
   - `set_combat_intensity(v)`
   - `set_environment(temp_c, wet, insulation)`
   - `set_injury_load(v)`
   - `set_sleep_debt(hours)`
   - `consume(item_id, quality_state)`
4. Apply modifiers from the `effects_changed` signal to stamina/healing/sway/etc systems.

## Notes

This is a complete subsystem implementation, but exact balancing should be tuned against your movement/combat values.


## Build `.vmz` for Road to Vostok testing

From repo root:

```bash
python scripts/build_vmz.py
```

This creates `dist/r2v_nutrition_overhaul.vmz` that you can drop directly into your Road to Vostok mods folder.


## UI (HUD + Item Nutrition Info)

Included UI scenes:

- `res://mod/ui/nutrition_hud.tscn`
- `res://mod/ui/food_info_panel.tscn`

### Nutrition HUD setup

1. Add `nutrition_hud.tscn` to your gameplay UI canvas.
2. Set `nutrition_system_path` on the HUD node to your `NutritionSystem` node.
3. The HUD auto-updates from `nutrition_state_changed`.

### Food info panel setup

1. Add `food_info_panel.tscn` to your inventory/loot UI.
2. At runtime, call:

```gdscript
food_info_panel.set_food_database(nutrition_system.food_db)
food_info_panel.show_item(StringName(item_id))
```

Use `show_item` whenever player highlights/selects a consumable item.
