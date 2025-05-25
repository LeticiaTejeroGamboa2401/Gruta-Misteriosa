extends Control

func _ready():
	$VideoPlayer.play()
	await get_tree().create_timer(9).timeout
	get_tree().change_scene_to_file("res://Scenes/mapa.tscn")
