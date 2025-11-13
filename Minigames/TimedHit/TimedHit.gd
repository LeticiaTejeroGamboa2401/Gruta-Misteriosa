extends "res://Scripts/minigames/MiniGame.gd"

signal hit_pressed(score: int)

# UI nodes
@onready var bar: ColorRect = $Bar
@onready var zone: ColorRect = $Bar/Zone
@onready var cursor: ColorRect = $Bar/Cursor
@onready var label: Label = $Label
@onready var btn: Button = $Button

# Config
var duration: float = 5.0
var cursor_speed: float = 700.0 # px/s (aumentado para mayor dinamismo)
var zone_width: float = 220.0
var attempts: int = 3

# State
var _time: float = 0.0
var _dir: int = 1
var _best_score: int = 0
var _presses: int = 0

func start(config := {}):
	super.start(config)
	duration = float(config.get("duration", duration))
	attempts = int(config.get("attempts", attempts))
	var difficulty := int(config.get("difficulty", 1))
	var phase := str(config.get("phase", ""))
	# Ajuste de dificultad
	if difficulty >= 2:
		# Para Huaychivo, mantenerlo desafiante pero justo
		if phase == "huaychivo":
			zone_width = 200.0
			cursor_speed = 750.0
		else:
			zone_width = 160.0
			cursor_speed = 800.0
	else:
		zone_width = 220.0
		cursor_speed = 700.0
	# Posicionar zona al centro
	zone.size.x = zone_width
	zone.position.x = (bar.size.x - zone_width) * 0.5
	cursor.position.x = 0
	label.text = "Apunta al centro verde y presiona!"
	btn.disabled = false

func _process(delta: float) -> void:
	if not _running:
		return
	_time += delta
	if _time >= duration or _presses >= attempts:
		_end(true, _best_score)
		return
	# Mover cursor ping-pong dentro de la barra
	var x := cursor.position.x + _dir * cursor_speed * delta
	var min_x := 0.0
	var max_x := bar.size.x - cursor.size.x
	if x <= min_x:
		x = min_x
		_dir = 1
	elif x >= max_x:
		x = max_x
		_dir = -1
	cursor.position.x = x

func _ready() -> void:
	# Asegurar tamaños relativos a pantalla si aún no están
	await get_tree().process_frame
	# Si la barra no tiene tamaño (cargado por código), forzar valores amigables
	if bar.size == Vector2.ZERO:
		bar.size = Vector2(600, 24)
		bar.position = Vector2(200, 260)
		cursor.size = Vector2(8, 36)
		cursor.position = Vector2(0, -6)
		zone.size = Vector2(zone_width, 36)
		zone.position = Vector2((bar.size.x - zone_width) / 2, -6)

	# Conectar botón si aún no está conectado
	if btn and not btn.pressed.is_connected(_on_Button_pressed):
		btn.pressed.connect(_on_Button_pressed)

func _on_Button_pressed() -> void:
	if not _running:
		return
	_presses += 1
	var cx_center: float = cursor.global_position.x + cursor.size.x * 0.5
	var z_left: float = zone.global_position.x
	var z_right: float = zone.global_position.x + zone.size.x
	var z_center: float = (z_left + z_right) * 0.5
	var dist: float = abs(cx_center - z_center)
	var max_dist: float = zone.size.x * 0.5
	var score: int = int(round(max(0.0, (1.0 - dist / max_dist) * 100.0)))
	_best_score = max(_best_score, score)
	emit_signal("hit_pressed", score)
	# Feedback ligero
	label.text = "Intento %d/%d  •  Puntuación: %d" % [_presses, attempts, score]
	# Pequeño flash de zona
	var tw = create_tween()
	tw.tween_property(zone, "modulate:a", 1.0, 0.05).from(0.6)
