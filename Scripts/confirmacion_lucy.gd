extends Control





func _on_no_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/personaje.tscn")


func _on_yes_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/LucyBosque/LucySaleCasa.tscn")
