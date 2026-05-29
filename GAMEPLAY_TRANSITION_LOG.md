# Multiplayer Level Handshake Architecture

The cinematic terminal scene acts as the host-controlled handshake boundary. When the host reaches the end of the `Descenso` sequence, it generates a single procedural world seed and stores it in Steam lobby metadata under `world_seed`. That value becomes the durable source of truth for every peer in the session.

The flow is intentionally one-way. The host writes the seed into the lobby, then transitions into `MainGameplay.tscn` locally through `SceneManager`. Clients do not generate their own seed. Instead, they observe the lobby metadata update and switch to the gameplay scene once the shared seed is available. This keeps procedural generation deterministic across the entire lobby because every peer reads the same seed value before gameplay initialization begins.

Late joiners follow the same rule. If they connect after the host has already published `world_seed`, the Steam lobby metadata query resolves the cached seed immediately and the client can load the gameplay scene without replaying the cinematic. That avoids divergent world state and keeps the matchmaking handshake stable even when players join near the transition boundary.

# Crew Instantiation Scheme

Lobby role IDs remain the authoritative input for crew spawning. The lobby refactor already normalized the selectable roles into internal IDs, and those IDs are reused unchanged at gameplay load time: `electrical_engineer`, `mechanic_welder`, `security_officer`, and `medic_scientist`.

`GameplayManager` resolves each connected Steam peer, reads the member role from lobby metadata, and maps that role to a dedicated specialist scene path. The role scenes are thin wrappers over the shared character foundation, which keeps movement, interaction, and component wiring centralized while still allowing the gameplay layer to instantiate a specific crew archetype for each peer.

Each spawned character receives network authority for its owning Steam ID and is placed into the submarine capsule / Safe Zone spawn area using deterministic offsets. That gives every peer the same crew composition, the same ownership mapping, and the same starting arrangement at the moment gameplay begins.

# Post-Refactor Technical Checklist

1. Confirm the seed is identical on all clients by reading `world_seed` from the Steam lobby on host and client at gameplay startup.
2. Confirm each lobby member spawns with the correct role assigned in the lobby by comparing the Steam member role metadata against the instantiated scene path.
3. Confirm the cinematic terminal unloads completely by checking that the `Descenso` scene is replaced by `MainGameplay.tscn` and that no terminal UI nodes remain in the live scene tree after the transition.
4. Confirm late join behavior by connecting a client after the host has already published `world_seed` and verifying that the client loads directly into gameplay with the same seed.
5. Confirm network authority by inspecting each spawned crew member and validating that the authoritative Steam ID matches the lobby member that selected the role.
6. Confirm deterministic spawn placement by restarting the session with the same lobby roster and verifying that the Safe Zone spawn positions are unchanged for the same member ordering.