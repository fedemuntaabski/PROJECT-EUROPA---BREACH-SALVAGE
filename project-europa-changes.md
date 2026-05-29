# Project Europa - Pressure Point

Development log and implementation guide for the current UI state, the Steam lobby flow, and the launch-match issue.

## Project Overview

**Title:** Project Europa - Pressure Point

**Genre:** Co-op (1-4 players) isometric tactical roguelike crisis management game.

**Core Concept:** Players escort a cargo core through an underwater station. Moving or opening bulkheads acts as a turn trigger, calculating hydrostatic pressure, flooding propagation, and deep-sea monster spawns.

## Current Features Checklist

### Completed

- Main Menu is functional and can start a new operations flow.
- Basic Settings Menu exists and returns cleanly to the main menu.
- Steam name is fetched and shown in the Mission Preparation / Lobby scene.
- Host status is visible in the lobby state.
- Lobby membership and role metadata are already wired through Steam lobby callbacks.

### Pending or Broken

- The role selector still uses placeholder labels and must be aligned to the official four roles.
- The `Iniciar Descenso` / `INITIATE DESCENT` button is currently broken as a reliable match start trigger.
- Peer-wide scene transition should be hardened so all connected players enter gameplay together.
- Lobby start flow still depends on a chat-message command and needs clearer validation and fallback handling.

## Current UI State

### Main Menu

The main menu is already in place and currently acts as the entry point into the Steam lobby flow. The existing script path is `scripts/ui/main_menu.gd`, and it transitions into lobby creation through `SteamNetwork.create_mission_lobby()`.

### Settings Menu

The settings screen is minimal but functional. It supports volume and fullscreen options and then returns to the main menu.

### Mission Preparation / Lobby

The lobby scene is built in `scripts/core/Lobby.gd` and attached to `scenes/ui/Lobby.tscn`. It already:

- shows the Steam persona name for each lobby member,
- marks the owner as host,
- reads player role metadata from Steam lobby member data,
- listens for `player_list_changed` and `role_updated` signals from `SteamNetwork`.

The current implementation is intentionally lightweight, but the role labels are still placeholder text and the match launch command needs a more reliable handoff.

## UI Refactoring Guide

### Goal

Replace the current placeholder roles with the official four gameplay roles while keeping the lobby UI simple and easy to maintain.

### Official Roles

1. **Ingeniero Electrónico** - Electrical engineer focused on energy economy and module optimization.
2. **Mecánico / Soldador** - Mechanic / welder focused on flood control, pressure mitigation, and repairs.
3. **Oficial de Seguridad** - Security officer focused on combat, aggro control, and infrastructure protection.
4. **Médico / Científico** - Medic / scientist focused on crew healing and bioluminescent research management.

### Recommended Implementation Pattern

The cleanest option in the current codebase is to keep the lobby scene dynamic and populate the `OptionButton` from a single role table. That preserves the current Control-based flow and avoids hardcoding duplicate labels in the scene.

#### GDScript blueprint

```gdscript
extends Control

const ROLE_DEFINITIONS := [
	{
		"id": "electrical_engineer",
		"label": "Ingeniero Electrónico",
		"summary": "Energy economy and module optimization."
	},
	{
		"id": "mechanic_welder",
		"label": "Mecánico / Soldador",
		"summary": "Flood control, pressure mitigation, and repairs."
	},
	{
		"id": "security_officer",
		"label": "Oficial de Seguridad",
		"summary": "Combat, aggro control, and infrastructure protection."
	},
	{
		"id": "medic_scientist",
		"label": "Médico / Científico",
		"summary": "Crew healing and bioluminescent research management."
	},
]

@onready var role_selector: OptionButton = $MainVBox/RoleSelector

func _ready() -> void:
	_populate_roles()

func _populate_roles() -> void:
	role_selector.clear()
	for role_data in ROLE_DEFINITIONS:
		role_selector.add_item(role_data["label"])
		role_selector.set_item_metadata(role_selector.item_count - 1, role_data)

func _on_role_selected(index: int) -> void:
	var role_data: Dictionary = role_selector.get_item_metadata(index)
	if role_data.is_empty():
		return

	print("Selected role: ", role_data["id"], " / ", role_data["label"])
	if SteamNetwork.is_steam_running and SteamNetwork.lobby_id != 0:
		Steam.setLobbyMemberData(SteamNetwork.lobby_id, "role", role_data["label"])
```

### Notes for the refactor

- Keep the displayed label human-readable and stable.
- If you want the internal role ID to remain language-agnostic, store the ID in metadata and only send the display label to the lobby UI.
- If the scene is rebuilt manually like the current lobby script, the role list can be repopulated in `_ready()` without changing the scene file.
- If later you want tooltips or richer descriptions, add a `Label` below the selector instead of adding a heavier UI layer.

## Troubleshooting Guide for `Iniciar Descenso`

### Current flow in the codebase

The current launch sequence is:

