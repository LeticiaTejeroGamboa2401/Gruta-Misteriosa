extends Control

func _ready() -> void:
	MusicManager.play_music("res://audio/mapa.ogg")

	if Global.selected_character_scene != null:
		var player_instance = Global.selected_character_scene.instantiate()
		player_instance.name = Global.selected_character_name
		add_child(player_instance)
		player_instance.scale = Vector2(0.4, 0.4)
		player_instance.speed = 150
		if get_scene_file_path() == Global.use_respawn_in_scene:
			player_instance.position = Global.respawn_position
		else:
			player_instance.position = Vector2(100, 250)  # posición por defecto
	else:
		print("No se ha seleccionado personaje.")

	# Actualizar el label de juegos ganados
	actualizar_label_juegos_ganados()
	
	var plataforma = OS.get_name() 
	if plataforma == "Android" or plataforma == "iOS":
		$TouchControls.visible = true
	else:
		$TouchControls.visible = false
	
# <---- IZQUIERDA ----->
func _on_left_button_down() -> void:
	Input.action_press("ui_left")
func _on_left_button_up() -> void:
	Input.action_release("ui_left")

# <---- DERECHA ----->
func _on_right_button_down() -> void:
	Input.action_press("ui_right")
func _on_right_button_up() -> void:
	Input.action_release("ui_right")
	
# <---- ARRIBA ----->
func _on_up_button_down() -> void:
	Input.action_press("ui_up")
func _on_up_button_up() -> void:
	Input.action_release("ui_up")

# <---- ABAJO ----->
func _on_down_button_down() -> void:
	Input.action_press("ui_down")
func _on_down_button_up() -> void:
	Input.action_release("ui_down")

func actualizar_label_juegos_ganados():
	var ganados = 0
	for k in Global.juegos_ganados.keys():
		if Global.juegos_ganados[k]:
			ganados += 1
	$Conteno.text = "X %d" % ganados
	if ganados == 6:
		get_tree().change_scene_to_file("res://Scenes/Juegos/Talisman.tscn")


func _on_salir_pressed() -> void:
	get_tree().quit()
