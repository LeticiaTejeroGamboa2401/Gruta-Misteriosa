extends Control

func _ready():
	MusicManager.play_music("res://audio/win.ogg")
	
	await get_tree().create_timer(4).timeout
	get_tree().change_scene_to_file("res://Scenes/mapa.tscn")
