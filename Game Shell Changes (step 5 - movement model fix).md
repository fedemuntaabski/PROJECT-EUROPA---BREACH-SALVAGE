# Game Shell Changes


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

## Debug Visualization Layer

- Added simple `Polygon2D` debug shapes to each room so the room layout is visible in world space.
- Kept the existing room spacing and positions so the relationships between rooms are easy to read.
- Added a visible player marker as a small `Polygon2D` attached to the player node.
- Added a current `Camera2D` and kept the active area framed instead of leaving it pointed at empty space.
- Added an active-room highlight in the `World` script by tinting the current room and dimming inactive rooms.
- Kept the transition log as fallback debug output for room changes.

## Movement Model Overhaul

- Replaced press-to-swap room logic with continuous top-down movement inside the current room.
- Kept the existing room graph and used room boundaries and exit directions to trigger room transitions only when the player reaches an edge.
- Preserved physical movement in world space so room changes happen at the boundary instead of as an instant input response.
- Added a minimal on-screen debug readout showing the current room ID and the player's local position inside that room.
- Updated the camera behavior so it follows the moving player smoothly instead of jumping independently between rooms.

## Intentional scope limits

- No grid system was added.
- No flooding system was added.
- No enemies were added.
- No procedural generation was added.
- No complex UI was added.