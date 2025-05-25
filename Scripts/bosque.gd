extends Control

var murcielago_escena = preload("res://Scenes/Murcielago_Volando.tscn")

func _ready():
	if Global.selected_character_scene != null:
		var player_instance = Global.selected_character_scene.instantiate()
		player_instance.name = Global.selected_character_name
		add_child(player_instance)
		player_instance.position = Vector2(15,520)
	else:
		print("No se ha seleccionado personaje.")

	var posiciones = [Vector2(1000, 100), Vector2(750, 200), Vector2(600, 100)]

	for pos in posiciones:
		var murcielago = murcielago_escena.instantiate()
		add_child(murcielago)
		murcielago.position = pos
		murcielago.visible = true
