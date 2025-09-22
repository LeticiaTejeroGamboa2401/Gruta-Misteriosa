extends Control


func _ready() -> void:
	if Global.selected_character_scene != null:
		var player_instance = Global.selected_character_scene.instantiate()
		player_instance.name = Global.selected_character_name
		add_child(player_instance)
		player_instance.position = Vector2(15,520)
	else:
		print("No se ha seleccionado personaje.")
	
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
