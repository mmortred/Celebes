extends Node2D

# red number that pops up when someone gets hit, the pop animation moves it and deletes it


func show_damage(amount):
	$Label.text = str(int(amount))
	$AnimationPlayer.play("pop")
