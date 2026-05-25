---
description: Describe when these instructions should be loaded by the agent based on task context
# Project Europa - Copilot Instructions

# Copilot Instructions

## General Goal
This project is a game development project focused on building a modular, system-driven gameplay experience.

All generated code should prioritize clarity, maintainability, and iterative development.

## Core Development Principles

### 1. Think in systems, not features
Break functionality into independent systems that can evolve separately.

Avoid hard-coupling logic between unrelated parts of the game.

### 2. Keep implementations minimal first
Always prefer the simplest working version of a system before adding complexity or abstraction.

Do not design for future features that are not implemented yet.

### 3. Favor modularity and independence
Code should be structured so that systems can be modified or replaced without affecting the rest of the project.

### 4. Use event-driven communication when appropriate
Prefer signals or events over direct references between systems when possible.

### 5. Prioritize gameplay clarity
Gameplay functionality is more important than architectural perfection.

Working prototypes are preferred over fully engineered systems.

### 6. Avoid unnecessary complexity
Do not introduce additional layers, managers, or abstractions unless they solve a real and present problem.

## Development mindset
Assume the project is in active evolution. Any system may change later, so code should remain flexible and easy to refactor.