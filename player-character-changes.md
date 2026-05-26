# Player Character Changes

This document summarizes the initial player character architecture added for Project Europa. The goal of this pass was to create a modular, production-oriented foundation for the controllable character without adding enemies, procedural generation, networking, UI systems, or flood simulation logic.

## What Was Added

### New character scene

- Added [scenes/player/Character.tscn](scenes/player/Character.tscn) as the first dedicated player character scene.
- The root node is `CharacterBody2D`, which makes the player a proper physics-driven actor instead of a simple transform-moving node.
- The scene is organized around a clean, expandable node hierarchy:
  - `Character`
  - `Visuals`
    - `Sprite2D`
    - `Shadow`
    - `Effects`
  - `CollisionShape2D`
  - `InteractionArea`
  - `DirectionMarker`
  - `Audio`
  - `Components`
    - `HealthComponent`
    - `StatsComponent`
    - `AbilityComponent`
    - `StatusEffectComponent`
    - `InventoryComponent`
  - `AnimationController`

### New root controller

- Updated [scripts/player/player.gd](scripts/player/player.gd) to act as the main character controller.
- The script now extends `CharacterBody2D` and is named `CharacterController`.
- It owns:
  - top-down movement input
  - acceleration and deceleration
  - facing direction tracking
  - interaction request routing
  - death response from the health component
- It does not own health, stats, abilities, status effects, or inventory state directly.

### New component scripts

- Added [scripts/player/components/health_component.gd](scripts/player/components/health_component.gd).
- Added [scripts/player/components/stats_component.gd](scripts/player/components/stats_component.gd).
- Added [scripts/player/components/ability_component.gd](scripts/player/components/ability_component.gd).
- Added [scripts/player/components/status_effect_component.gd](scripts/player/components/status_effect_component.gd).
- Added [scripts/player/components/inventory_component.gd](scripts/player/components/inventory_component.gd).
- Added [scripts/player/character_animation_controller.gd](scripts/player/character_animation_controller.gd).

## Architecture Details

### Movement

- Movement is handled in `_physics_process()` using `Input.get_vector()`.
- The controller uses the existing input actions already present in `project.godot`:
  - `left`
  - `right`
  - `up`
  - `down`
  - `interact`
- Motion uses smooth acceleration when moving and smooth deceleration when input stops.
- Movement speed is not hardcoded into the movement code path; it is pulled from `StatsComponent` when available and falls back to a local default.

### Interaction framework

- Added an `InteractionArea` based on `Area2D` for proximity detection.
- The character tracks nearby interaction targets in a local list.
- The controller exposes `request_interaction()` as the main entry point for interaction requests.
- Interaction is intentionally generic:
  - it looks for targets that are in the `interactable` group, or
  - targets that expose `interact()`, `on_interact()`, or `can_interact()`.
- If a target supports `interact(self)` or `on_interact(self)`, the controller calls it and emits interaction signals.

### Health system

- `HealthComponent` owns current health, max health, damage handling, healing, and death state.
- It exposes these signals:
  - `health_changed(current_health, max_health)`
  - `died`
  - `healed(amount, source)`
  - `damaged(amount, source)`
- The component supports both direct health setting and runtime damage/heal calls.
- The controller listens for the death signal and stops movement when the character dies.

### Stats system

- `StatsComponent` stores the base tunable character values.
- The following stats are currently supported:
  - `movement_speed`
  - `repair_speed`
  - `flood_resistance`
  - `pressure_tolerance`
- The component also supports an `extra_stats` dictionary so future stats can be added without restructuring the API.
- A generic `get_stat(stat_name)` method was added so other systems can query values in a consistent way.

### Ability foundation

- `AbilityComponent` is a lightweight registry for future role abilities.
- It does not implement any actual abilities yet.
- It is prepared for role-based expansion such as:
  - Operator
  - Technician
  - Custodian
- The component exposes these signals:
  - `ability_registered(ability_id)`
  - `ability_used(ability_id, user, payload)`
  - `ability_unavailable(ability_id)`
- The current implementation only stores ability metadata and provides a safe `use_ability()` dispatch surface for later work.

### Status effects

- `StatusEffectComponent` is a storage-and-events layer for future buffs, debuffs, hazards, and environmental effects.
- It supports adding, removing, querying, and clearing status effects.
- It intentionally does not resolve effect behavior yet.

### Inventory

- `InventoryComponent` provides a basic item container for later expansion.
- It supports adding, removing, querying, and clearing items.
- It is intentionally minimal so item logic can be introduced later without changing the character controller.

### Animation and visuals

- `CharacterAnimationController` keeps facing state separate from gameplay logic.
- It updates the `DirectionMarker` rotation and flips the sprite horizontally for left-facing movement.
- Visual nodes are intentionally isolated under `Visuals` so future animation and effect work does not leak gameplay responsibilities into rendering nodes.

## Signals And Communication

The new player stack is designed to communicate through signals rather than tight direct coupling.

Current signals include:

- `interaction_requested(target)`
- `interacted(target)`
- `facing_changed(direction)`
- `health_changed(current_health, max_health)`
- `died`
- `healed(amount, source)`
- `damaged(amount, source)`
- `stats_changed`
- `ability_registered(ability_id)`
- `ability_used(ability_id, user, payload)`
- `ability_unavailable(ability_id)`
- `status_effect_added(effect_id)`
- `status_effect_removed(effect_id)`
- `status_effects_cleared`
- `inventory_changed`

This keeps the character easy to extend later without turning the root controller into a monolithic script.

## Design Constraints Kept Intact

- The character does not control flood simulation.
- The character only reacts to environment state through exposed stats and future status effects.
- No enemies were added.
- No procedural generation was added.
- No networking was added.
- No UI systems were added.
- No actual abilities were implemented yet.

## Current Implementation Notes

- The new scene is ready to be wired into a test level or world scene later.
- The controller is compatible with the existing `$Player`-style expectation used by the current world setup.
- The implementation stays deliberately small and modular so future systems can be added without rewriting the player foundation.

## Future Follow-Up

The next useful additions would be:

- wiring the scene into a playable test level
- adding concrete interactables that respond to the new interaction contract
- adding animation clips or state machine hooks
- expanding the ability registry into role-specific gameplay behavior
- linking stats and status effects to room conditions such as flooding and pressure