1. Host clicks the start button in `scripts/core/Lobby.gd`.
2. `_on_start_pressed()` sends `START_DESCENT` through `Steam.sendLobbyChatMsg(...)`.
3. `SteamNetwork._on_lobby_message()` receives the lobby message.
4. If the message matches, `SceneManager.change_scene("res://scenes/ui/Descenso.tscn")` runs.

### Code checklist

Use this checklist to diagnose the break:

1. Confirm the host is actually flagged as host in `SteamNetwork.is_host` before the button is shown.
2. Confirm `SteamNetwork.lobby_id` is not zero when the button is pressed.
3. Confirm `Steam.sendLobbyChatMsg()` is being called with the correct lobby ID and string payload.
4. Confirm `Steam.lobby_message` is connected inside `SteamNetwork._initialize_steam()`.
5. Confirm the callback signature still matches the GodotSteam version being used.
6. Confirm the message type check is correct for the Steam API version in use.
7. Confirm the transition scene path `res://scenes/ui/Descenso.tscn` still exists and loads cleanly.
8. Confirm `SceneManager.change_scene()` is not being called from a stale node that has already been freed.
9. Confirm clients are still in the lobby when the host starts the match.

### Common failure points

- The lobby message callback may be connected, but the message type check may be too strict for the actual message type returned by Steam.
- The host may press the button before the lobby state is fully synchronized.
- A scene transition may disconnect UI nodes if the callback fires after the lobby scene is already being replaced.
- The lobby owner may change, but the `is_host` state may not be refreshed.
- Peer membership changes may happen during the transition and leave some clients without the start event.
- The scene path may exist, but the destination scene may still have a broken script or missing resource dependency.

### Recommended host-side boilerplate

The current lobby-chat approach can be kept, but it should be wrapped in a small match-start function so the launch intent is explicit and easy to debug.

```gdscript
func _on_start_pressed() -> void:
	if not SteamNetwork.is_host:
		return
	if not SteamNetwork.is_steam_running:
		push_warning("Steam is not initialized.")
		return
	if SteamNetwork.lobby_id == 0:
		push_warning("No active lobby to start.")
		return

	print("Host started match. Broadcasting start command...")
	Steam.sendLobbyChatMsg(SteamNetwork.lobby_id, "START_DESCENT")

func _on_lobby_message(this_lobby_id: int, user_id: int, text: String, type: int) -> void:
	if this_lobby_id != lobby_id:
		return

	if text != "START_DESCENT":
		return

	if Steam.getLobbyOwner(lobby_id) != user_id:
		print("Ignoring start command from non-owner sender: ", user_id)
		return

	print("Match start confirmed from host. Loading gameplay scene...")
	SceneManager.change_scene("res://scenes/ui/Descenso.tscn")
```

### More robust peer-wide pattern

If you want to harden this beyond chat-command broadcast, use the host as authority and send a dedicated start state to every peer before changing scenes locally.

```gdscript
const MATCH_STATE_KEY := "match_state"
const MATCH_START_VALUE := "descending"

func _start_match_as_host() -> void:
	if not SteamNetwork.is_host:
		return

	Steam.setLobbyData(SteamNetwork.lobby_id, MATCH_STATE_KEY, MATCH_START_VALUE)
	Steam.sendLobbyChatMsg(SteamNetwork.lobby_id, "START_DESCENT")
	SceneManager.change_scene("res://scenes/ui/Descenso.tscn")

func _on_lobby_data_update(_success: int, this_lobby_id: int, _member_id: int, key: String) -> void:
	if this_lobby_id != lobby_id:
		return

	if key != MATCH_STATE_KEY:
		return

	var match_state := Steam.getLobbyData(lobby_id, MATCH_STATE_KEY)
	if match_state == MATCH_START_VALUE:
		SceneManager.change_scene("res://scenes/ui/Descenso.tscn")
```

### Why this helps

- Lobby metadata gives late-joining or slightly delayed peers a stable start state.
- The chat message still works as the immediate trigger.
- The host can change scenes locally at the same time, while clients can catch the same state through the lobby update callback.

## Practical Debug Checklist

Before calling the button fixed, verify the following in order:

1. The lobby scene loads with the correct Steam name.
2. The host badge appears for the lobby owner.
3. The role selector shows the four official roles.
4. The host button is only visible for the host.
5. Pressing the start button prints a local host log line.
6. `SteamNetwork._on_lobby_message()` prints the incoming command.
7. `Descenso.tscn` loads successfully on the host.
8. Clients receive the same start event and transition to the gameplay scene.

## Implementation Notes

- Keep `SteamNetwork` as the central Steam callback manager.
- Keep `SceneManager` as the single scene-switch utility.
- Avoid introducing a new matchmaking manager unless the current callback flow proves too fragile.
- Prefer small incremental fixes over a large networking rewrite.

## Status Summary

The lobby foundation is present, the host identity is visible, and the main menu flow works. The next required step is to replace placeholder role text with the official four roles and harden the host-driven start transition so every peer enters the gameplay scene together.