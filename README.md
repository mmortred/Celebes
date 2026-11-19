# Celebes: Abyssal Tides

A 3v3 top down arena game about the pollution in the Celebes Sea, played over LAN. Made by Lit Studios in Godot 4.7.1.

The Garbage Monsters stole the Abyssal Pearls that keep the sea cool, and now the Celebes Serpent is waking up. The Sea Nomads have to get the pearls back.

## Controls

- **WASD** - move
- **Left click**, right click or **Q** - attack
- **Space** - dash (10 second cooldown)
- **E** and **R** - ability 1 and ability 2, the icons at the bottom show the cooldown
- **Tab** - scoreboard
- **V** - hide the HUD when spectating

## How to play

### The pearl

Grab the pearl from the clam in the middle and bring it to your team's well.

- Stand in your well for 2.5 seconds to score, a yellow bar fills up over the well
- If you get hit while channeling, the bar starts over
- Carrying the pearl makes you 15% slower
- If you die with the pearl, you drop it where you died
- First team to 12 pearls wins (PEARLS_TO_WIN in GameManager.gd)

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

### Characters

Tanks have 120 HP, the ranged striker has 90 and everyone else has 100.

**Sea Nomads**

- **Bugis Spear-Fisher** (melee assassin, 100 HP)
- **Spear Thrust (E)** - long stab at the closest enemy in front, 25 damage, 90 range (7s cooldown)
- **Riptide Sweep (R)** - wave all around him, 25 damage to everyone within 120 (10s cooldown)
- **Bajau Tide-Weaver** (ranged support, 100 HP, 10% slower, shoots a water bolt every 1.5 seconds for about 10)
- **Tide Shift (E)** - her and allies close by get 40% faster for 2 seconds (8s cooldown)
- **Heal (R)** - her and allies close by heal 16 HP over 2 seconds, a green glow stays around her (13s cooldown)
- **Minahasan Shield-Bearer** (tank, 120 HP, 0.8x attack speed)
- **Shield Bash (E)** - hits enemies in front for 15, pushes them back and stuns them for 0.5 seconds (10s cooldown)
- **Retaliate (R)** - for 3 seconds half the damage he takes goes back to the attacker (10s cooldown)

**Garbage Monsters**

- **Plastic Hoard** (ranged striker, 90 HP, shoots a bottle cap every 0.77 seconds)
- **Plastic Shot (E)** - big bottle shot, 25 damage to the first enemy it hits, 600 range (10s cooldown)
- **Scatter Debris (R)** - junk rains down in front of him up to 360 away, 10 damage and 30% slower for 2 seconds (8s cooldown)
- **Rusty Leviathan** (tank, 120 HP, 0.7x attack speed)
- **Crushing Slam (E)** - anchor smash in front, 35 damage, pushes back and stuns for 0.5 seconds, 78 range (8s cooldown)
- **Corroded Armor (R)** - takes 50% less damage for 4 seconds and sends half of it back (12s cooldown)
- **Toxic Sludge** (melee support, 100 HP, attacks every second)
- **Toxic Mist (E)** - poison cloud around him for 2 seconds, 8 damage per second within 90 (9s cooldown)
- **Contaminate (R)** - poison goo on the closest enemy in front within 78, their damage goes down 30% for 3 seconds (9s cooldown)

Every number is a const at the top of the ability script (like **DAMAGE** and **COOLDOWN** in **spear_thrust.gd**). HP, attack speed and move speed are in each character's scene.

### Other stuff

- Hiding in kelp makes you invisible to enemies, attacking or dashing shows you for a bit
- The right side of the screen, under the map, shows which team has the pearl and the last 2 kills
- All 6 characters are playable
- STUN, SLOW and WEAK pop up over a player when they get hit by one

## Playing with friends

