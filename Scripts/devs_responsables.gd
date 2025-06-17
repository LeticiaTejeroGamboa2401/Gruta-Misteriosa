extends Control

func _ready() -> void:
	MusicManager.play_music("res://audio/menu.ogg")
	
func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Creditos/creditos.tscn")

@onready var boton_atras = $Button

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_LEFT:
		boton_atras.emit_signal("pressed")
