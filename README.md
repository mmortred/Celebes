# Celebes: Abyssal Tides

A 3v3 top down arena game about the pollution in the Celebes Sea, played over LAN. Made by Lit Studios in Godot 4.7.1.

The Garbage Monsters stole the Abyssal Pearls that keep the sea cool, and now the Celebes Serpent is waking up. The Sea Nomads have to get the pearls back.

## Controls

- **WASD** - move
- **Left click**, right click or **Q** - attack
- **Space** - dash (10 second cooldown)
- **E** and **R** - ability 1 and ability 2 (not done yet)
- **Tab** - scoreboard
- **V** - hide the HUD when spectating

## How to play

### The pearl

Grab the pearl from the clam in the middle and bring it to your team's well.

- Stand in your well for 2.5 seconds to score, a yellow bar fills up over the well
- If you get hit while channeling, the bar starts over
- Carrying the pearl makes you 15% slower
- If you die with the pearl, you drop it where you died
- First team to 15 pearls wins

### Serpent Rising (5:00)

- The inner wells open, the outer wells lock and the border starts closing in
- Everyone respawns on the enemy's side once, so the pearl has to go through the other team
- After that you respawn on your own side again
- After 2 more minutes the team with more pearls wins

### Dying

- You respawn after 6 seconds, or 4 seconds during Serpent Rising
- The countdown shows in the middle of your screen

### Tuna

- At 3:30 and 1:30 a school of tuna swims across the top, middle or bottom lane
- First to touch it gets the Tuna Rush: 20% faster and half the dash cooldown for 15 seconds
- The tuna in the background show how healthy the sea is, Sea Nomads points bring more back and Garbage Monsters points scare them away

### Other stuff

- Hiding in kelp makes you invisible to enemies, attacking or dashing shows you for a bit
- The left side of the screen shows which team has the pearl and the last 2 kills
- Only Bugis and the Garbage Monsters are playable right now, Bajau and Minahasan are not done yet

## Playing with friends

