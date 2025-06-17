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


@onready var boton_atras = $Regreso

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_LEFT:
		boton_atras.emit_signal("pressed")
