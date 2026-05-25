# Game Shell Changes

segundo prompt

## Game shell foundation

- Refactored `scenes/levels/Game.tscn` into a minimal `Game` shell built on `Node2D`.
- Added a `World` placeholder node for future grid and map systems.
- Added a separate `UI` `CanvasLayer` for future HUD elements.
- Added a basic `Camera2D` to establish the scene's default camera setup.

## Scene flow

- Kept `scripts/levels/game.gd` focused on scene flow only.
- Preserved the Escape return path from the game scene back to the Main Menu for debugging.
- Did not add any gameplay systems, grid logic, room logic, enemy logic, or flood logic.
- Did not introduce a new manager layer.

## Intentional scope limits

- No gameplay behavior was implemented.
- No future systems were stubbed beyond the scene hierarchy placeholders.
- No extra abstractions were added beyond the minimum needed for the shell structure.
