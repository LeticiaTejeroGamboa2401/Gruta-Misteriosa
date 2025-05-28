extends Control

func _ready() -> void:
	MusicManager.play_music("res://audio/menu.ogg")

func _on_return_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Creditos/creditos1.tscn")
