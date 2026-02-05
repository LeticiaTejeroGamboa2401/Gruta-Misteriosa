extends "res://Scripts/minigames/MiniGame.gd"

enum State {IDLE, SHOW, INPUT, RESULT}

@onready var title: Label = $Title
@onready var subtitle: Label = $SubTitle
@onready var progress: ProgressBar = $Progress
@onready var time_bar: ProgressBar = $Time
@onready var time_label: Label = $TimeLabel
@onready var grid: Control = $Grid

@onready var retry_btn: Button = $RetryBtn
@onready var tip_label: Label = $Tip
@onready var buttons: Array = [
	$Grid/Btn1,
	$Grid/Btn2,
	$Grid/Btn3,
	$Grid/Btn4
]

var sequence: Array[int] = []
var user_index: int = 0
var playing_back: bool = false
# Colores base (Blanco para respetar el arte original de los amuletos)
var base_colors := [
	Color(1, 1, 1),
	Color(1, 1, 1),
	Color(1, 1, 1),
	Color(1, 1, 1)
]

var element_textures: Array[Texture2D] = []

# State and timing
var state: State = State.IDLE
var difficulty: int = 1
var seq_length: int = 4
var show_delay: float = 0.5
var gap_delay: float = 0.25
var input_timeout_sec: float = 2.5
var input_timer: Timer
var time_left: float = 0.0
var best_progress: int = 0
var attempts_remaining: int = 1
var max_attempts: int = 1
var total_rounds: int = 3
var current_round: int = 1
var completed_rounds: int = 0

# SFX
var element_players: Array[AudioStreamPlayer] = [] # 4 players for elemental tones
var success_player: AudioStreamPlayer
var fail_player: AudioStreamPlayer

func start(config := {}):
	super.start(config)
	difficulty = int(config.get("difficulty", 1))
	_configure_difficulty(difficulty)
	_prepare_audio()
	_ensure_timer()
	max_attempts = int(config.get("attempts", 5))
	attempts_remaining = max_attempts
	best_progress = 0
	total_rounds = int(config.get("rounds", 3))
	current_round = 1
	completed_rounds = 0

	retry_btn.visible = false
	tip_label.visible = true
	_begin_round()

