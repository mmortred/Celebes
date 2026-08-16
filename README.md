Celebes Abbysal Tides

Filler.txt files are only fillers inside empty folders so that Git will track and push them to GitHub. Ma delete tu

Controls:
"WASD" : Move Character
"SpaceBar" : Dash


Development Progress:
STAGE 1: Top-Down Player Movement + Universal Dash
	Scene: *Player.tscn (CharacterBody2D) named Player, 
		 -Sprite2D 
		 -CollisionShape2D
		 -Camera2D
	Script: '*player.gd' attached to Player.tscn


STAGE 2: Health, Damage, and Knockout 
	Scene: Added HealthComponent to *Player.tscn
	Script: '*health_component.gd' attached to HealthComponent

Stage 3: Arena and CoralBarriers
	Scenes: Arena.tscn -> root node2D (Arena)
		-TileMap
		-CoralBarriers (holds instanced CoralBarrier.tscn nodes)
		-ClamSpawner (Area2D with CircleShape2D)
		-DropZone1 & DropZone2 (Marker2D team scoring zones)
		-TeamLeftSpawns & TeamRightSpawns (holds Marker2D spawn points)

		*CoralBarrier.tscn (CoralBarrier)
		  -Spride2D
		  -CollisionShaped2D

	Scripts: *arena.gd attached to *Arena.tscn (randomized team spawner logic)
		 *coral_barrier.gd attached to *CoralBarrier.tscn (barrier HP & destruction)

Stage 4 (incomplete): Ability System 
	Scene: ability.tscn -> root Node
		-empty
	Scripts: ability.gd -> base class for abilities
			bubblestrike.gd; spearthrust.gd -> sample abilities inheriting from abilitiesbase; for now just prints
	*added Primary and Ultimate attack nodes to player.gd. These will hold the ability scripts.
	*added also E and R for Primary and Ult respectively

	add other abilities for character kits

Stage 5: Kelp Zones
	Scene: Kelptest.tscn -> root Node2D
		-Sprite2D
		-Area2D
		-kelp_area.gd attached -> calls functions if player has kelp functions
	Script: kelp_area.gd
			player.gd -> added functions for kelp hiding and showing. player will be briefly revealed when dashing or attacking
