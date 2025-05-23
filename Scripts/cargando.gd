extends Control

func _ready():
	$VideoPlayer.play()


	get_tree().change_scene_to_file("res://Scenes/mapa.tscn")
