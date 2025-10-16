extends Node2D

func _ready() -> void:
	# 1. Instanciar al personaje seleccionado
	var player_scene = Global.get("selected_character_scene")
	if not player_scene or not player_scene is PackedScene:
		print("Error: No se ha seleccionado un personaje válido en Global.")
		# Cargar uno por defecto para evitar crasheos
		player_scene = load("res://Scenes/Lele_Player.tscn")

	var player = player_scene.instantiate()
	add_child(player)

	# Desactivar el script del jugador para evitar que interfiera con la animación
	player.set_physics_process(false)
	player.set_process(false)

	# 2. Configurar la animación y posición inicial
	var start_position = Vector2(544, 656) # Iniciar desde la parte de abajo del poblado
	var end_position = Vector2(544, 432) # Terminar cerca de los padres (arriba)

	player.global_position = start_position

	# Configurar escala inicial (tamaño normal)
	var start_scale = Vector2(1.0, 1.0)
	var end_scale = Vector2(0.6, 0.6) # Se reduce al 60% del tamaño original
	player.scale = start_scale

	var anim_sprite = player.get_node_or_null("AnimatedSprite2D")
	if anim_sprite:
		anim_sprite.play("Arriba") # Usar animación de caminar hacia arriba

	# 3. Crear y configurar el Tween para el movimiento y escala
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.set_parallel(true) # Permitir animaciones simultáneas

	# Animar la posición del jugador
	tween.tween_property(player, "global_position", end_position, 5.0)

	# Animar la escala del jugador (efecto de perspectiva)
	tween.tween_property(player, "scale", end_scale, 5.0)

	# 4. Conectar la señal de finalización del tween para cambiar de escena
	tween.finished.connect(_on_walk_finished)

func _on_walk_finished() -> void:
	get_tree().change_scene_to_file("res://Scenes/Creditos/creditos.tscn")
