extends Control

func _on_button_pressed() -> void:
	call_deferred("_change_scene")

func _change_scene():
		get_tree().change_scene_to_file("res://Scenes/efecto1.tscn")

@onready var boton_siguiente = $Button

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_RIGHT:
		boton_siguiente.emit_signal("pressed")
