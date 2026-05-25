# Project Europa Changes

primer prompt


## Core game flow


- Added a minimal `Game.tscn` scene at `scenes/levels/Game.tscn`.
- Added `scripts/levels/game.gd` to handle a debug return path from the game scene.
- Bound `ui_cancel` to Escape in `project.godot` so the game scene can return to the main menu for testing.
- Updated `scripts/ui/main_menu.gd` so the Start button now loads `scenes/levels/Game.tscn` instead of the missing prototype level path.

## Intentional scope limits

- No gameplay systems were added.
- No grid, room, enemy, or save-state logic was added.
- No new manager layer was introduced; scene transitions still go through `SceneManager`.

## Notes

- The project instructions file `project-europa.instructions.md` was read in this chat and used to keep the implementation minimal and modular.