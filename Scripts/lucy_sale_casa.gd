extends Control

func _ready() -> void:
	MusicManager.play_music("res://audio/historia.ogg")

func _on_siguiente_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Bosque.tscn")


func _on_omitir_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/mapa.tscn")

@onready var boton_siguiente = $Siguiente

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_RIGHT:
		boton_siguiente.emit_signal("pressed")
