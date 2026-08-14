Celebes Abbysal Tides

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
		 