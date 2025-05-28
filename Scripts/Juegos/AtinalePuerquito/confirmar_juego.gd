extends Control


func _ready() -> void:
	MusicManager.play_music("res://audio/mapa.ogg")

func _on_jugar_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Juegos/Atinale_al_Puerquito/Explicacion_Juego.tscn")


func _on_salir_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/mapa.tscn")
