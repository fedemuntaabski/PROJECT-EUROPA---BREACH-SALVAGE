# Game Shell Changes

tercer prompt

## Game shell foundation

- Refactored `scenes/levels/Game.tscn` into a minimal `Game` shell built on `Node2D`.
- Added a `World` placeholder node for future grid and map systems.
- Added a separate `UI` `CanvasLayer` for future HUD elements.
- Added a basic `Camera2D` to establish the scene's default camera setup.

## Scene flow

- Kept `scripts/levels/game.gd` focused on scene flow only.
- Preserved the Escape return path from the game scene back to the Main Menu for debugging.
- Kept the room-navigation prototype localized to the `World` node instead of adding a new manager layer.

## Minimal room navigation prototype

- Added a tiny `Room` placeholder concept as independent `Node2D` nodes with simple room IDs.
- Added a `World` script that owns a hardcoded room graph and handles instant room-to-room transitions.
- Added a minimal player controller that uses the existing direction inputs to request room changes.
- Added log output for each successful transition so the current room is easy to verify during playtests.

## Intentional scope limits

- No grid system was added.
- No flooding system was added.
- No enemies were added.
- No procedural generation was added.
- No complex UI was added.
