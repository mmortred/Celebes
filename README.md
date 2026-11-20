# Celebes: Abyssal Tides

A 3v3 top down arena game about the pollution in the Celebes Sea, played over LAN. Made by Lit Studios in Godot 4.7.1.

The Garbage Monsters stole the Abyssal Pearls that keep the sea cool, and now the Celebes Serpent is waking up. The Sea Nomads have to get the pearls back.

## Controls

- **WASD** - move
- **Left click**, right click or **Q** - attack toward the mouse (melee swings the closest of the 4 ways, ranged shoots exactly at it)
- **Mouse** - aims attacks and abilities, Plastic Shot, Scatter Debris and Contaminate go exactly where it is
- **Space** - dash (10 second cooldown)
- **E** and **R** - ability 1 and ability 2, the icons at the bottom show the cooldown, hover them to see the stats
- Only one ability at a time, pressing E and R together only does the first one
- **Tab** - scoreboard
- **V** - hide the HUD when spectating
- **F11** - fullscreen or window (the game starts fullscreen and fits any screen size)

## How to play

### The pearl

Grab the pearl from the clam in the middle and bring it to your team's well.

- Stand in your well for 2.5 seconds to score, a yellow bar fills up over the well
- If you get hit while channeling, the bar starts over
- Carrying the pearl makes you 20% slower
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
- **Bajau Tide-Weaver** (ranged support, 100 HP, speed 160, shoots a water bolt every 1.5 seconds for about 10)
- **Tide Shift (E)** - her and allies close by get 40% faster for 2 seconds (8s cooldown)
- **Heal (R)** - her and allies close by heal 16 HP over 2 seconds, a green glow stays around her (13s cooldown)
- **Minahasan Shield-Bearer** (tank, 120 HP, speed 150, one attack every 1.25 seconds)
- **Shield Bash (E)** - hits enemies in front for 15, pushes them back and stuns them for 0.5 seconds (10s cooldown)
- **Retaliate (R)** - for 3 seconds half the damage he takes goes back to the attacker (10s cooldown)

**Garbage Monsters**

- **Plastic Hoard** (ranged striker, 90 HP, speed 150, shoots a bottle cap every 1.4 seconds)
- **Plastic Shot (E)** - big bottle shot at the mouse, 25 damage to the first enemy it hits, 600 range (10s cooldown)
- **Scatter Debris (R)** - junk rains down in a straight line toward the mouse, 360 long, piles land one after another, 10 damage and 30% slower for 2 seconds (8s cooldown)
- **Rusty Leviathan** (tank, 120 HP, speed 135, one attack every 1.43 seconds)
- **Crushing Slam (E)** - anchor smash in front, 35 damage, pushes back and stuns for 0.5 seconds, 78 range (8s cooldown)
- **Corroded Armor (R)** - takes 50% less damage for 4 seconds and sends half of it back (12s cooldown)
- **Toxic Sludge** (melee support, 100 HP, attacks every second)
- **Toxic Mist (E)** - poison cloud around him for 2 seconds, 8 damage per second within 90 (9s cooldown)
- **Contaminate (R)** - throws a big glob of poison goo where the mouse is (up to 150 away), it splats into one big puddle for 3 seconds, enemies in it take 6 damage per second and their damage goes down 30% (9s cooldown)

Every number is a const at the top of the ability script (like **DAMAGE** and **COOLDOWN** in **spear_thrust.gd**). HP, attack speed and move speed are in each character's scene.

### Other stuff

- Hiding in kelp makes you invisible to enemies, attacking or dashing shows you for a bit
- Kelp heals 8 HP every second when you are out of combat
- Hitting someone or getting hit puts you IN COMBAT for 4 seconds (shows under your HP)
- Shots stop at walls, players walk through each other
- STUNNED shows over a player for as long as the stun lasts
- The right side of the screen, under the map, shows which team has the pearl and the last 2 kills
- All 6 characters are playable
- SLOW and WEAK pop up over a player when they get hit by one
- After the match click BACK TO LOBBY

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
- **player.gd** - **stun**, **apply_slow** and **apply_weaken** rpcs, corroded armor damage reduction, **attack_speed** (seconds between basic attacks, it shows in every player scene), and **projectile_path** for ranged basic attacks
- **projectile.gd** and **WaterBolt.tscn**, **PlasticPellet.tscn**, **PlasticShotBolt.tscn** - shots every pc sees, only the shooters own pc deals the damage
- **scenes/player/fx** - SlamCrack, CorrodedAura, ToxicMistCloud, ContaminateMark, ScatterDebrisFx, HealAura and HealGround
- **PlasticHoard.tscn**, **RustyLeviathan.tscn** and **ToxicSludge.tscn** - scale 1.3, a bit bigger than the Sea Nomads
- **AbilitySlot.tscn** and **ability_slot.gd** - the E and R icons on the HUD with the cooldown
- **ArenaHUD.tscn** - the kill feed moved to the right side
- **CharacterSelect.tscn** and **CharacterCard.tscn** - the whole screen is made of nodes now, **character_select.gd** only changes the text and borders
- clicking your own character again does nothing
- **NetworkManager.gd** - sends players away with a message when the lobby is full or the match started, and moves everyone to the new host
- **PlayerSlot.tscn** and **pvp_lobby.gd** - KICK and HOST buttons for the host

### 21: Bug Fixes, Mouse Aim and Kelp Regen

