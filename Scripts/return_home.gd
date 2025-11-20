extends Node2D

# Referencias
var player
var dialog_box
var current_dialog_index = 0

# Audio
var dialog_open_sfx: AudioStreamPlayer
var dialog_typewriter_sfx: AudioStreamPlayer
var bgm_player: AudioStreamPlayer

# Sistema de diálogos - Historia del regreso a casa
var dialogs = [
	{"speaker": "MADRE", "text": "¡%s! ¡Gracias al cielo que estás bien! ¿Dónde has estado toda la tarde?"},
	{"speaker": "PLAYER", "text": "Mamá, papá... Me perdí en la selva y... ¡vi al Huaychivo!"},
	{"speaker": "PADRE", "text": "¿El Huaychivo? Hijo, esa criatura es muy peligrosa. ¿Cómo escapaste?"},
	{"speaker": "PLAYER", "text": "Un alux apareció y me ayudó. Me dijo que el Huaychivo persigue a los niños que se alejan solos."},
	{"speaker": "MADRE", "text": "Los aluxes son los guardianes de la selva. Tuviste mucha suerte de que uno te protegiera."},
	{"speaker": "PLAYER", "text": "El alux me enseñó que debo respetar la naturaleza y nunca adentrarme solo en lugares desconocidos."},
	{"speaker": "PADRE", "text": "Esa es una lección muy importante. La selva es sagrada y hay que conocerla antes de explorarla."},
	{"speaker": "MADRE", "text": "Prometiste que no te alejarías tanto. Estábamos muy preocupados por ti."},
	{"speaker": "PLAYER", "text": "Lo siento mucho. Prometo que la próxima vez les avisaré y no me alejaré solo."},
	{"speaker": "PADRE", "text": "Nos alegra que estés bien. Los aluxes cuidaron de ti, pero debes ser más responsable."},
	{"speaker": "MADRE", "text": "Ven, entremos a casa. Debes estar cansado después de tu aventura."},
	{"speaker": "PLAYER", "text": "Gracias por comprenderme. Ahora sé que la selva debe respetarse y que ustedes siempre se preocupan por mí."}
]

func _ready() -> void:
	# 1. Instanciar al personaje seleccionado
	var player_scene = Global.get("selected_character_scene")
	if not player_scene or not player_scene is PackedScene:
		print("Error: No se ha seleccionado un personaje válido en Global.")
		player_scene = load("res://Scenes/Lele_Player.tscn")

	player = player_scene.instantiate()
	add_child(player)

	# Desactivar el script del jugador para evitar que interfiera con la animación
	player.set_physics_process(false)
	player.set_process(false)

	# 2. Configurar la animación y posición inicial
	var start_position = Vector2(544, 656)
	var end_position = Vector2(544, 432)

	player.global_position = start_position

	# Configurar escala inicial (tamaño normal)
	var start_scale = Vector2(1.0, 1.0)
	var end_scale = Vector2(0.6, 0.6)
	player.scale = start_scale

	var anim_sprite = player.get_node_or_null("AnimatedSprite2D")
	if anim_sprite:
		anim_sprite.play("Arriba")

	# 3. Crear y configurar el Tween para el movimiento y escala
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_LINEAR)

	# Animar posición y escala en paralelo
	tween.tween_property(player, "global_position", end_position, 5.0)
	tween.parallel().tween_property(player, "scale", end_scale, 5.0)

	# 4. Cuando termine la caminata, iniciar los diálogos
	tween.finished.connect(_on_walk_finished)

	print("Tween iniciado - Esperando que el personaje llegue...")

	# Configurar audio
	_setup_audio()

func _setup_audio() -> void:
	print("🎵 Configurando audio en return_home...")
	# Sonido al abrir diálogo
	dialog_open_sfx = AudioStreamPlayer.new()
	dialog_open_sfx.stream = load("res://assets/sounds/kenney_interface-sounds/Audio/open_001.ogg")
	dialog_open_sfx.volume_db = 0
	dialog_open_sfx.bus = "Master"
	add_child(dialog_open_sfx)
	print("✅ Dialog open SFX configurado")

	# Sonido de typewriter (tick rápido)
	dialog_typewriter_sfx = AudioStreamPlayer.new()
	dialog_typewriter_sfx.stream = load("res://assets/sounds/kenney_interface-sounds/Audio/tick_002.ogg")
	dialog_typewriter_sfx.volume_db = -5 # Un poco más bajo para el tick repetitivo
	dialog_typewriter_sfx.bus = "Master"
	add_child(dialog_typewriter_sfx)
	print("✅ Dialog typewriter SFX configurado")

	# Música de victoria
	bgm_player = AudioStreamPlayer.new()
	bgm_player.stream = load("res://audio/triunfo.ogg")
	bgm_player.volume_db = -10
	bgm_player.bus = "Master"
	bgm_player.autoplay = true
	add_child(bgm_player)
	print("✅ BGM triunfo configurado y reproduciendo")

