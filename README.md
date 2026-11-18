# Celebes: Abyssal Tides

3v3 top down arena game about the pollution in the Celebes Sea, played over LAN. Made by Lit Studios in Godot 4.7.1.

The Garbage Monsters stole the Abyssal Pearls that keep the sea cool, and now the Celebes Serpent is waking up. The Sea Nomads have to get the pearls back.

## Controls

- WASD to move
- Left click, right click or Q to attack
- Space to dash (10 second cooldown)
- E for primary and R for ultimate (not done yet)
- Tab to see the scoreboard
- V to hide the HUD when spectating

## How to play

- Grab the pearl from the clam in the middle and bring it to your team's well
- First team to 15 pearls wins
- If you die while holding the pearl you drop it
- At 5:00 the serpent rises, the inner wells open, the outer wells lock and the border starts closing in
- After 2 more minutes the team with more pearls wins
- Hiding in kelp makes you invisible to enemies, attacking or dashing shows you for a bit
- Right now only Bugis and the Garbage Monsters are playable, Bajau and Minahasan are not done yet

## Playing with friends

- Everyone needs to be on the same WiFi
- One person clicks PVP then HOST
- The others click PVP then JOIN and pick the lobby from the list (or type the host's IP)
- If the lobby doesn't show up, allow the game in the Windows firewall
- To test on one PC, go to Debug > Customize Run Instances in Godot and run 2 instances, host on one and join 127.0.0.1 on the other

## Development Progress

### 1: Top-Down Player Movement + Universal Dash

- Scene: **Player.tscn** (CharacterBody2D named Player) with a Sprite2D, CollisionShape2D and Camera2D
- Script: **player.gd** attached to **Player.tscn**

### 2: Health, Damage, and Knockout

- Scene: added a HealthComponent to **Player.tscn**
- Script: **health_component.gd** attached to the HealthComponent

### 3: Arena and CoralBarriers

- Scene: **Arena.tscn** with the TileMap, CoralBarriers, ClamSpawner, DropZone1 and DropZone2 (team scoring zones), TeamLeftSpawns and TeamRightSpawns
- Scene: **CoralBarrier.tscn** with a Sprite2D and CollisionShape2D
- Script: **arena.gd** attached to **Arena.tscn** (randomized team spawner)
- Script: **coral_barrier.gd** attached to **CoralBarrier.tscn** (barrier HP and destruction)

### 4 (Incomplete): Ability System

- Scene: **ability.tscn** with an empty root Node
- Script: **ability.gd** is the base class for abilities
- Script: **bubblestrike.gd** and **spearthrust.gd** are sample abilities, for now they just print
- Added Primary and Ultimate nodes to **player.gd**, and E and R for Primary and Ult
- Multiplayer test: add 2 instances in Debug > Multiple Instances, run **lobby.tscn**, Host Game on one and Join Game on the other

### 5: Kelp Zones

- Scene: **Kelptest.tscn** with a Sprite2D and an Area2D
- Script: **kelp_zone.gd** calls the kelp functions if the player has them
- Script: **player.gd** got hiding and showing in kelp, the player is revealed for a bit when dashing or attacking

### 6: PvP Lobby (Server-Authoritative)

- Scene: **PvPLobby.tscn** and the slot component **PlayerSlot.tscn**
- Clients request changes, the host decides and syncs the slots to everyone
- Slots 0 to 2 are Sea Nomads, 3 to 5 are Garbage Monsters, 6 to 7 are Spectators
- The host shows its IP (IP: 192.168.x.x), clients show CONNECTED TO HOST
- Each slot shows the player's name, or "Player" plus their id if they don't have one
- The host sees Start Game and Back, clients see Ready / Unready and Back
- New players go in the first empty slot, the host sends sync_all_slots so late joiners see the whole lobby
- Click an empty slot to move there, one slot per player only
- If the host clicks Back everyone goes back to **MainMenu.tscn**, if a client leaves only they go back and the host clears their slot

### 7: Main Menu and Settings

- Scene: **MainMenu.tscn** and **SettingsPanel.tscn**
- Script: **menu_buttons.gd** for the PVP, HOST, JOIN, OPTIONS and QUIT buttons
- Script: **settings_panel.gd** with 3 tabs, controls (change keys), audio (music and sound volume) and profile (username)
- Script: **PlayerProfile.gd** saves the username, **LobbyAudio.gd** plays the menu music, **SFXManager.gd** plays the sound effects

### 8: Character Select

- Scene: **CharacterSelect.tscn**
- Script: **character_select.gd** for the screen, **CharacterSelectManager.gd** where the host checks the picks
- You can only pick from your own team and each character can only be picked once
- When everyone presses READY the match loads
- Characters: **Bugis.tscn** and **ToxicSludge.tscn**, Plastic Hoard and Rusty Leviathan use the Toxic Sludge art for now

### 9: Loading Screen

- Scene: **LoadingScreen.tscn** with **loading_screen.gd**
- Shows a sea fact and fish while the arena loads, then waits for every player

### 10: Arena and HUD

- Scene: **MainArena.tscn** (32px tiles, sand, water cliff, stairs, bridge and railings)
- Scene: **ArenaHUD.tscn**
- Script: **arena.gd** spawns everyone's character on their team's side
- Script: **arena_hud.gd** shows the timer, team scores, HP bar and character icon
- Script: **scoreboard_overlay.gd** is the Tab scoreboard, the kills, deaths and assists come from **ScoreboardManager.gd**

### 11: Combat

- Script: **player.gd** got the 4 direction basic attack swings
- A hit does 20 damage and slows you for a bit
- Dead players fade out and respawn after 3 seconds
- Added feet shadows
- Script: **launch_fx.gd** is the dash effect (squash, afterimages and bubbles)

### 12: Pearl, Clam and Wells

- Scene: **Pearl.tscn**, **clam_zone.tscn** and **PearlIndicator.tscn**
- Scene: **SeaNomadDrop.tscn** and **GarbageMonsterDrop.tscn** (the wells)
- Script: **pearl.gd** for picking up, dropping on death and capturing
- Script: **clam_zone.gd** opens and closes the clam
- Script: **well.gd** for scoring, **pearl_indicator.gd** shows the pearl on the screen edge
- Script: **GameManager.gd** keeps the score and the timer
- The carrier's own wall goes up so they have to go around
- First to 15 pearls wins and the winner screen shows up

### 13: Serpent Rising

- Scene: **SerpentAwakening.tscn** with **serpent_awakening.gd**
- At 5:00 the screen shakes, everyone stops, the serpent eye opens and everyone respawns on their side
- The inner wells open and **arena_border.gd** closes the red border in

### 14: LAN Lobby List and Spectators

- Script: **join_panel.gd** lists the open lobbies on the network (from **NetworkManager.gd**) so you don't have to type the IP
- Script: **spectator_camera.gd** lets spectators move around, V hides the HUD

### 15: Intro Cutscene

- Scene: **Intro.tscn** with **intro.gd**
- Calm sea, then the pollution wave, then going up to the surface for the title

- The art is PNGs in **assets/cutscene/intro**