func _ready() -> void:
	# Cargar texturas de amuletos desde la carpeta assets/amuleto_elementos
	var texture_paths = [
		"res://assets/amuleto_elementos/amulet_fuego.jpg",
		"res://assets/amuleto_elementos/amulet_tierra.jpg",
		"res://assets/amuleto_elementos/amulet_agua.jpg",
		"res://assets/amuleto_elementos/amulet_aire.jpg"
	]

	element_textures.clear()
	for path in texture_paths:
		if FileAccess.file_exists(path):
			element_textures.append(load(path))
		else:
			element_textures.append(null)

	# Ajustar Grid para acomodar botones cuadrados (con separación reducida)
	if grid:
		grid.add_theme_constant_override("h_separation", 20)
		grid.add_theme_constant_override("v_separation", 20)
		# Usar anchors para centrado dinámico en lugar de posición fija
		# Grid size: 180*2 + 20 separation = 380px
		grid.anchor_left = 0.5
		grid.anchor_right = 0.5
		grid.anchor_top = 0.32
		grid.anchor_bottom = 0.32
		grid.offset_left = -190
		grid.offset_right = 190
		grid.offset_top = 0
		grid.offset_bottom = 0

	# Asegurar colores y conexiones
	for i in buttons.size():
		var b: Button = buttons[i]
		# Hacer botones cuadrados (tamaño reducido para mejor ajuste)
		b.custom_minimum_size = Vector2(180, 180)

		# Usar blanco para mostrar la imagen tal cual es
		b.modulate = base_colors[i]
		b.scale = Vector2.ONE
		# Texto del botón limpio
		b.text = ""

		# Crear TextureRect para el amuleto si no existe
		var icon_name := "ElementIcon"
		var icon_rect := b.get_node_or_null(icon_name)
		if icon_rect == null:
			icon_rect = TextureRect.new()
			icon_rect.name = icon_name
			icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

			# Configurar layout con márgenes más grandes para imágenes más pequeñas
			icon_rect.anchor_left = 0.10
			icon_rect.anchor_top = 0.10
			icon_rect.anchor_right = 0.90
			icon_rect.anchor_bottom = 0.90
			icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

			b.add_child(icon_rect)

		# Asignar textura si existe
		if i < element_textures.size() and element_textures[i] != null:
			icon_rect.texture = element_textures[i]
		else:
			# Fallback a número si falla la carga de imagen
			var l = Label.new()
			l.text = str(i + 1)
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			l.anchor_right = 1.0
			l.anchor_bottom = 1.0
			l.add_theme_font_size_override("font_size", 72)
			b.add_child(l)
		if not b.pressed.is_connected(_on_button_pressed):
			b.pressed.connect(_on_button_pressed.bind(i))

	if retry_btn and not retry_btn.pressed.is_connected(_on_retry_pressed):
		retry_btn.pressed.connect(_on_retry_pressed)
	if progress:
		progress.visible = false
	if time_bar:
		time_bar.value = 100
		time_bar.min_value = 0
		time_bar.max_value = 100
	# Make fonts big and friendly
	if title:
		title.add_theme_font_size_override("font_size", 42)
		title.anchor_left = 0.5
		title.anchor_right = 0.5
		title.anchor_top = 0.05
		title.anchor_bottom = 0.12
		title.offset_left = -300
		title.offset_right = 300
		title.offset_top = 0
		title.offset_bottom = 0
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if subtitle:
		subtitle.add_theme_font_size_override("font_size", 28)
		subtitle.anchor_left = 0.5
		subtitle.anchor_right = 0.5
		subtitle.anchor_top = 0.12
		subtitle.anchor_bottom = 0.18
		subtitle.offset_left = -300
		subtitle.offset_right = 300
		subtitle.offset_top = 0
		subtitle.offset_bottom = 0
		subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	for i in buttons.size():
		var b: Button = buttons[i]
		# Aumentar padding para que el número respire
		b.add_theme_constant_override("h_separation", 12)

	# Centrar elementos de la UI usando anchors (ya configurados arriba)
	# No se necesita reconfigurar el grid aquí, ya está centrado con anchors

	if time_bar:
		# Mover barra de tiempo abajo
		time_bar.anchor_left = 0.5
		time_bar.anchor_right = 0.5
		time_bar.anchor_top = 0.9
		time_bar.anchor_bottom = 0.93
		time_bar.offset_left = -200
		time_bar.offset_right = 200
		time_bar.offset_top = 0
		time_bar.offset_bottom = 0

	if time_label:
		# Etiqueta de tiempo justo encima de la barra
		time_label.anchor_left = 0.5
		time_label.anchor_right = 0.5
		time_label.anchor_top = 0.86
		time_label.anchor_bottom = 0.9
		time_label.offset_left = -100
		time_label.offset_right = 100
		time_label.offset_top = 0
		time_label.offset_bottom = 0
		time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	if retry_btn:
		retry_btn.anchor_left = 0.5
		retry_btn.anchor_right = 0.5
		retry_btn.anchor_top = 0.8
		retry_btn.anchor_bottom = 0.85
		retry_btn.offset_left = -80
		retry_btn.offset_right = 80
		retry_btn.offset_top = 0
		retry_btn.offset_bottom = 0

func _set_buttons_enabled(en: bool) -> void:
	for b in buttons:
		b.disabled = not en