func _on_walk_finished() -> void:
	print("¡Personaje llegó al destino! Iniciando diálogos...")

	# Detener la animación de caminar
	var anim_sprite = player.get_node_or_null("AnimatedSprite2D")
	if anim_sprite:
		anim_sprite.stop()

	# Crear y configurar el cuadro de diálogo
	_setup_dialog_box()

	print("Dialog box creado, mostrando primer diálogo...")

	# Mostrar el primer diálogo
	_show_next_dialog()

func _setup_dialog_box() -> void:
	print("Configurando dialog box...")

	# Crear un CanvasLayer para asegurar que el UI esté sobre todo
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100
	add_child(canvas_layer)

	# Crear el contenedor del diálogo
	dialog_box = Control.new()
	dialog_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(dialog_box)

	# Fondo del diálogo con paleta arena/ocre/café (pergamino suave)
	var panel = ColorRect.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_top = -200
	# Arena/ocre claro con alta transparencia para conservar el fondo
	panel.color = Color(0.93, 0.85, 0.68, 0.9)
	dialog_box.add_child(panel)

	# Etiqueta del nombre del hablante
	var speaker_label = Label.new()
	speaker_label.name = "SpeakerLabel"
	speaker_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	speaker_label.offset_top = -190
	speaker_label.offset_left = 20
	speaker_label.add_theme_font_size_override("font_size", 28)
	# Nombre en azul legible sobre panel ocre
	speaker_label.add_theme_color_override("font_color", Color(0.18, 0.42, 0.82))
	dialog_box.add_child(speaker_label)

	# Etiqueta del texto del diálogo
	var text_label = Label.new()
	text_label.name = "TextLabel"
	text_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	text_label.offset_top = -150
	text_label.offset_left = 20
	text_label.offset_right = -20
	text_label.offset_bottom = -20
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.add_theme_font_size_override("font_size", 22)
	# Texto en café oscuro para alto contraste legible sobre ocre
	text_label.add_theme_color_override("font_color", Color(0.24, 0.16, 0.10))
	dialog_box.add_child(text_label)

	print("Dialog box configurado correctamente con CanvasLayer")

func _show_next_dialog() -> void:
	if current_dialog_index >= dialogs.size():
		# Todos los diálogos terminaron
		print("Todos los diálogos terminaron")
		_end_dialog()
		return

	print("Mostrando diálogo #", current_dialog_index)

	var dialog = dialogs[current_dialog_index]
	var speaker_label = dialog_box.get_node("SpeakerLabel")
	var text_label = dialog_box.get_node("TextLabel")

	# Reemplazar %s con el nombre del personaje
	var character_name = Global.get("selected_character_name")
	if character_name == null or character_name == "":
		character_name = "Hijo"

	var speaker_text = dialog.speaker
	if speaker_text == "PLAYER":
		speaker_text = character_name.to_upper()

	speaker_label.text = speaker_text

	var dialog_text = dialog.text
	if dialog_text.contains("%s"):
		dialog_text = dialog_text % character_name

	print("Hablante: ", speaker_text, " - Texto: ", dialog_text)

	# Reproducir sonido de diálogo abriendo
	print("🔊 Abriendo diálogo...")
	if dialog_open_sfx:
		dialog_open_sfx.play()

	# Efecto de escritura
	text_label.text = dialog_text
	text_label.visible_characters = 0

	var tween = create_tween()
	tween.tween_property(text_label, "visible_characters", dialog_text.length(), 2.0)

	# Reproducir tick cada pocos caracteres para simular typewriter
	_play_typewriter_effect(dialog_text.length(), 2.0)

	tween.finished.connect(_on_dialog_text_finished)

func _play_typewriter_effect(char_count: int, duration: float) -> void:
	# Reproducir ticks a intervalos durante la escritura
	var tick_interval = duration / float(char_count) * 3.0 # Cada 3 caracteres aprox
	var ticks_needed = int(float(char_count) / 3.0)

	for i in range(ticks_needed):
		await get_tree().create_timer(tick_interval).timeout
		if dialog_typewriter_sfx:
			dialog_typewriter_sfx.play()

func _on_dialog_text_finished() -> void:
	# Esperar 2 segundos antes del siguiente diálogo
	await get_tree().create_timer(2.5).timeout
	current_dialog_index += 1
	_show_next_dialog()

func _end_dialog() -> void:
	print("Finalizando diálogos, iniciando fade out...")

	# Esperar un poco antes del fade out
	await get_tree().create_timer(1.5).timeout

	# Crear un ColorRect negro para el fade out sobre toda la pantalla
	var fade_layer = CanvasLayer.new()
	fade_layer.layer = 200 # Por encima de todo
	add_child(fade_layer)

	var fade_rect = ColorRect.new()
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.color = Color(0, 0, 0, 0) # Negro transparente inicialmente
	fade_layer.add_child(fade_rect)

	# Fade out: de transparente a negro opaco
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, 2.0) # 2 segundos de fade
	tween.finished.connect(_go_to_credits)

func _go_to_credits() -> void:
	print("Cambiando a escena de créditos...")
	get_tree().change_scene_to_file("res://Scenes/Creditos/creditos.tscn")