- Everyone needs to be on the same WiFi
- One person clicks PVP then HOST
- The others click PVP then JOIN and pick the lobby from the list (or type the host's IP)
- If the lobby doesn't show up, allow the game in the Windows firewall
- To test on one PC, go to Debug > Customize Run Instances in Godot, run 2 instances, host on one and join 127.0.0.1 on the other

## Development Progress

### 1: Top-Down Player Movement + Universal Dash

The player moves in 4 directions and can dash.

- **Player.tscn** - CharacterBody2D with a Sprite2D, CollisionShape2D and Camera2D
- **player.gd** - movement and dash

### 2: Health, Damage, and Knockout

The player has HP and gets knocked out at 0.

- **Player.tscn** - added a HealthComponent
- **health_component.gd** - keeps the HP and tells the player when they're knocked out

### 3: Arena and CoralBarriers

The first arena with team spawns, scoring zones and barriers you can break.

- **Arena.tscn** - TileMap, CoralBarriers, ClamSpawner, DropZone1 and DropZone2, TeamLeftSpawns and TeamRightSpawns
- **CoralBarrier.tscn** - Sprite2D and CollisionShape2D
- **arena.gd** - spawns the teams on random spawn points
- **coral_barrier.gd** - barrier HP and breaking

### 4 (Incomplete): Ability System

The base for abilities, the sample ones only print for now. E and R use them.

- **ability.tscn** - empty root Node
- **ability.gd** - base class for every ability
- **bubblestrike.gd** and **spearthrust.gd** - sample abilities
- **player.gd** - added the Primary and Ultimate nodes

### 5: Kelp Zones

Players hide in kelp and get revealed for a bit when they dash or attack.

- **Kelptest.tscn** - Sprite2D and Area2D
- **kelp_zone.gd** - calls the kelp functions on the player
- **player.gd** - hiding and showing in kelp

### 6: PvP Lobby (Server-Authoritative)

Clients only ask for changes, the host decides and syncs the slots to everyone.

- **PvPLobby.tscn** - the lobby screen
- **PlayerSlot.tscn** - one slot in the lobby
- Slots 0 to 2 are Sea Nomads, 3 to 5 are Garbage Monsters, 6 to 7 are Spectators
- The host sees Start Game and Back, clients see Ready / Unready and Back
- New players go in the first empty slot, late joiners get the whole lobby from sync_all_slots
- If the host clicks Back everyone goes back to **MainMenu.tscn**, if a client leaves only they go back

### 7: Main Menu and Settings

- **MainMenu.tscn** and **menu_buttons.gd** - PVP, HOST, JOIN, OPTIONS and QUIT
- **SettingsPanel.tscn** and **settings_panel.gd** - controls, audio and profile tabs
- **PlayerProfile.gd** - saves the username
- **LobbyAudio.gd** - menu music
- **SFXManager.gd** - sound effects

### 8: Character Select

You can only pick from your own team and each character only once. When everyone is READY the match loads.

- **CharacterSelect.tscn** and **character_select.gd** - the screen
- **CharacterSelectManager.gd** - the host checks the picks
- **Bugis.tscn** and **ToxicSludge.tscn** - the playable characters

### 9: Loading Screen

- **LoadingScreen.tscn** and **loading_screen.gd** - shows a sea fact while the arena loads, then waits for every player

### 10: Arena and HUD

- **MainArena.tscn** - the real map (32px tiles)
- **arena.gd** - spawns everyone on their team's side
- **ArenaHUD.tscn** and **arena_hud.gd** - timer, scores, HP bar and character icon
- **scoreboard_overlay.gd** - the Tab scoreboard
- **ScoreboardManager.gd** - kills, deaths and assists

### 11: Combat

4 direction attack swings. A hit does about 15 damage (10 to 20) and slows you for a bit.

- **player.gd** - swings, random damage (**attack_damage** 15 and **damage_spread** 0.33), feet shadows, fade out when dead
- **launch_fx.gd** - dash effect (squash, afterimages and bubbles)

### 12: Pearl, Clam and Wells

- **Pearl.tscn** and **pearl.gd** - picking up, dropping on death and capturing
- **clam_zone.tscn** and **clam_zone.gd** - opens and closes the clam
- **PearlIndicator.tscn** and **pearl_indicator.gd** - shows the pearl on the screen edge
- **SeaNomadDrop.tscn**, **GarbageMonsterDrop.tscn** and **well.gd** - the wells
- **GameManager.gd** - score and timer
- The carrier's own wall goes up so they have to go around

### 13: Serpent Rising

At 5:00 the screen shakes, the serpent eye opens and everyone respawns.

- **SerpentAwakening.tscn** and **serpent_awakening.gd** - the cutscene
- **arena_border.gd** - the red border closing in

### 14: LAN Lobby List and Spectators

- **join_panel.gd** - lists the open lobbies so you don't have to type the IP
- **NetworkManager.gd** - finds the lobbies on the network
- **spectator_camera.gd** - spectators can move around, V hides the HUD

### 15: Intro Cutscene

Calm sea, then the pollution wave, then the Lit Studios logo, then up to the surface for the title.

- **Intro.tscn** - everything moves in the AnimationPlayers, so you can place the nodes in the 2D view
- **intro.gd** - only picks what plays next
- **assets/cutscene/intro** - the art PNGs

### 16: Damage Numbers, Respawn and Tuna

- **DamageNumber.tscn** and **damage_number.gd** - red number when someone gets hit, hidden in kelp
- **player.gd** - 10 second respawn (7 in Serpent Rising), counted with a timer so the cutscene can't respawn you twice
- **TunaRun.tscn** and **tuna_run.gd** - the Tuna Rush, the host decides when it comes and who caught it
- **SeaTuna.tscn** and **sea_tuna.gd** - the background tuna that follow the score
- **assets/sprite/tuna/tuna_swim.png** - tuna art

### 17: Kill Feed, Pearl Channel and Lanes

- **ArenaHUD.tscn** - kill feed on the left, pearl line on top and the last 2 kills under it
- **ScoreboardManager.gd** - the host sends every kill to everyone
- **scoreboard_overlay.gd** - the Tab scoreboard is see through now
- **Bugis.tscn** - scale 1.2 because its too small
- **well.gd** - stand in the well for 2.5 seconds to score, a hit starts it over
- **SeaNomadDrop.tscn** - the channel bar over the well
- **player.gd** - carrier is 15% slower (carrier_slow)
- **TunaRun.tscn** - 3 lane markers in Lanes you can drag in the 2D view
- **serpent_awakening.gd** and **arena.gd** - the 5:00 respawn puts you on the enemy side
