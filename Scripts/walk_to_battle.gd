extends Node2D

@onready var background: TextureRect = $Background

var footstep_sfx: AudioStreamPlayer
var footstep_timer: Timer
var bgm_player: AudioStreamPlayer

func _ready() -> void:
	# 1. Instanciar al personaje seleccionado
	var player_scene = Global.get("selected_character_scene")
	if not player_scene or not player_scene is PackedScene:
		print("Error: No se ha seleccionado un personaje válido en Global.")
		# Cargar uno por defecto para evitar crasheos
		player_scene = load("res://Scenes/Lele_Player.tscn")

	var player = player_scene.instantiate()
	add_child(player)

	# 2. Configurar la animación y posición inicial
	# Invertir: iniciar en el lado derecho y caminar hacia la izquierda
	var start_position = Vector2(get_viewport_rect().size.x + 100, 520) # Iniciar fuera de la pantalla a la derecha
	var end_position = Vector2(-100, 520) # Terminar fuera de la pantalla a la izquierda

	player.global_position = start_position

	var anim_sprite = player.get_node_or_null("AnimatedSprite2D")
	if anim_sprite:
		# Asegurar que el AnimatedSprite2D esté visible y activo
		anim_sprite.visible = true
		anim_sprite.process_mode = Node.PROCESS_MODE_INHERIT

		# Obtener las animaciones disponibles
		var animation_names = []
		if anim_sprite.sprite_frames:
			animation_names = anim_sprite.sprite_frames.get_animation_names()

		print("Animaciones disponibles: ", animation_names)

		# Crear un mapa case-insensitive para buscar animaciones
		var name_map = {}
		for anim_name in animation_names:
			name_map[anim_name.to_lower()] = anim_name

		# Buscar y reproducir la animación apropiada
		var selected_animation = ""
		if name_map.has("izquierda"):
			# Si existe animación "Izquierda", usarla directamente
			selected_animation = name_map["izquierda"]
			print("Usando animación: ", selected_animation)
		elif name_map.has("derecha"):
			# Si solo existe "Derecha", voltear el sprite y usarla
			selected_animation = name_map["derecha"]
			anim_sprite.flip_h = true
			print("Usando animación volteada: ", selected_animation)
		elif animation_names.size() > 0:
			# Fallback: usar la primera animación disponible
			selected_animation = animation_names[0]
			print("Usando animación por defecto: ", selected_animation)
		else:
			print("ADVERTENCIA: No hay animaciones disponibles en AnimatedSprite2D")

		# Reproducir la animación seleccionada
		if selected_animation != "":
			# CRÍTICO: Asegurar que la animación esté en modo loop
			if anim_sprite.sprite_frames:
				anim_sprite.sprite_frames.set_animation_loop(selected_animation, true)
				print("Loop activado para la animación: ", selected_animation)

			# Asegurar configuraciones correctas antes de reproducir
			anim_sprite.speed_scale = 1.0
			anim_sprite.frame = 0

			# Activar procesos antes de reproducir
			anim_sprite.set_process(true)
			anim_sprite.set_physics_process(true)

			# Desactivar lógica basada en entrada para que no detenga la animación
			if player.has_method("set_physics_process"):
				player.set_physics_process(false)
			if player.has_method("set_process"):
				player.set_process(false)
			if player.has_method("set_process_input"):
				player.set_process_input(false)
			if player.has_method("set_process_unhandled_input"):
				player.set_process_unhandled_input(false)
			if player.has_method("set_process_unhandled_key_input"):
				player.set_process_unhandled_key_input(false)

			# Si el personaje expone la propiedad `can_animate`, desactivarla
			for prop in player.get_property_list():
				if prop.name == "can_animate":
					player.set("can_animate", false)
					print("DEBUG: can_animate desactivado para la escena walk_to_battle")
					break

			# Reproducir la animación
			anim_sprite.play(selected_animation)

			# Verificar el estado después de reproducir
			await get_tree().process_frame
			var is_looping = anim_sprite.sprite_frames.get_animation_loop(selected_animation) if anim_sprite.sprite_frames else false
			print("Estado después de play(): animation='%s', frame=%d, speed_scale=%f, loop=%s" % [anim_sprite.animation, anim_sprite.frame, anim_sprite.speed_scale, str(is_looping)])

	# 3. Crear y configurar el Tween para el movimiento
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_LINEAR)

	# Animar la propiedad global_position del jugador hacia la izquierda
	tween.tween_property(player, "global_position", end_position, 5.0) # Duración de 5 segundos

	# 4. Conectar la señal de finalización del tween para cambiar de escena
	tween.finished.connect(_on_walk_finished)

	# 5. Configurar sonidos de pasos
	_setup_footsteps()

func _setup_footsteps() -> void:
	print("🎵 Configurando footsteps...")
	# Crear player de pasos
	footstep_sfx = AudioStreamPlayer.new()
	footstep_sfx.stream = load("res://assets/sounds/kenney_impact-sounds/Audio/footstep_grass_000.ogg")
	footstep_sfx.volume_db = -3
	footstep_sfx.bus = "Master"
	add_child(footstep_sfx)

	# Timer para reproducir pasos cada 0.5 segundos
	footstep_timer = Timer.new()
	footstep_timer.wait_time = 0.5
	footstep_timer.autostart = true
	footstep_timer.timeout.connect(_play_footstep)
	add_child(footstep_timer)
	print("✅ Footsteps configurados")

	# Música de tensión
	bgm_player = AudioStreamPlayer.new()
	bgm_player.stream = load("res://audio/suspenso.ogg")
	bgm_player.volume_db = -12
	bgm_player.bus = "Master"
	bgm_player.autoplay = true
	add_child(bgm_player)
	print("✅ BGM suspenso configurado y reproduciendo")

func _play_footstep() -> void:
	if footstep_sfx:
		# Variar entre los 5 sonidos de pasto disponibles
		var random_step = randi() % 5
		footstep_sfx.stream = load("res://assets/sounds/kenney_impact-sounds/Audio/footstep_grass_00" + str(random_step) + ".ogg")
		footstep_sfx.play()

func _on_walk_finished() -> void:
	# Detener pasos
	if footstep_timer:
		footstep_timer.stop()
	get_tree().change_scene_to_file("res://Scenes/Pelea_Final.tscn")
