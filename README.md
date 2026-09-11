# Celebes Abyssal Tides

> **Note:** `Filler.txt` files are only fillers inside empty folders so that Git will track and push them to GitHub. *Ma delete tu.*

---

## Controls

| Key | Action |
| :--- | :--- |
| **WASD** | Move Character |
| **SpaceBar** | Dash |
| **E** | Primary |
| **R** | Ult |

---

## Development Progress

### Stage 1: Top-Down Player Movement + Universal Dash
* **Scene:** `Player.tscn` (`CharacterBody2D` named `Player`)
  * `Sprite2D`
  * `CollisionShape2D`
  * `Camera2D`
* **Script:** `player.gd` attached to `Player.tscn`

---

### Stage 2: Health, Damage, and Knockout
* **Scene:** Added `HealthComponent` to `Player.tscn`
* **Script:** `health_component.gd` attached to `HealthComponent`

---

### Stage 3: Arena and CoralBarriers
* **Scenes:**
  * `Arena.tscn` -> root `Node2D` (`Arena`)
    * `TileMap`
    * `CoralBarriers` (holds instanced `CoralBarrier.tscn` nodes)
    * `ClamSpawner` (`Area2D` with `CircleShape2D`)
    * `DropZone1` & `DropZone2` (`Marker2D` team scoring zones)
    * `TeamLeftSpawns` & `TeamRightSpawns` (holds `Marker2D` spawn points)
  * `CoralBarrier.tscn` (`CoralBarrier`)
    * `Sprite2D`
    * `CollisionShape2D`
* **Scripts:**
  * `arena.gd` attached to `Arena.tscn` *(randomized team spawner logic)*
  * `coral_barrier.gd` attached to `CoralBarrier.tscn` *(barrier HP & destruction)*

---

### Stage 4 (Incomplete): Ability System
* **Scene:** `ability.tscn` -> root `Node`
  * empty
* **Scripts:**
  * `ability.gd` -> base class for abilities
  * `bubblestrike.gd`; `spearthrust.gd` -> sample abilities inheriting from `abilitiesbase`; for now just prints

*Added Primary and Ultimate attack nodes to `player.gd`. These will hold the ability scripts.*  
*Added also E and R for Primary and Ult, respectively.*

#### Multiplayer System (Incomplete)
**To use:**
1. Go to **Debug** -> **Multiple Instances** -> Add 2 instances.
2. Run `lobby.tscn`.
3. On one instance, click **Host Game**.
4. On the other instance, enter nothing in the IP field and press **Join Game**.

> `// add other abilities for character kits`

---

### Stage 5: Kelp Zones
* **Scene:** `Kelptest.tscn` -> root `Node2D`
  * `Sprite2D`
  * `Area2D`
  * `kelp_area.gd` attached -> calls functions if player has kelp functions
* **Scripts:**
  * `kelp_area.gd`
  * `player.gd` -> added functions for kelp hiding and showing. Player will be briefly revealed when dashing or attacking.
