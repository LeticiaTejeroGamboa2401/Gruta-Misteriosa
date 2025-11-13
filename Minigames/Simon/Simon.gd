extends "res://Scripts/minigames/MiniGame.gd"

enum State {IDLE, SHOW, INPUT, RESULT}

@onready var title: Label = $Title
@onready var subtitle: Label = $SubTitle
@onready var progress: ProgressBar = $Progress
@onready var time_bar: ProgressBar = $Time
@onready var time_label: Label = $TimeLabel
@onready var grid: Control = $Grid
@onready var start_btn: Button = $StartBtn
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
# Colores base más vivos y con alto contraste (rojo, verde, azul, amarillo)
var base_colors := [
	Color(0.93, 0.27, 0.27),
	Color(0.22, 0.85, 0.35),
	Color(0.25, 0.45, 0.98),
	Color(0.98, 0.86, 0.18)
]

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

# SFX (optional)
var click_player: AudioStreamPlayer
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
	start_btn.visible = false
	retry_btn.visible = false
	tip_label.visible = true
	_begin_round()

func _ready() -> void:
	# Asegurar colores y conexiones
	for i in buttons.size():
		var b: Button = buttons[i]
		b.modulate = base_colors[i]
		b.scale = Vector2.ONE
		# Texto del botón limpio: usaremos un Label hijo grande con sombra
		b.text = ""
		# Crear label numérico si no existe
		var num_name := "NumLabel"
		var lbl := b.get_node_or_null(num_name)
		if lbl == null:
			var l = Label.new()
			l.name = num_name
			l.text = str(i + 1)
			# Centrar y grande
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			l.anchor_left = 0
			l.anchor_top = 0
			l.anchor_right = 1
			l.anchor_bottom = 1
			l.offset_left = 0
			l.offset_top = 0
			l.offset_right = 0
			l.offset_bottom = 0
			l.add_theme_font_size_override("font_size", 72)
			l.add_theme_color_override("font_color", Color(1, 1, 1))
			l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
			l.add_theme_constant_override("shadow_offset_x", 2)
			l.add_theme_constant_override("shadow_offset_y", 2)
			b.add_child(l)
		if not b.pressed.is_connected(_on_button_pressed):
			b.pressed.connect(_on_button_pressed.bind(i))
	if start_btn and not start_btn.pressed.is_connected(_on_start_pressed):
		start_btn.pressed.connect(_on_start_pressed)
	if retry_btn and not retry_btn.pressed.is_connected(_on_retry_pressed):
		retry_btn.pressed.connect(_on_retry_pressed)
	if progress:
		progress.value = 0
		progress.min_value = 0
		progress.max_value = 100
	if time_bar:
		time_bar.value = 100
		time_bar.min_value = 0
		time_bar.max_value = 100
	# Make fonts big and friendly
	if title:
		title.add_theme_font_size_override("font_size", 36)
	if subtitle:
		subtitle.add_theme_font_size_override("font_size", 24)
	for i in buttons.size():
		var b: Button = buttons[i]
		# Aumentar padding para que el número respire
		b.add_theme_constant_override("h_separation", 12)

func _set_buttons_enabled(en: bool) -> void:
	for b in buttons:
		b.disabled = not en

func _playback_sequence() -> void:
	state = State.SHOW
	playing_back = true
	_set_buttons_enabled(false)
	title.text = "Observa el patrón del alux"
	subtitle.text = "Memoriza el orden"
	# Pequeña pausa de preparación
	await get_tree().create_timer(0.5).timeout
	for i in sequence:
		await _flash_button(i)
		await get_tree().create_timer(gap_delay).timeout
	playing_back = false
	state = State.INPUT
	title.text = "Repite el patrón"
	subtitle.text = _progress_text()
	_set_buttons_enabled(true)
	_restart_input_timer()

func _flash_button(idx: int) -> void:
	var b: Button = buttons[idx]
	if click_player and click_player.stream:
		click_player.play()
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(b, "modulate", Color(1, 1, 1), show_delay * 0.4).from(b.modulate)
	tw.tween_property(b, "scale", Vector2(1.12, 1.12), show_delay * 0.35).from(Vector2.ONE)
	await tw.finished
	var tw2 = create_tween()
	tw2.tween_property(b, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

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

func _on_start_pressed() -> void:
	if state == State.IDLE:
		_begin_round()

func _on_retry_pressed() -> void:
	_begin_round()

func _begin_round() -> void:
	state = State.SHOW
	_set_buttons_enabled(false)
	_generate_sequence()
	user_index = 0
	_update_progress()
	title.text = "Observa el patrón del alux"
	subtitle.text = _round_and_attempts_text()
	retry_btn.visible = false
	tip_label.visible = true
	await _playback_sequence()

func _generate_sequence() -> void:
	sequence.clear()
	for i in range(seq_length):
		sequence.append(randi() % buttons.size())

func _update_progress() -> void:
	if progress:
		var pct = 0.0 if sequence.size() == 0 else (float(user_index) / float(sequence.size()) * 100.0)
		progress.value = pct
	subtitle.text = _progress_text()

func _progress_text() -> String:
	return "Patrón %d/%d  ·  Paso %d/%d  ·  %s" % [current_round, total_rounds, user_index, max(1, sequence.size()), _attempts_text()]

func _attempts_text() -> String:
	return "Intentos: %d/%d" % [attempts_remaining, max_attempts]

func _round_and_attempts_text() -> String:
	return "Patrón %d/%d  ·  %s" % [current_round, total_rounds, _attempts_text()]

func _success() -> void:
	# Full success across all rounds
	state = State.RESULT
	_set_buttons_enabled(false)
	if success_player and success_player.stream:
		success_player.play()
	title.text = "¡Excelente!"
	subtitle.text = "Completaste los %d patrones" % total_rounds
	_end(true, 100)

func _round_success() -> void:
	completed_rounds += 1
	if completed_rounds >= total_rounds:
		_success()
		return
	# Preparar siguiente patrón
	current_round = min(current_round + 1, total_rounds)
	title.text = "¡Bien!"
	subtitle.text = "Patrón %d/%d completado" % [current_round - 1, total_rounds]
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
		# Replay same sequence for another try
		title.text = "Inténtalo de nuevo"
		subtitle.text = "%s  ·  Avance %d%%" % [_round_and_attempts_text(), best_progress]
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
		subtitle.text = "Avance total %d%%" % _aggregate_score()
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
	# Create players once
	if click_player == null:
		click_player = AudioStreamPlayer.new()
		add_child(click_player)
	if success_player == null:
		success_player = AudioStreamPlayer.new()
		add_child(success_player)
	if fail_player == null:
		fail_player = AudioStreamPlayer.new()
		add_child(fail_player)
	# No reproducir música de fondo durante el minijuego: no asignar pista al 'click'
	click_player.stream = null
	# Efectos de éxito/fracaso (cortos)
	success_player.stream = _try_load_stream("res://audio/triunfo.ogg")
	fail_player.stream = _try_load_stream("res://audio/losing.ogg")

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