- Everyone needs to be on the same WiFi
- One person clicks PVP then HOST
- The others click PVP then JOIN and pick the lobby from the list (or type the host's IP)
- If the lobby doesn't show up, allow the game in the Windows firewall
- The lobby has 8 spots (3 per team and 2 spectators), when it's full or the match started, new players get sent back with a message
- The host has KICK and HOST buttons on the other players' slots, HOST makes that player the new host and everyone joins them
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
- **Bugis.tscn**, **Bajau.tscn**, **Minahasan.tscn**, **PlasticHoard.tscn**, **RustyLeviathan.tscn** and **ToxicSludge.tscn** - the playable characters

### 9: Loading Screen

- **LoadingScreen.tscn** and **loading_screen.gd** - shows a sea fact while the arena loads, then waits for every player

### 10: Arena and HUD

- **MainArena.tscn** - the real map (32px tiles)
- **arena.gd** - spawns everyone on their team's side
- **ArenaHUD.tscn** and **scripts/ui/arena_hud.gd** - timer, scores, HP bar and character icon
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
- **player.gd** - carrier is 15% slower (carrier_slow), swinging is 10% slower (attack_slow_percent)
- **TunaRun.tscn** - 3 lane markers in Lanes you can drag in the 2D view
- **serpent_awakening.gd** and **arena.gd** - the 5:00 respawn puts you on the enemy side

### 18: Cleanup and Split Sprites

- **player.tscn** - 3 sprites now: **AnimatedSpriteWalk** (walk and idle), **AnimatedAttacks** (the 4 swings) and **AnimatedAbility** (primary and ultimate)
- **base_attacks.tres** - the swings of the base player, the other frames stay in **base.tres**
- **player.gd** - shows the swing sprite while swinging, **AnimatedAttacks** copies the position and scale of **AnimatedSpriteWalk**
- **ability_base.gd** - **effect_animation** picks what **AnimatedAbility** plays, nothing plays until you add frames to it
- **GameManager.gd** - **PEARLS_TO_WIN** is 12 now
- scripts moved to the scripts folder and scenes to the scenes folder

### 19: Bajau and Minahasan

The other 2 Sea Nomads are playable now, with walk, attack and both abilities in 4 directions.

- **assets/sprite/Bajau** - walk, staff attack, Tide Shift and Heal sheets, **heal_pulse.png**, and **water_bolt.png** for later
- **assets/sprite/Minahasan** - walk, sword attack, Shield Bash and Retaliate sheets, and **retaliate_aura.png**
- **tide_shift.gd**, **heal.gd**, **shield_bash.gd** and **retaliate.gd** - the abilities
- **HealPulse.tscn** and **RetaliateAura.tscn** with **ability_fx.gd** - the green heal ring and the retaliate glow, they delete themselves when done
- **player.gd** - **receive_heal** and **knock_back** rpcs, the tide shift speed, and retaliate sending half the damage back
- heal and shield bash are decided on the casters own pc and sent to everyone, same as the basic attack
- **player.gd** - plays the ability pose for the way you face (like **tide_shift_left**) instead of the body, attacking cancels it
- **Bajau.tscn** and **Minahasan.tscn** - same setup as **Bugis.tscn** (scale 1.2, same hitboxes)
- **CharacterSelectManager.gd** and **arena.gd** - Bajau and Minahasan can be picked and spawn in the arena

### 20: Garbage Monsters and All Abilities

All 6 characters have their art and both abilities now.

- **assets/sprite/PlasticHoard**, **RustyLeviathan** and **ToxicSludge** - walk, attack and both abilities in 4 directions, plus their effects
- **assets/sprite/Minahasan** - redrawn on the artist's version, the round shield stays
- **assets/sprite/SeaNomad1** - Bugis Spear Thrust, made from his own attack frames
- **assets/sprite/Bajau** - bigger water bolt, and a glow on the ground and rising pluses for the heal
- **assets/ui/abilities** - the 12 ability icons and the cooldown cover
- **faction_nomads/spear_thrust.gd** and **riptide_sweep.gd** - Bugis abilities
- **faction_monsters** - **plastic_shot.gd**, **scatter_debris.gd**, **crushing_slam.gd**, **corroded_armor.gd**, **toxic_mist.gd** and **contaminate.gd**
- **ability_base.gd** - **find_enemies**, **find_closest_enemy** and **spawn_fx** that every ability uses, and the icon for the HUD
- each ability sets its name and cooldown in **_ready**, so the const in the script is the only place to change it
- **player.gd** - **stun**, **apply_slow** and **apply_weaken** rpcs, corroded armor damage reduction, **attack_cooldown** for attack speed, and **projectile_path** for ranged basic attacks
- **projectile.gd** and **WaterBolt.tscn**, **PlasticPellet.tscn**, **PlasticShotBolt.tscn** - shots every pc sees, only the shooters own pc deals the damage
- **scenes/player/fx** - SlamCrack, CorrodedAura, ToxicMistCloud, ContaminateMark, ScatterDebrisFx, HealAura and HealGround
- **PlasticHoard.tscn**, **RustyLeviathan.tscn** and **ToxicSludge.tscn** - scale 1.3, a bit bigger than the Sea Nomads
- **AbilitySlot.tscn** and **ability_slot.gd** - the E and R icons on the HUD with the cooldown
- **ArenaHUD.tscn** - the kill feed moved to the right side
- **CharacterSelect.tscn** and **CharacterCard.tscn** - the whole screen is made of nodes now, **character_select.gd** only changes the text and borders
- clicking your own character again does nothing
- **NetworkManager.gd** - sends players away with a message when the lobby is full or the match started, and moves everyone to the new host
- **PlayerSlot.tscn** and **pvp_lobby.gd** - KICK and HOST buttons for the host
