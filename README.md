# Celebes Abyssal Tides

> **Note:** `Filler.txt` files are only fillers inside empty folders so that Git will track and push them to GitHub. *Ma delete tu.*

---

## Controls

| Key          | Action         |
|:------------ |:-------------- |
| **WASD**     | Move Character |
| **SpaceBar** | Dash           |
| **E**        | Primary        |
| **R**        | Ult            |

---

## Development Progress

### 1: Top-Down Player Movement + Universal Dash

* **Scene:** `Player.tscn` (`CharacterBody2D` named `Player`)
  * `Sprite2D`
  * `CollisionShape2D`
  * `Camera2D`
* **Script:** `player.gd` attached to `Player.tscn`

---

### 2: Health, Damage, and Knockout

* **Scene:** Added `HealthComponent` to `Player.tscn`
* **Script:** `health_component.gd` attached to `HealthComponent`

---

### 3: Arena and CoralBarriers

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

### 4 (Incomplete): Ability System

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

### 5: Kelp Zones

* **Scene:** `Kelptest.tscn` -> root `Node2D`
  * `Sprite2D`
  * `Area2D`
  * `kelp_zone.gd` attached -> calls functions if player has kelp functions
* **Scripts:**
  * `kelp_zone.gd`
  * `player.gd` -> added functions for kelp hiding and showing. Player will be briefly revealed when dashing or attacking.

### 6: PvP Lobby (Server-Authoritative) (Not yet complete)

The lobby is server-authoritative. Clients request changes; the host decides and synchronizes the resulting slot data across all connected peers.

* **Scene:** `scenes/ui/lobby/PvPLobby.tscn`
* **Slot Component:** `scenes/ui/lobby/PlayerSlot.tscn`
* transition scne

---

#### Slot Mapping Rules

* **Slots 0–2:** Sea Nomads (Team 0)
* **Slots 3–5:** Garbage Monsters (Team 1)
* **Slots 6–7:** Spectators (Team 2)

---

#### A. Host IP & Player Name Setup

* **Host IP Display (`HostIpLabel`):**
  * **Host:** Fetches the host device's local IP address (`IP.get_local_addresses()`) and displays it on the label (`IP: 192.168.x.x`).
  * **Client:** Displays "CONNECTED TO HOST" or the specific server IP upon joining.
* **Dynamic Player Names (`PlayerNameLabel`):** Each slot's `PlayerNameLabel` receives and displays the joining player's custom name (falling back to `"Player " + str(peer_id)` if unassigned).
* **Static Banners:** `SeaNomadLabel`, `MonstersLabel`, and `SpectatorsLabel` remain purely decorative visual elements and are never modified by network code.

---

#### B. Role-Based UI & Button Controls

* **Host (Server):**
  * Displays **Start Game** and **Back**.
  * Never displays **Ready** or **Unready** (regardless of whether occupying a player slot or spectator slot).
* **Clients (Peers):**
  * Display **Ready / Unready** and **Back**.
  * Never display **Start Game**.

---

#### C. Slot Join, Sync & Movement Logic

* **Auto-Assignment on Connect:** When a new player joins, the server finds the first empty slot index (`0` through `7`) and assigns the player automatically.
* **Full Network Sync for New Peers:** When a client connects, the host sends an RPC (`sync_all_slots`) containing the entire current map of occupied slots and player names so late joiners see the exact lobby state immediately.
* **Player Movement (Host & Clients):**
  * Any player can click an empty slot.
  * The client sends `request_slot_change(target_slot, peer_id, player_name)` to the server.
  * The server checks if the slot is free, clears the player's old slot, and assigns them to the new target slot across all connected peers.
  * Strictly 1 slot per player is enforced at all times.

---

#### D. Disconnect & Cleanup Rules

* **Host Clicks Back / Closes Lobby:** Triggers an RPC (`host_closed_lobby`) that gracefully disconnects all peers and returns everyone to `MainMenu.tscn`.
* **Client Clicks Back / Drops Connection:**
  * Only that client leaves to `MainMenu.tscn`.
  * The host detects `peer_disconnected(peer_id)` and immediately clears that player's slot, reopening it for others.
