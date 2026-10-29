# SlopDash

A [Boulder Dash](https://en.wikipedia.org/wiki/Boulder_Dash)-style cave-digging game built with **Godot 4.2+**.

## How to play

Dig through dirt, collect the required number of gems to open the exit, and reach it before getting crushed.

| Action | Keys |
| --- | --- |
| Move | Arrow keys / WASD |
| Push boulder | Walk into it (horizontal only) |
| Restart level | R |
| Back to menu | Esc |

## Mechanics

- **Boulders and gems** fall when unsupported and roll off rounded piles — never stand under a falling rock.
- **Fireflies** (orange) patrol the caves; touching one is fatal, and a falling rock makes them explode.
- **Butterflies** (purple) also patrol; when crushed by a rock they burst into a 3x3 spread of gems — a classic scoring trick.
- **Exit** opens once you've collected enough gems (see the HUD).
- **Score**: 25 per gem, 5 per pushed boulder, 250 per completed level. High scores are saved to `user://slopdash_save.json`.

## Running

Open the project in Godot 4.2 or newer and press F5, or run headless:

```bash
godot --path . --import   # once, to generate .godot/
godot --path .
```

## Project layout

- `project.godot` – project config, input map, GameManager autoload
- `scenes/` – main menu, game, and victory scenes
- `scripts/game.gd` – core grid engine: gravity, enemies, hazards, rendering
- `scripts/level_data.gd` – the caves as ASCII maps (add your own!)
- `scripts/texture_factory.gd` – all art is generated procedurally at runtime (no binary assets)