- **menu_buttons.gd** - the QUIT button closes the game now (nothing was connected to it)
- **ability_base.gd** - **spawn_fx** takes the life before the effect is added, the toxic mist cloud stayed forever before
- **ability_base.gd** - **request_use** sends the aim direction so every pc uses the same one, **aim_with_mouse** for the aimed abilities, **get_info** for the hover box
- **player.gd** - attacks and abilities turn you to the mouse and keep that direction for the whole swing, so the shot never comes out the back while kiting
- **player.gd** - **try_cast** stops 2 abilities at the same time, **combat_timer** (4 seconds), kelp regen (**kelp_regen**), STUNNED label and the pearl carrier is 20% slower
- **player.gd** - players dont collide with each other anymore, bumping into someone made you fly off
- **projectile.gd** - shots hit when their path touches the HurtBox (same box as melee) and stop at walls (checked at the feet, every pc)
- **contaminate.gd** - a big glob falls where the mouse is and turns into one big puddle (**ContaminateDrop.tscn** and **ContaminateBigPool.tscn**)
- **scatter_debris.gd** - the junk lands in a straight line toward the mouse, one pile after another
- **AbilitySlot.tscn** - hover box with the ability stats
- **ArenaHUD.tscn** - IN COMBAT label, and a BACK TO LOBBY button after the match instead of any key
- **WallTileSet.tres** - the round pillars sort at their base, you looked like you were standing on top of them before

### 19: Music and Sound Effects

- **LobbyAudio.gd** - the kulintang starts at the intro and never restarts, it fades to ARENA_VOLUME (low, like a floater) in the arena and back up in the menus
- **settings_panel.gd** - music and SFX sliders, press Esc in the arena to open them
- **SFXManager.gd** - the sfx2 sounds are in: hit, player_death, heavy_attack, ability_ready, low_health_warning, pearl_drop, pearl_spawn, serpent_growl
- **player.gd** - low_health_percent is when the low health warning plays (only for you)
- **ability_base.gd** - the ready ping plays for abilities with 3+ seconds cooldown, ultimates play heavy_attack
- **serpent_awakening.gd** - the sea dragon growl plays with the cutscene

### 20: Lobby Text and Attack Speed

- **PvPLobby.tscn** - **StartStatusLabel** is a node now (the waiting text under START), move it in the 2D view
- **pvp_lobby.gd** - only changes the text, the host shows the label
- **player.gd** - **attack_cooldown** is renamed **attack_speed**, every player scene has it

### 21: FX Folders

- **scenes/player/fx** - every effect is in its team and character folder, like **fx/SeaNomad/Bajau/HealPulse.tscn** and **fx/Monsters/ToxicSludge/ToxicMistCloud.tscn**
- put new effects in the folder of the character that uses them

### 22: Every Ability Has an FX Scene

- **fx/SeaNomad/Bugis** - **SpearThrustTrail** and **RiptideWave**
- **fx/SeaNomad/Minahasan** - **ShieldBashImpact** (next to **RetaliateAura**)
- **fx/SeaNomad/Bajau** - **TideShiftRing** (next to the heal scenes)
- **spear_thrust.gd**, **riptide_sweep.gd**, **shield_bash.gd** and **tide_shift.gd** spawn them on every pc
- the new art is a placeholder you can redraw, the pngs are in assets/sprite/SeaNomad1, Minahasan and Bajau
- all player stats (move_speed, attack_damage, attack_speed, attack_offset, swing_hit_frames, max_health) are listed in every character scene

### 23: Main Menu Facts

- **MainMenu.tscn** - **FactLabel** and its child **SourceLabel** are nodes, move or restyle them in the 2D view
- **menu_facts.gd** - the 5 facts and 8 awareness lines from docs/Main_Menu_Facts_and_Awareness.txt, shown at random and mixed, every line shows once before any repeats
- **change_time** and **fade_time** are exported on **FactLabel** (8 seconds and 0.6 seconds)
- only facts show their source under the line

### 24: Skill Details, Projectile Spots and Balance

- **CharacterSelect.tscn** - hover or pick a card and **DetailsPanel**, **DetailName**, **DetailStats**, **Skill1Icon/Text** and **Skill2Icon/Text** show that character, all nodes you can move
- the text is read from the character scene (**get_basic_stats** in player.gd) and from each ability's **get_info**, so changing a number in a script or scene changes the text, nothing to edit by hand
- **tide_shift.gd** has **SPEED_BONUS**, **retaliate.gd** and **corroded_armor.gd** have **REFLECT_PERCENT** (they were hidden numbers in player.gd before)
- **projectile_forward** and **projectile_y** are in every ranged player scene, they move where the shot appears (x and y)
- **fit_fx** in ability_base.gd makes the effect as big as the area it hurts, used by riptide sweep, heal, tide shift, toxic mist and scatter debris
- **spear_thrust.gd** has **TRAIL_Y** so the water streak lines up with the spear
- balance (speed / seconds per attack): Bugis 170 / 1.0, Bajau 160 / 1.5, Minahasan 150 / 1.25, Plastic Hoard 150 / 1.4, Rusty Leviathan 135 / 1.43, Toxic Sludge 160 / 1.0
- **settings_panel.gd** has a **QUIT GAME** button (Esc in the arena), and the main menu QUIT closes the game

### 25: Cleanup and Bug Fixes

- removed **CoralBarrier.tscn** and **coral_barrier.gd**, nothing called its take_damage and the two in the arena were invisible walls players bumped into
- removed dead files: cutscene.tscn, GarbageMonster3.tscn, the GMonster3 sprites, Spear_guy_idle, contaminate_glob, GarbageMonster1, tf_atlantis.zip, the filler.txt files and the editor backups (.png~)
- **the console prints** for walking, dashing, kelp and every hit are gone, they were slowing the game down
- fix: attacking twice in the kelp used to put you back in hiding too early, **reveal_time** on the player is the new timer
- fix: dead players kept playing the hurt sound
- fix: a match with both players on the same team ended the moment the arena opened. **begin_match** does not check the winner anymore and the lobby says **Both teams need a player** until each side has one
