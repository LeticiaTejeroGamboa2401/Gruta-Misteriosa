extends Control


func _on_siguiente_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/historia5.tscn")

@onready var boton_siguiente = $Siguiente

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_RIGHT:
		boton_siguiente.emit_signal("pressed")
