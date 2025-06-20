extends Control

func _ready() -> void:
	Input.set_custom_mouse_cursor(null)
	MusicManager.play_music("res://audio/menu.ogg")


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/personaje.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_creditos_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Creditos/creditos.tscn")
	
