extends Control

func _ready() -> void:
	MusicManager.play_music("res://audio/menu.ogg")

func _on_regreso_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/menu.tscn")


func _on_dev_original_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Creditos/devOrig.tscn")


func _on_equipo_ss_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Creditos/devs-Responsables.tscn")


func _on_material_da_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Creditos/MaterialDA.tscn")


func _on_herramientas_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Creditos/HYT.tscn")