func _playback_sequence() -> void:
	state = State.SHOW
	playing_back = true
	_set_buttons_enabled(false)
	title.text = "Observa la secuencia"
	subtitle.text = "Memoriza el orden"
	# Pequeña pausa de preparación
	await get_tree().create_timer(0.5).timeout
	for i in sequence:
		await _flash_button(i)
		await get_tree().create_timer(gap_delay).timeout
	playing_back = false
	state = State.INPUT
	title.text = "Repite la secuencia"
	subtitle.text = ""
	_set_buttons_enabled(true)
	_restart_input_timer()

func _flash_button(idx: int) -> void:
	var b: Button = buttons[idx]
	var original_col = base_colors[idx]

	# Reproducir tono elemental único para cada botón
	if idx < element_players.size() and element_players[idx] and element_players[idx].stream:
		element_players[idx].play()

	var tw = create_tween()
	tw.set_parallel(true)
	# Iluminar (ir a blanco o color muy brillante)
	tw.tween_property(b, "modulate", Color(1.2, 1.2, 1.2), show_delay * 0.4).from(original_col)
	tw.tween_property(b, "scale", Vector2(1.12, 1.12), show_delay * 0.35).from(Vector2.ONE)
	await tw.finished

	# Regresar a estado normal
	var tw2 = create_tween()
	tw2.set_parallel(true)
	tw2.tween_property(b, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw2.tween_property(b, "modulate", original_col, 0.14)

func _on_button_pressed(idx: int) -> void:
	if not _running or playing_back or state != State.INPUT:
		return
	await _flash_button(idx)
	_restart_input_timer()
	if idx == sequence[user_index]:
		user_index += 1
		_update_progress()
		if user_index >= sequence.size():
			_round_success()
	else:
		_fail_partial()


func _on_retry_pressed() -> void:
	_begin_round()

func _begin_round() -> void:
	state = State.SHOW
	_set_buttons_enabled(false)
	_generate_sequence()
	user_index = 0
	_update_progress()
	title.text = "Observa la secuencia"
	subtitle.text = "Memoriza el orden"
	retry_btn.visible = false
	tip_label.visible = true
	await _playback_sequence()

func _generate_sequence() -> void:
	sequence.clear()
	for i in range(seq_length):
		sequence.append(randi() % buttons.size())

func _update_progress() -> void:
	subtitle.text = ""

func _progress_text() -> String:
	return ""

func _attempts_text() -> String:
	return "Intentos: %d/%d" % [attempts_remaining, max_attempts]

func _round_and_attempts_text() -> String:
	return _attempts_text()

func _success() -> void:
	# Full success across all rounds
	state = State.RESULT
	_set_buttons_enabled(false)
	if success_player and success_player.stream:
		success_player.play()
	title.text = "¡Excelente!"
	subtitle.text = "Completaste las %d rondas" % total_rounds
	_end(true, 100)

func _round_success() -> void:
	completed_rounds += 1
	if completed_rounds >= total_rounds:
		_success()
		return
	# Preparar siguiente patrón
	current_round = min(current_round + 1, total_rounds)
	title.text = "¡Bien!"
	subtitle.text = "Ronda %d/%d completada" % [current_round - 1, total_rounds]
	state = State.SHOW
	_set_buttons_enabled(false)
	user_index = 0
	_update_progress()
	await get_tree().create_timer(0.8).timeout
	_generate_sequence()
	await _playback_sequence()

func _fail_partial() -> void:
	# Track best progress
	var score: int = int(floor(float(user_index) / float(sequence.size()) * 100.0))
	if score > best_progress:
		best_progress = score
	if fail_player and fail_player.stream:
		fail_player.play()
	_shake_grid()
	attempts_remaining -= 1
	if attempts_remaining > 0:
		title.text = "Inténtalo de nuevo"
		subtitle.text = _round_and_attempts_text()
		state = State.SHOW
		_set_buttons_enabled(false)
		user_index = 0
		_update_progress()
		await get_tree().create_timer(0.6).timeout
		await _playback_sequence()
	else:
		state = State.RESULT
		_set_buttons_enabled(false)
		title.text = "Intento terminado"
		subtitle.text = ""
		retry_btn.visible = true
		tip_label.visible = true
		_end(false, _aggregate_score())

func _shake_grid() -> void:
	var start_pos := grid.position
	var tw = create_tween()
	tw.set_parallel(false)
	tw.tween_property(grid, "position", start_pos + Vector2(12, 0), 0.05)
	tw.tween_property(grid, "position", start_pos - Vector2(12, 0), 0.05)
	tw.tween_property(grid, "position", start_pos, 0.05)

func _configure_difficulty(d: int) -> void:
	difficulty = clamp(d, 1, 3)
	match difficulty:
		1:
			seq_length = 4
			show_delay = 0.85
			gap_delay = 0.45
			input_timeout_sec = 4.0
		2:
			seq_length = 4
			show_delay = 1.0
			gap_delay = 0.5
			input_timeout_sec = 5.0
		_:
			seq_length = 4
			show_delay = 0.85
			gap_delay = 0.45
			input_timeout_sec = 4.0

func _ensure_timer() -> void:
	if input_timer == null:
		input_timer = Timer.new()
		input_timer.one_shot = true
		add_child(input_timer)
		input_timer.timeout.connect(_on_input_timeout)

func _restart_input_timer() -> void:
	if state == State.INPUT and input_timer:
		input_timer.start(input_timeout_sec)
		time_left = input_timeout_sec
		set_process(true)

func _on_input_timeout() -> void:
	if state == State.INPUT:
		_fail_partial()

func _process(_delta: float) -> void:
	if state == State.INPUT and input_timer and input_timer.time_left >= 0:
		time_left = input_timer.time_left
		var pct = clamp(time_left / input_timeout_sec * 100.0, 0.0, 100.0)
		if time_bar:
			time_bar.value = pct
		if time_label:
			time_label.text = "Tiempo: %.1f s" % max(0.0, time_left)
	else:
		if time_bar:
			time_bar.value = 100

func _prepare_audio() -> void:
	# Crear 4 AudioStreamPlayers para tonos elementales
	var element_sounds = [
		"res://assets/sounds/kenney_digital-audio/Audio/tone1.ogg", # Fuego
		"res://assets/sounds/kenney_digital-audio/Audio/lowThreeTone.ogg", # Tierra
		"res://assets/sounds/kenney_digital-audio/Audio/phaserDown2.ogg", # Agua
		"res://assets/sounds/kenney_digital-audio/Audio/phaserUp3.ogg" # Aire
	]

	element_players.clear()
	for i in range(4):
		var player = AudioStreamPlayer.new()
		player.stream = _try_load_stream(element_sounds[i])
		player.volume_db = 0 # Volumen normal (antes era -8)
		player.bus = "Master" # Asegurar que está en el bus Master
		add_child(player)
		element_players.append(player)

	# Crear players de feedback
	if success_player == null:
		success_player = AudioStreamPlayer.new()
		success_player.stream = _try_load_stream("res://assets/sounds/kenney_digital-audio/Audio/powerUp11.ogg")
		success_player.volume_db = 0 # Volumen normal (antes era -5)
		success_player.bus = "Master"
		add_child(success_player)

	if fail_player == null:
		fail_player = AudioStreamPlayer.new()
		fail_player.stream = _try_load_stream("res://assets/sounds/kenney_interface-sounds/Audio/error_003.ogg")
		fail_player.volume_db = 0 # Volumen normal (antes era -5)
		fail_player.bus = "Master"
		add_child(fail_player)

func _try_load_stream(path: String) -> AudioStream:
	if FileAccess.file_exists(path):
		var s = load(path)
		if s and s is AudioStream:
			return s
	return null

func _aggregate_score() -> int:
	var per_round := 100.0 / float(total_rounds)
	var current_progress := (float(user_index) / float(max(1, sequence.size()))) * per_round
	return int(clamp(per_round * float(completed_rounds) + current_progress, 0.0, 100.0))
