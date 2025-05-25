extends Control


func _on_lucy_pressed() -> void:
	Global.selected_character_scene = preload("res://Scenes/Lucy_Player.tscn")
	Global.selected_character_name = "Lucy_Player"
	get_tree().change_scene_to_file("res://Scenes/confirmacionLucy.tscn")


func _on_lele_pressed() -> void:
	Global.selected_character_scene = preload("res://Scenes/Lele_Player.tscn")
	Global.selected_character_name = "Lele_Player"
	get_tree().change_scene_to_file("res://Scenes/confirmacionLele.tscn")
