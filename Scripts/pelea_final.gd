extends Node2D

# ----- Variables principales -----
var player_health: int = 6
var dogs_health: Array = [3, 3, 3] # cada perro requiere 3 golpes bien acertados
var dogs_alive: Array = [true, true, true]
var huaychivo_health: int = 5
var current_phase: String = "dialog" # dialog -> dogs -> huaychivo -> victory/defeat

var selected_weapon: String = "" # viene de Global.selected_weapon
var processing_turn: bool = false # renombrado para evitar shadowing
var active_minigame: Node = null
var minigame_running: bool = false

# Timing constants (restaurables)
const DIALOG_AUTO_ADVANCE_TIME: float = 3.0
const RETURN_TO_IDLE_DELAY: float = 1.0
const ENEMY_HIT_FLASH_DOGS: float = 0.14
const ENEMY_HIT_FLASH_HUAYCHIVO: float = 0.18
const POST_HIT_DELAY: float = 0.25

# ----- Variables para el sistema de diálogos -----
var dialog_lines: Array = []
var current_dialog_index: int = 0
var next_btn_cooldown: bool = false

# Referencia al personaje para controlar movimiento
var player_instance: Node2D = null
# Referencia al arma instanciada
var player_weapon: Node2D = null
var original_player_sprite_scale: Vector2 = Vector2.ONE
var weapon_idle_position: Vector2 = Vector2.ZERO
var weapon_idle_rotation: float = 0.0
var weapon_tween: Tween = null

# ---- Dog motion state (sin sprites adicionales) ----
const DOG_LUNGE_DIST: float = 28.0
const DOG_LUNGE_TIME: float = 0.12
const DOG_RETURN_TIME: float = 0.14
const DOG_KNOCKBACK_DIST: float = 36.0
const DOG_KNOCKBACK_TIME: float = 0.16
const DOG_FADE_TIME: float = 0.25
const DOG_HIT_TINT := Color(1.0, 0.5, 0.5, 1.0)

var dog_idle_positions: Array = [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
var dog_tweens: Array = [null, null, null]
var dog_busy: Array = [false, false, false]
var dog_bob_tweens: Array = [null, null, null]
var dog_bob_base_pos: Array = [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
var dog_press_hits: int = 0
var dog_minigame_active: bool = false
var macana_tokens: int = 0 # Con arma A: necesitas 2 ataques completos (3+3 aciertos) para derrotar 1 perro
var huaychivo_tutorial_shown: bool = false
var waiting_huaychivo_instructions: bool = false


# Helper para leer valores desde el autoload Global de forma robusta
func _get_global_value(key: String, default_val):
	# Intentar obtener autoload Global desde el árbol de nodos (/root/Global)
	var g = get_node_or_null("/root/Global")
	if g:
		var v = null
		if g.has_method("get"):
			v = g.get(key)
			if v != null:
				print("DEBUG: _get_global_value found '%s' in /root/Global" % key)
				return v

	# Si no está en /root/Global, buscar en los hijos del root (por si el autoload tiene otro nombre)
	var root = get_tree().get_root()
	for c in root.get_children():
		if c == null:
			continue
		if c == self:
			continue
		if c.has_method("get"):
			var vv = c.get(key)
			if vv != null:
				print("DEBUG: _get_global_value found '%s' in node %s" % [key, str(c)])
				return vv
	# Intentar Engine singleton como último recurso
	if Engine.has_singleton("Global"):
		var gs = Engine.get_singleton("Global")
		if gs and gs.has_method("get"):
			var v2 = gs.get(key)
			if v2 != null:
				print("DEBUG: _get_global_value found '%s' via Engine.get_singleton(Global)" % key)
				return v2
	return default_val

# ----- Rutas según tu estructura -----
@onready var background: TextureRect = $Background
@onready var characters: Node2D = $Characters
@onready var player_spawn: Marker2D = $Characters/PlayerSpawnPoint
@onready var dogs_node: Node2D = $Characters/Dogs
@onready var nahual1: CharacterBody2D = $Characters/Dogs/nahual1
@onready var nahual2: CharacterBody2D = $Characters/Dogs/nahual2
@onready var nahual3: CharacterBody2D = $Characters/Dogs/nahual3
@onready var huaychivo: Node2D = $Characters/HuayChivo


# UI
@onready var canvas: CanvasLayer = $CanvasLayer
@onready var healthbar: Control = $CanvasLayer/HealthBar
@onready var action_buttons: Control = $CanvasLayer/ActionButtons
@onready var btn_attack_dogs: Button = $CanvasLayer/ActionButtons/AttackDogs
@onready var btn_attack_huaychivo: Button = null
# Verificar path completo si el botón no se encuentra
@onready var dialog_box: Control = $CanvasLayer/DialogBox
@onready var dialog_label: Label = $CanvasLayer/DialogBox/Label
@onready var huaychivo_label: Label = $CanvasLayer/HuaychivoLabel
@onready var personaje_label: Label = $CanvasLayer/PersonajeLabel
@onready var personaje_name_label: Label = $CanvasLayer/PersonajeLabel/PersonajeName
@onready var dialog_next_btn: Button = get_node_or_null("CanvasLayer/NextButton") as Button
@onready var dialog_card: Panel = get_node_or_null("CanvasLayer/DialogBox/Card") as Panel
var phase_label: Label = null

# Barra de vida general de enemigos
var general_enemy_healthbar: ProgressBar = null

# Barras de vida de enemigos
var dog_healthbars: Array[ProgressBar] = []
var huaychivo_healthbar: ProgressBar = null
var tutorial_overlay: Panel = null
var timedhit_tutorial: Panel = null
var simon_tutorial: Panel = null
var dogs_tutorial_shown: bool = false
var practice_active: bool = false
var pending_minigame_type: String = ""

# Effects
@onready var hit_flash: ColorRect = get_node_or_null("Effects/HitFlash") as ColorRect
@onready var death_effect: CPUParticles2D = get_node_or_null("Effects/DeathEffect") as CPUParticles2D

# ----- Ready -----

func _ready() -> void:
	_initialize_scene()
	_spawn_general_enemy_healthbar()
	_spawn_enemy_healthbars()
	_init_dog_motion_state()
	start_intro_sequence()
	_create_tutorial_overlay()

func _process(_delta: float) -> void:
	pass

func _spawn_general_enemy_healthbar() -> void:
	# Instanciar ProgressBar general y agregarla a la HUD
	# Intentamos no depender de recursos externos .tres que pueden no existir
	general_enemy_healthbar = ProgressBar.new()
	general_enemy_healthbar.min_value = 0
	general_enemy_healthbar.max_value = 14 # 3+3+3+5
	general_enemy_healthbar.value = 14
	# ProgressBar.percent_visible no existe en algunas versiones de Godot 4.x.
	# En su lugar mostramos el valor mediante una Label si fuera necesario.
	general_enemy_healthbar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	general_enemy_healthbar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	general_enemy_healthbar.custom_minimum_size = Vector2(300, 18)
	# Posicionar arriba en la HUD
	# Agregar al CanvasLayer para que las propiedades de Control funcionen correctamente
	canvas.add_child(general_enemy_healthbar)
	general_enemy_healthbar.anchor_left = 0.5
	general_enemy_healthbar.anchor_right = 0.5
	general_enemy_healthbar.anchor_top = 0.05
	general_enemy_healthbar.anchor_bottom = 0.05
	general_enemy_healthbar.offset_left = -150
	general_enemy_healthbar.offset_right = 150
	general_enemy_healthbar.offset_top = 0
	general_enemy_healthbar.offset_bottom = 18
	general_enemy_healthbar.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _spawn_enemy_healthbars() -> void:
	dog_healthbars.clear()
	huaychivo_healthbar = null

# ----- Inicialización -----
func _initialize_scene() -> void:
	# Cargar el arma desde el singleton Global de forma segura
	# first try Global, then fallback to a simple test property on the scene (test_selected_weapon), then default
	var gw = _get_global_value("selected_weapon", null)
	if gw != null:
		selected_weapon = str(gw)
		print("DEBUG: selected_weapon leído desde Global: %s" % selected_weapon)
		# Normalizar inmediatamente
		selected_weapon = _normalize_weapon(selected_weapon)
		print("DEBUG: selected_weapon normalizado a: %s" % selected_weapon)
	else:
		# Try a test override present in the .tscn (property on the root node)
		var t = null
		if has_method("get"):
			# get() may return null if not present
			t = get("test_selected_weapon") if has_method("get") else null
		if t != null and str(t) != "":
			selected_weapon = str(t)
			print("DEBUG: selected_weapon leído desde propiedad de escena test_selected_weapon: %s" % selected_weapon)
			selected_weapon = _normalize_weapon(selected_weapon)
			print("DEBUG: selected_weapon normalizado a: %s" % selected_weapon)
		else:
			selected_weapon = "inutil"
			print("ADVERTENCIA: No se encontró 'selected_weapon' en Global ni override; usando arma por defecto.")

	# --- PARA PRUEBAS (condicional) ---
	# Permite forzar el arma C solo si en Global existe una bandera booleana
	# 'debug_force_weapon_c' en true. Así no rompemos pruebas visuales de otras armas.
	var __force_c = bool(_get_global_value("debug_force_weapon_c", false))
	if __force_c:
		print("DEBUG: TEST OVERRIDE habilitado -> forcing selected_weapon = weapon_c")
		selected_weapon = "weapon_c"

	# Normalizar el token del arma
	selected_weapon = _normalize_weapon(selected_weapon)

	# Conectar señales de UI
	if btn_attack_dogs:
		btn_attack_dogs.connect("pressed", Callable(self, "_on_attack_pressed"))
	# Intentar localizar el botón de atacar huaychivo; si no existe, reutilizar el botón de perros
	if not btn_attack_huaychivo:
		btn_attack_huaychivo = get_node_or_null("CanvasLayer/ActionButtons/AttackHuaychivo")
		if not btn_attack_huaychivo:
			btn_attack_huaychivo = btn_attack_dogs
	if btn_attack_huaychivo:
		if not btn_attack_huaychivo.is_connected("pressed", Callable(self, "_on_attack_pressed")):
			btn_attack_huaychivo.connect("pressed", Callable(self, "_on_attack_pressed"))
	# Si no existe botón huaychivo en escena, crear uno y ubicarlo (para mantener interfaz anterior)
	if action_buttons and not get_node_or_null("CanvasLayer/ActionButtons/AttackHuaychivo"):
		if btn_attack_dogs:
			var new_btn = Button.new()
			new_btn.name = "AttackHuaychivo"
			new_btn.text = "Atacar Huaychivo"
			# copiar tamaño/flags del botón existente si aplica
			new_btn.size_flags_horizontal = btn_attack_dogs.size_flags_horizontal
			new_btn.size_flags_vertical = btn_attack_dogs.size_flags_vertical
			action_buttons.add_child(new_btn)
			new_btn.anchor_left = btn_attack_dogs.anchor_left
			new_btn.anchor_right = btn_attack_dogs.anchor_right
			new_btn.anchor_top = btn_attack_dogs.anchor_top
			new_btn.anchor_bottom = btn_attack_dogs.anchor_bottom
			new_btn.offset_left = btn_attack_dogs.offset_left + 140
			new_btn.offset_right = btn_attack_dogs.offset_right + 140
			new_btn.offset_top = btn_attack_dogs.offset_top
			new_btn.offset_bottom = btn_attack_dogs.offset_bottom
			btn_attack_huaychivo = new_btn
			new_btn.connect("pressed", Callable(self, "_on_attack_pressed"))
	if dialog_next_btn:
		dialog_next_btn.connect("pressed", Callable(self, "_on_dialog_next_pressed"))

	# Configuración inicial de la UI
	if dialog_next_btn:
		dialog_next_btn.visible = false
	if dialog_card:
		dialog_card.visible = false
	if action_buttons:
		action_buttons.visible = false
	if huaychivo_label:
		huaychivo_label.visible = false
	if personaje_label:
		personaje_label.visible = false

	update_health_ui()
	_spawn_player()
	if hit_flash:
		hit_flash.visible = false
	_configure_dogs_collision()
	_configure_dogs_properties()
	_configure_collision_layers()

	# Evitar parpadeo: asegurarse de que el HuayChivo empiece invisible (alpha 0)
	if huaychivo:
		var sprite_child := huaychivo.get_node_or_null("Sprite2D")
		if sprite_child:
			sprite_child.modulate.a = 0.0
			sprite_child.visible = true
			sprite_child.scale.x = - abs(sprite_child.scale.x)
		else:
			if huaychivo.has_method("set_flip_h") or huaychivo.has_property("flip_h"):
				huaychivo.flip_h = true
			else:
				huaychivo.scale.x = - abs(huaychivo.scale.x)
			huaychivo.visible = false

		phase_label = Label.new()
		phase_label.name = "PhaseLabel"
		phase_label.text = ""
		phase_label.position = Vector2(12, 12)
		phase_label.add_theme_color_override("font_color", Color(1, 1, 1))
		if "horizontal_alignment" in phase_label:
			phase_label.set("horizontal_alignment", 0)
		elif "align" in phase_label:
			phase_label.set("align", 0)
		canvas.add_child(phase_label)
		_set_phase_label_text()
	_center_battle_ui()
	if healthbar:
		healthbar.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _init_dog_motion_state() -> void:
	# Guardar posiciones base locales de cada perro al inicio
	if nahual1:
		dog_idle_positions[0] = nahual1.position
	if nahual2:
		dog_idle_positions[1] = nahual2.position
	if nahual3:
		dog_idle_positions[2] = nahual3.position
	# Resetear tweens y flags
	dog_tweens = [null, null, null]
	dog_busy = [false, false, false]
	# Resetear bobbing
	dog_bob_tweens = [null, null, null]
	dog_bob_base_pos = [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]


func _spawn_player() -> void:
	# Cargar la escena del personaje desde el singleton Global de forma segura
	var scene: PackedScene = null
	var sc = _get_global_value("selected_character_scene", null)
	if sc != null:
		scene = sc
		print("DEBUG: selected_character_scene leído desde Global")
	if not scene:
		print("ADVERTENCIA: No se encontró 'selected_character_scene' en Global. Cargando personaje por defecto.")
		scene = load("res://Scenes/Lele_Player.tscn")

	if scene and scene is PackedScene:
		var inst = scene.instantiate()
		inst.can_animate = false # Desactivar animación de movimiento
		inst.position = player_spawn.position
		# Asignar nombre del personaje desde Global para personalizar UI/diálogos
		var pname: String = str(_get_global_value("selected_character_name", ""))
		if pname.strip_edges() != "":
			inst.name = pname
		# Voltear horizontalmente el nodo visual del personaje si existe
		var sprite_child := inst.get_node_or_null("AnimatedSprite2D")
		if sprite_child:
			sprite_child.scale.x = - abs(sprite_child.scale.x)
		else:
			inst.scale.x = - abs(inst.scale.x)
		characters.add_child(inst)
		player_instance = inst

		# Instanciar y adjuntar el arma seleccionada usando la textura guardada en Global
		var weapon_texture: Texture2D = _get_global_value("selected_weapon_texture", null)

		if weapon_texture:
			# Crear un Sprite2D para mostrar el arma
			player_weapon = Sprite2D.new()
			player_weapon.texture = weapon_texture

			# Ajustar escala del arma para que se vea proporcional y horizontal
			player_weapon.scale = Vector2(0.15, 0.15) # Escala más pequeña para mejor proporción

			# Rotar el arma 90 grados para que quede horizontal
			# La imagen del arma está en vertical, necesitamos rotarla para que sea horizontal
			player_weapon.rotation_degrees = -90

			# Orientación base: apuntar hacia la izquierda (enemigo).
			# Nota: tras rotar, usar flip_h para espejar horizontalmente.
			player_weapon.flip_v = false
			player_weapon.flip_h = true
			# Corrección específica: armas A y C venían invertidas (punta hacia atrás),
			# así que NO las espejeamos horizontalmente para que la punta apunte hacia el frente.
			var _w := _normalize_weapon(selected_weapon)
			if _w == "weapon_a" or _w == "weapon_c":
				player_weapon.flip_h = false
			# Jícara: girar un poco hacia la derecha para mejor ángulo visual
			elif _w == "weapon_b":
				# Baseline: -90° (horizontal). Un pequeño giro a la derecha = -12° adicionales.
				player_weapon.rotation_degrees -= 12.0

			# Buscar marker de mano
			var hand_marker = player_instance.get_node_or_null("Hand")
			if hand_marker:
				player_instance.add_child(player_weapon)
				player_weapon.position = hand_marker.position + Vector2(-10, -15)
				weapon_idle_position = player_weapon.position
				weapon_idle_rotation = player_weapon.rotation_degrees
			else:
				# Si no hay marker, poner en una posición relativa al personaje
				# Ajustada para que parezca que el personaje sostiene el arma
				player_instance.add_child(player_weapon)
				player_weapon.position = Vector2(-20, -10)
				weapon_idle_position = player_weapon.position
				weapon_idle_rotation = player_weapon.rotation_degrees

			print("DEBUG: Arma instanciada con textura desde Global (rotada a horizontal)")
		else:
			print("ADVERTENCIA: No se encontró 'selected_weapon_texture' en Global")

		# Forzar animación base al spawnear
		var anim_sprite = inst.get_node_or_null("AnimatedSprite2D")
		if anim_sprite:
			original_player_sprite_scale = anim_sprite.scale
			anim_sprite.play("Derecha")

		# Slide hacia la izquierda tras spawnear
		var slide_tween = create_tween()
		var target_x = inst.position.x - 200.0
		slide_tween.tween_property(inst, "position:x", target_x, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		slide_tween.finished.connect(_stop_player_animation)

func _stop_player_animation() -> void:
	if player_instance:
		var anim_sprite = player_instance.get_node_or_null("AnimatedSprite2D")
		if anim_sprite:
			anim_sprite.stop()

func _return_player_to_idle() -> void:
	if player_instance:
		var anim_sprite = player_instance.get_node_or_null("AnimatedSprite2D")
		if anim_sprite:
			anim_sprite.scale = original_player_sprite_scale
			anim_sprite.animation = "Derecha"
			anim_sprite.frame = 0
			anim_sprite.stop()

# ----- El resto del archivo sin cambios -----

# Funciones para manejar el texto de fase (top-level para evitar nested functions)
func set_phase(new_phase: String) -> void:
	current_phase = new_phase
	_set_phase_label_text()
	# Ajustes de UI por fase
	if current_phase == "dialog":
		if dialog_card:
			dialog_card.visible = true
		if dialog_box:
			dialog_box.visible = true
		if dialog_next_btn:
			dialog_next_btn.visible = true
		if action_buttons:
			action_buttons.visible = false
	elif current_phase == "dogs" or current_phase == "huaychivo":
		# mostrar botones de acción
		if dialog_card:
			dialog_card.visible = false
		if dialog_box:
			dialog_box.visible = false
		if action_buttons:
			action_buttons.visible = true

		# Configuración específica para cada fase
		if current_phase == "dogs":
			if btn_attack_dogs:
				btn_attack_dogs.disabled = false
				btn_attack_dogs.visible = true
				btn_attack_dogs.text = "Atacar Perros"
			# Activar bobbing del perro en turno
			_refresh_dog_agro_loops()

			# Ocultar botón de huaychivo en fase de perros
			if btn_attack_huaychivo:
				btn_attack_huaychivo.visible = false

		elif current_phase == "huaychivo":
			# Si hay botón específico para huaychivo, usarlo, sino adaptar el de perros
			print("DEBUG: Cambiando fase a huaychivo, botón huaychivo encontrado: %s" % (btn_attack_huaychivo != null))
			if btn_attack_huaychivo:
				btn_attack_huaychivo.disabled = false
				btn_attack_huaychivo.visible = true
				# Ocultar botón de perros cuando hay botón específico
				if btn_attack_dogs:
					btn_attack_dogs.visible = false
			else:
				# Fallback si no hay botón específico
				if btn_attack_dogs:
					btn_attack_dogs.disabled = false
					btn_attack_dogs.visible = true
					btn_attack_dogs.text = "Atacar Huaychivo"
					print("DEBUG: Usando botón de perros para atacar al Huaychivo, texto actualizado")

			# Mostrar instrucciones antes del primer minijuego del Huaychivo
			if not huaychivo_tutorial_shown:
				_show_huaychivo_instructions()
				huaychivo_tutorial_shown = true

			# Mensaje educativo neutral si el arma actual no puede dañar al Huaychivo (sin revelar la correcta)
			if _normalize_weapon(selected_weapon) != "weapon_c":
				await _show_temporary_message("Tu arma actual no afecta al Huaychivo. Observa y piensa en otra estrategia.", 2.8)
		# Al salir de perros, detener bobbing
		if current_phase != "dogs":
			_stop_all_dog_bob_loops()
	elif current_phase == "victory" or current_phase == "defeat":
		# finales: ocultar controles de combate
		if action_buttons:
			action_buttons.visible = false
		if btn_attack_dogs:
			btn_attack_dogs.disabled = true
		_stop_all_dog_bob_loops()
	# Ejecutar secuencias finales
	if current_phase == "victory":
		# pequeña pausa para mostrar estado y luego llamar a victory()
		await victory()
	elif current_phase == "defeat":
		await defeat()
		if dialog_box:
			dialog_box.visible = false

# Actualiza el texto del indicador de fase en pantalla
func _set_phase_label_text() -> void:
	if phase_label:
		var next_phase := ""
		match current_phase:
			"dialog": next_phase = "dogs"
			"dogs": next_phase = "huaychivo"
			"huaychivo": next_phase = "victory/defeat"
			_:
				next_phase = "-"
		phase_label.text = "Fase: %s\nSiguiente: %s" % [current_phase, next_phase]

# Muestra un mensaje temporal con fade in/out en la caja de diálogo
func _show_temporary_message(text: String, duration: float = 1.4) -> void:
	if dialog_box and dialog_label:
		dialog_label.text = text
		dialog_label.modulate.a = 0.0
		dialog_label.visible = true
		dialog_box.modulate.a = 0.0
		dialog_box.visible = true
		if huaychivo_label:
			huaychivo_label.visible = false
		if personaje_label:
			personaje_label.visible = false

		var tween_in = create_tween()
		tween_in.set_parallel(true)
		tween_in.tween_property(dialog_box, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_SINE)
		tween_in.tween_property(dialog_label, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_SINE)

		await _delay(duration)

		var tween_out = create_tween()
		tween_out.set_parallel(true)
		tween_out.tween_property(dialog_box, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_SINE)
		tween_out.tween_property(dialog_label, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_SINE)
		await tween_out.finished

	if current_phase != "dialog" and dialog_box:
		dialog_box.visible = false

# Mostrar instrucciones del minijuego de Huaychivo antes del primer intento
func _show_huaychivo_instructions() -> void:
	if action_buttons:
		action_buttons.visible = false
	waiting_huaychivo_instructions = true
	if tutorial_overlay and simon_tutorial:
		tutorial_overlay.visible = true
		simon_tutorial.visible = true
	return
# ----- Secuencia de introducción -----
func start_intro_sequence() -> void:
	# Posiciones objetivo para que los perros queden distribuidos y no se sobrepongan
	var mid_x: float = 575.0
	var dog1_x: float = mid_x
	var dog2_x: float = mid_x - 80.0
	var dog3_x: float = mid_x - 160.0
	nahual1.target_position_x = dog1_x
	nahual2.target_position_x = dog2_x
	nahual3.target_position_x = dog3_x

	# Tween paralelo para que los perros se muevan a sus posiciones
	var dogs_tween = create_tween()
	dogs_tween.set_parallel(true)
	dogs_tween.tween_property(nahual1, "global_position:x", dog1_x, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	dogs_tween.tween_property(nahual2, "global_position:x", dog2_x, 1.32).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	dogs_tween.tween_property(nahual3, "global_position:x", dog3_x, 1.44).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await dogs_tween.finished

	# Pausar la animación de correr de los perros al terminar el slide
	var anim1 := nahual1.get_node_or_null("AnimatedSprite2D")
	var anim2 := nahual2.get_node_or_null("AnimatedSprite2D")
	var anim3 := nahual3.get_node_or_null("AnimatedSprite2D")
	if anim1:
		anim1.pause()
	if anim2:
		anim2.pause()
	if anim3:
		anim3.pause()

	# Asegurar que los nahuales se detengan al llegar
	nahual1.target_position_x = 0
	nahual2.target_position_x = 0
	nahual3.target_position_x = 0
	nahual1.velocity.x = 0
	nahual2.velocity.x = 0
	nahual3.velocity.x = 0

	# Hacer aparecer el HuayChivo (fade-in)
	# Intentar fade-in sobre el Sprite2D hijo si existe, sino hacer visible directo
	var sprite_child := huaychivo.get_node_or_null("Sprite2D")
	if sprite_child:
		sprite_child.modulate.a = 0.0
		var huaychivo_tween = create_tween()
		huaychivo_tween.tween_property(sprite_child, "modulate:a", 1.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		await huaychivo_tween.finished
	else:
		huaychivo.visible = true

	# Después del fade-in, hacer un slide para que el HuayChivo quede antes que los perros
	var huay_target_x: float = mid_x - 400.0
	var slide_tween = create_tween()
	slide_tween.tween_property(huaychivo, "global_position:x", huay_target_x, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await slide_tween.finished
	var sprite_child2 := huaychivo.get_node_or_null("Sprite2D")
	if not sprite_child2:
		huaychivo.visible = true

	# Esperar a que todos los slides hayan terminado y hacer una pausa final
	await _delay(0.4)

	# Ahora sí, iniciar los diálogos
	play_dialog_intro()

	# Importante: después de que todos los movimientos iniciales terminaron,
	# refrescamos las posiciones "idle" de los perros para futuras animaciones.
	_init_dog_motion_state()

# ----- Helpers -----
func _delay(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

# Oculta todas las etiquetas de diálogo para evitar superposiciones y efecto "doble"
func _hide_all_dialog_texts() -> void:
	if dialog_box:
		dialog_box.visible = false
	if dialog_label:
		dialog_label.visible = false
	if huaychivo_label:
		huaychivo_label.visible = false
	if personaje_label:
		personaje_label.visible = false
	if personaje_name_label:
		personaje_name_label.visible = false

# Obtiene el nombre del personaje seleccionado desde Global; fallback seguro
func _get_selected_character_name() -> String:
	var name_val = _get_global_value("selected_character_name", null)
	if name_val == null:
		return ""
	var txt := str(name_val).strip_edges()
	return txt

# Calcular daño según arma y tipo de objetivo
func _get_damage_for(target: String) -> int:
	# Mapear exactamente según la especificación del diseño
	var w := _normalize_weapon(selected_weapon if selected_weapon != "" else "inutil")
	print("DEBUG: Calculando daño para target='%s' con arma normalizada='%s'" % [target, w])

	# Uso canónico basado en arma normalizada (fallback cuando no hay minijuego)
	if w == "weapon_a":
		# Macana: solo avanza contra perros si completas 2 ataques con 3 aciertos cada uno (manejado en minijuego)
		# En fallback (sin minijuego) no causa daño directo
		return 0
	elif w == "weapon_b":
		return (1 if target == "dog" else 0)
	elif w == "weapon_c":
		# Correcta: daño base en fallback = 1 (perros y Huaychivo) si no hay minijuego
		return 1
	else:
		# Fallback seguro
		return 0

# Enemigos responden: un perro vivo ataca con daño menor; si ya no hay perros, HuayChivo ataca con daño mayor
func _enemy_retaliation() -> void:
	var wnorm := _normalize_weapon(selected_weapon)
	# Daño fijo por arma en cada turno (según requerimiento):
	# C -> 1 corazón, A -> 2 corazones, B -> 3 corazones
	var dmg_map := {
		"weapon_c": 1,
		"weapon_a": 2,
		"weapon_b": 3
	}
	var inc: int = int(dmg_map.get(wnorm, 3))
	player_health -= inc
	if (current_phase == "dogs" or current_phase == "huaychivo") and wnorm == "weapon_c" and player_health <= 1:
		player_health = 1
	print("DEBUG: incoming -> phase=%s, weapon=%s, dmg=%d" % [current_phase, wnorm, inc])
	# Efecto de impacto
	if hit_flash:
		hit_flash.visible = true
		var flash_time := (ENEMY_HIT_FLASH_DOGS if current_phase == "dogs" else ENEMY_HIT_FLASH_HUAYCHIVO)
		await _delay(flash_time)
		hit_flash.visible = false
	update_health_ui()

	# Chequear derrota
	if player_health <= 0:
		player_health = 0
		set_phase("defeat")
		print("Derrota: la salud del jugador ha llegado a 0")
		# Ocultar botones de acción
		if action_buttons:
			action_buttons.visible = false


# Normaliza el nombre del arma a los tokens canonicales usados internamente
func _normalize_weapon(w: String) -> String:
	if not w:
		return "weapon_a"
	w = w.to_lower().strip_edges()
	# Mapeo de sinónimos a token canonical
	var map := {
		# A: Macana Maya (educativamente inútil en este combate)
		"weapon_a": [
			"weapon_a", "inutil", "inútil", "macana", "macana maya"
		],
		# B: Jícara (parcial: solo perros). Mantener "honda" como alias legado para compatibilidad, pero no usar en UI.
		"weapon_b": [
			"weapon_b", "jicara", "jícara", "jicara pintada", "jícara pintada", "honda", "honda yucateca"
		],
		# C: Lanza con Obsidiana (correcta). Mantener alias de "bastón de chechén" por compatibilidad.
		"weapon_c": [
			"weapon_c", "correcta", "lanza", "lanza con obsidiana", "lanza obsidiana", "obsidiana",
			"baston", "bastón", "baston de chechén", "bastón de chechén", "baston de chechen"
		]
	}
	for key in map.keys():
		for alias in map[key]:
			if w == alias:
				return key
	# Fallback: si contiene 'weapon_' devolver tal cual, sino asumir weapon_a
	if w.begins_with("weapon_"):
		return w
	return "weapon_a"

# ----- Métodos de ataque -----
func _on_attack_pressed() -> void:
	# Solo aceptar ataques en fases de combate
	if current_phase != "dogs" and current_phase != "huaychivo":
		print("No se puede atacar en la fase actual: %s" % current_phase)
		return

	if processing_turn:
		print("DEBUG: Ya hay un turno en proceso, ignorando")
		return

	# Iniciar el turno
	processing_turn = true
	if btn_attack_dogs:
		btn_attack_dogs.disabled = true
	if btn_attack_huaychivo:
		btn_attack_huaychivo.disabled = true

	# --- Animación de golpe de Lele ---
	if player_instance:
		var anim_sprite = player_instance.get_node_or_null("AnimatedSprite2D")
		if anim_sprite and anim_sprite.sprite_frames and "Golpe" in anim_sprite.sprite_frames.get_animation_names():
			# Aplicar escala correctiva para la animación "Golpe"
			var corrective_scale_factor = 324.0 / 768.0 # idle_height / golpe_height
			anim_sprite.scale = original_player_sprite_scale * corrective_scale_factor
			anim_sprite.play("Golpe")
			get_tree().create_timer(RETURN_TO_IDLE_DELAY).timeout.connect(_return_player_to_idle)

	# Movimiento del arma hacia adelante (empuje) sincronizado con el ataque
	_play_weapon_attack_motion()

	# Lanzar minijuego según fase. Si falla, se usará fallback en start_minigame.
	if current_phase == "dogs":
		if not dogs_tutorial_shown:
			if tutorial_overlay and timedhit_tutorial:
				tutorial_overlay.visible = true
				timedhit_tutorial.visible = true
				return
		start_minigame("timed_hit")
	elif current_phase == "huaychivo":
		start_minigame("simon")
	else:
		_execute_combat_turn()
	return

# Animación simple del arma: pequeño empuje hacia adelante y regreso
func _play_weapon_attack_motion() -> void:
	if player_weapon == null:
		return
	# Cancelar tween previo si sigue corriendo para evitar acumulación
	if weapon_tween and weapon_tween.is_running():
		weapon_tween.kill()

	var w := _normalize_weapon(selected_weapon)
	var forward_offset := Vector2(-22, -4)
	var extra_rot := -8.0
	if w == "weapon_b":
		# Jícara: empuje más corto y un pelín hacia arriba
		forward_offset = Vector2(-14, -6)
		extra_rot = -4.0

	# Asegurar valores base por si el arma se creó hace poco
	weapon_idle_position = player_weapon.position
	weapon_idle_rotation = player_weapon.rotation_degrees

	# Tween de avance
	weapon_tween = create_tween()
	weapon_tween.set_parallel(true)
	weapon_tween.tween_property(player_weapon, "position", weapon_idle_position + forward_offset, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	weapon_tween.tween_property(player_weapon, "rotation_degrees", weapon_idle_rotation + extra_rot, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# Al terminar el avance, lanzar regreso en un nuevo tween (secuencial)
	weapon_tween.finished.connect(func():
		if not player_weapon:
			return
		var back = create_tween()
		back.set_parallel(true)
		back.tween_property(player_weapon, "position", weapon_idle_position, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		back.tween_property(player_weapon, "rotation_degrees", weapon_idle_rotation, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		back.finished.connect(func():
			if player_weapon:
				player_weapon.position = weapon_idle_position
				player_weapon.rotation_degrees = weapon_idle_rotation
		)
	)

func start_minigame(type: String) -> void:
	if minigame_running:
		return
	var scene_path := ""
	if type == "timed_hit":
		scene_path = "res://Minigames/TimedHit/TimedHit.tscn"
	elif type == "simon":
		scene_path = "res://Minigames/Simon/Simon.tscn"
	if scene_path == "" or not FileAccess.file_exists(scene_path):
		print("ADVERTENCIA: minijuego no disponible:", type)
		_execute_combat_turn() # fallback al flujo lineal
		return
	var Packed = load(scene_path)
	if not Packed:
		print("ADVERTENCIA: error al cargar minijuego", scene_path)
		_execute_combat_turn()
		return
	active_minigame = Packed.instantiate()
	minigame_running = true
	if type == "timed_hit":
		dog_press_hits = 0
		dog_minigame_active = true
	if canvas:
		canvas.add_child(active_minigame)
	else:
		add_child(active_minigame)
	if active_minigame is Control:
		var cm := active_minigame as Control
		cm.anchor_left = 0.0
		cm.anchor_top = 0.0
		cm.anchor_right = 1.0
		cm.anchor_bottom = 1.0
		cm.offset_left = 0.0
		cm.offset_top = 0.0
		cm.offset_right = 0.0
		cm.offset_bottom = 0.0
	else:
		if active_minigame is Node2D:
			var n2 := active_minigame as Node2D
			var center := get_viewport().get_visible_rect().size * 0.5
			n2.global_position = center
	if active_minigame.has_signal("finished"):
		active_minigame.connect("finished", Callable(self, "_on_minigame_finished"))
	# Conectar intentos de golpe del minijuego de perros para animar estocada
	if current_phase == "dogs" and active_minigame.has_signal("hit_pressed"):
		active_minigame.connect("hit_pressed", Callable(self, "_on_timedhit_attempt"))
	var difficulty := (2 if current_phase == "huaychivo" else 1)
	if active_minigame.has_method("start"):
		var attempts := (5 if current_phase == "huaychivo" else 3)
		var rounds := (3 if type == "simon" else 1)
		active_minigame.start({
			"phase": current_phase,
			"difficulty": difficulty,
			"duration": 6.0,
			"attempts": attempts,
			"rounds": rounds
		})

func _on_minigame_finished(_success: bool, score: int) -> void:
	if active_minigame and is_instance_valid(active_minigame):
		active_minigame.queue_free()
	active_minigame = null
	minigame_running = false
	if practice_active:
		practice_active = false
		if pending_minigame_type != "":
			start_minigame(pending_minigame_type)
			pending_minigame_type = ""
		return
	if not _success:
		pass

	var wnorm := _normalize_weapon(selected_weapon)
	var target := ("huaychivo" if current_phase == "huaychivo" else "dog")

	var dmg := 0
	if target == "dog":
		# Daño a perros se aplicó por intento (arma C) o se evalúa por tokens (arma A)
		if wnorm == "weapon_a":
			# Si en este ataque lograste 3 aciertos, ganas un token; con 2 tokens, muere 1 perro
			if dog_press_hits >= 3:
				macana_tokens += 1
				print("DEBUG: Macana -> press_hits=", dog_press_hits, ", tokens=", macana_tokens)
				if macana_tokens >= 2:
					var idx_kill := _dog_target_index()
					if idx_kill != -1:
						dogs_health[idx_kill] = 0
						dogs_alive[idx_kill] = false
						await _dog_on_death(idx_kill)
						update_health_ui()
						macana_tokens = 0
			else:
				print("DEBUG: Macana -> sin token (hits=", dog_press_hits, ")")
		elif wnorm == "weapon_c":
			# Salvaguarda: si por timing no se aplicó el 3er daño, forzar muerte si hubo 3 aciertos
			if dog_press_hits >= 3:
				var idx_kill2 := _dog_target_index()
				if idx_kill2 != -1 and dogs_alive[idx_kill2] and dogs_health[idx_kill2] > 0:
					dogs_health[idx_kill2] = 0
					dogs_alive[idx_kill2] = false
					await _dog_on_death(idx_kill2)
					update_health_ui()
		print("DEBUG: minigame end (dogs) -> weapon=", wnorm, ", press_hits=", dog_press_hits)
	else:
		# Huaychivo: daño por score total del minijuego
		dmg = compute_damage_from_score(score, target)
		dmg = _apply_weapon_rules(dmg, target)
		if wnorm == "weapon_c" and dmg == 0 and score > 0:
			dmg = 1
		print("DEBUG: minigame end (huaychivo) -> weapon=", wnorm, ", score=", score, ", dmg=", dmg)

	if dmg > 0:
		if target == "dog":
			# Ya aplicado por intento
			pass
		else:
			huaychivo_health = max(0, huaychivo_health - dmg)
			if huaychivo_health <= 0:
				if huaychivo:
					huaychivo.hide()
				set_phase("victory")
				return
	else:
		if target == "dog":
			# Si no hubo aciertos en los intentos, contraataca
			if dog_press_hits <= 0:
				var idx := _dog_target_index()
				if idx != -1:
					await _dog_counterattack(idx)
		else:
			# Mensaje educativo si el arma impide daño en Huaychivo
			var msg := _weapon_rule_message(target)
			if msg != "":
				await _show_temporary_message(msg, 2.4)

	update_health_ui()

	var transitioned_to_huaychivo := false
	if current_phase == "dogs":
		# Reset per-press tracker al finalizar el minijuego
		dog_press_hits = 0
		dog_minigame_active = false
		var any_dog_alive := false
		for is_alive in dogs_alive:
			if is_alive:
				any_dog_alive = true
				break
		if not any_dog_alive:
			# Ocultar botón de perros de inmediato para evitar confusión
			if btn_attack_dogs:
				btn_attack_dogs.visible = false
			await _show_temporary_message("¡Todos los perros derrotados! Ahora enfrenta al Huaychivo", DIALOG_AUTO_ADVANCE_TIME)
			set_phase("huaychivo")
			transitioned_to_huaychivo = true
		else:
			# Reanudar bobbing del nuevo perro en turno
			_refresh_dog_agro_loops()

	# Retaliación fija por arma en cada turno, a menos que hayamos transicionado este mismo turno
	var _did_retaliate := false
	if not transitioned_to_huaychivo:
		await _enemy_retaliation()
		_did_retaliate = true

	# Cierre del turno: reactivar UI siempre, haya o no retaliación
	processing_turn = false
	if btn_attack_dogs:
		btn_attack_dogs.disabled = false
	if btn_attack_huaychivo:
		btn_attack_huaychivo.disabled = false

# Reaccionar a cada intento de golpe en TimedHit
func _on_timedhit_attempt(score: int) -> void:
	_play_player_attack_anim()
	_play_weapon_attack_motion()
	var idx: int = _dog_target_index()
	if idx == -1:
		return

	var wnorm := _normalize_weapon(selected_weapon)
	var per_press_dmg := 0

	# Arma C (Lanza con Obsidiana): cada acierto resta 1 de vida (3 aciertos -> muere el perro)
	# Arma A (Macana): no hace daño por golpe; se evalúa por tokens al final del minijuego
	if score > 0:
		dog_press_hits += 1
		if wnorm == "weapon_c" or wnorm == "weapon_b":
			per_press_dmg = 1

	print("DEBUG: timedhit_attempt -> idx=%d, score=%d, dmg=%d, weapon=%s, health=%d" % [idx, score, per_press_dmg, wnorm, dogs_health[idx]])

	if per_press_dmg > 0:
		dogs_health[idx] = max(0, dogs_health[idx] - per_press_dmg)
		if dogs_health[idx] <= 0:
			await _dog_on_death(idx)
			dogs_alive[idx] = false
			update_health_ui()
			# Si ya no quedan perros, transicionar inmediatamente a Huaychivo
			var any_dog_left := false
			for a in dogs_alive:
				if a:
					any_dog_left = true
					break
			if not any_dog_left:
				if btn_attack_dogs:
					btn_attack_dogs.visible = false
				# Mensaje breve y cambio de fase directo
				await _show_temporary_message("¡Todos los perros derrotados! Ahora enfrenta al Huaychivo", DIALOG_AUTO_ADVANCE_TIME)
				set_phase("huaychivo")
				# Cancelar minijuego si sigue activo
				if active_minigame and active_minigame.has_method("cancel"):
					dog_minigame_active = false
					active_minigame.cancel()
				return
			# Si murió el perro, terminar el minijuego anticipadamente
			if active_minigame and active_minigame.has_method("cancel"):
				dog_minigame_active = false
				active_minigame.cancel()
			return
		else:
			await _dog_on_hit(idx)
			update_health_ui()
			return
	# Sin daño, solo preact visual
	await _dog_preact(idx)

# Reproducir animación de ataque del jugador (Golpe)
func _play_player_attack_anim() -> void:
	if not player_instance:
		return
	var anim_sprite = player_instance.get_node_or_null("AnimatedSprite2D")
	if anim_sprite and anim_sprite.sprite_frames and "Golpe" in anim_sprite.sprite_frames.get_animation_names():
		var corrective_scale_factor = 324.0 / 768.0
		anim_sprite.scale = original_player_sprite_scale * corrective_scale_factor
		anim_sprite.play("Golpe")
		get_tree().create_timer(RETURN_TO_IDLE_DELAY).timeout.connect(_return_player_to_idle)

# ------------------------
# Helpers de movimiento de perros
# ------------------------
func _dog_target_index() -> int:
	for i in range(dogs_alive.size()):
		if dogs_alive[i]:
			return i
	return -1

func _get_dog_node(idx: int) -> Node2D:
	match idx:
		0:
			return nahual1
		1:
			return nahual2
		2:
			return nahual3
		_:
			return null

func _dog_cancel_tween(idx: int) -> void:
	if idx < 0 or idx >= dog_tweens.size():
		return
	var tw: Tween = dog_tweens[idx]
	if tw and tw.is_running():
		tw.kill()
	dog_tweens[idx] = null

# ---------- Bobbing (avance/retroceso) continuo del perro en turno ----------
func _is_dog_alive(idx: int) -> bool:
	if idx < 0 or idx >= dogs_alive.size():
		return false
	return dogs_alive[idx] and _get_dog_node(idx) != null

func _stop_dog_bob_loop(idx: int) -> void:
	if idx < 0 or idx >= dog_bob_tweens.size():
		return
	var t: Tween = dog_bob_tweens[idx]
	if t and t.is_running():
		t.kill()
	dog_bob_tweens[idx] = null

func _stop_all_dog_bob_loops() -> void:
	for i in range(3):
		_stop_dog_bob_loop(i)

func _run_dog_bob_cycle(idx: int) -> void:
	if not _is_dog_alive(idx):
		_stop_dog_bob_loop(idx)
		return
	if current_phase != "dogs" or dog_busy[idx]:
		_stop_dog_bob_loop(idx)
		return
	var dog = _get_dog_node(idx)
	if not dog:
		return
	# Asegurar base
	if dog_bob_base_pos[idx] == Vector2.ZERO:
		dog_bob_base_pos[idx] = dog.position
	var base_pos: Vector2 = dog_bob_base_pos[idx]
	# Vaivén más marcado (amenaza) hacia el frente y regreso
	var forward := Vector2(-14, 0)
	var t1 = create_tween()
	t1.set_parallel(true)
	t1.tween_property(dog, "position", base_pos + forward, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t1.tween_property(dog, "rotation_degrees", -3.0, 0.16)
	await t1.finished
	if not _is_dog_alive(idx) or current_phase != "dogs" or dog_busy[idx]:
		_stop_dog_bob_loop(idx)
		return
	var t2 = create_tween()
	t2.set_parallel(true)
	t2.tween_property(dog, "position", base_pos, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	t2.tween_property(dog, "rotation_degrees", 0.0, 0.18)
	dog_bob_tweens[idx] = t2
	await t2.finished
	# Loop solo si siguen las condiciones
	if _is_dog_alive(idx) and current_phase == "dogs" and not dog_busy[idx]:
		_run_dog_bob_cycle(idx)
	else:
		_stop_dog_bob_loop(idx)

func _start_dog_agro_loop(idx: int) -> void:
	if not _is_dog_alive(idx):
		return
	# Registrar base actual
	var dog = _get_dog_node(idx)
	if dog:
		dog_bob_base_pos[idx] = dog.position
	_stop_dog_bob_loop(idx)
	_run_dog_bob_cycle(idx)

func _refresh_dog_agro_loops() -> void:
	# Solo el perro objetivo debe bobbear
	_stop_all_dog_bob_loops()
	if current_phase != "dogs" or minigame_running:
		return
	var idx := _dog_target_index()
	if idx != -1:
		_start_dog_agro_loop(idx)

func _dog_reset_pose(idx: int) -> void:
	var dog = _get_dog_node(idx)
	if not dog:
		return
	# Mantener la posición actual; solo resetear rotación y color
	if dog.has_method("set_rotation_degrees"):
		dog.rotation_degrees = 0.0
	var sprite_child := dog.get_node_or_null("Sprite2D")
	if sprite_child:
		sprite_child.modulate = Color(1, 1, 1, 1)
	else:
		dog.modulate = Color(1, 1, 1, 1)

func _dog_preact(idx: int) -> void:
	var dog = _get_dog_node(idx)
	if not dog or dog_busy[idx]:
		return
	_stop_dog_bob_loop(idx)
	_dog_cancel_tween(idx)
	var forward := Vector2(-8, -2)
	var base_pos: Vector2 = dog.position
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(dog, "position", base_pos + forward, 0.06).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(dog, "rotation_degrees", -2.0, 0.06)
	dog_tweens[idx] = tw
	await tw.finished
	var back = create_tween()
	back.set_parallel(true)
	back.tween_property(dog, "position", base_pos, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	back.tween_property(dog, "rotation_degrees", 0.0, 0.08)
	await back.finished
	_dog_reset_pose(idx)
	_maybe_resume_bob(idx)

func _dog_on_hit(idx: int) -> void:
	var dog = _get_dog_node(idx)
	if not dog:
		return
	_stop_dog_bob_loop(idx)
	_dog_cancel_tween(idx)
	var base_pos: Vector2 = dog.position
	var sprite_child := dog.get_node_or_null("Sprite2D")
	if sprite_child:
		sprite_child.modulate = DOG_HIT_TINT
	else:
		dog.modulate = DOG_HIT_TINT
	var back := Vector2(-12, 0)
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(dog, "position", base_pos + back, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(dog, "rotation_degrees", 3.0, 0.08)
	dog_tweens[idx] = tw
	await tw.finished
	var tw2 = create_tween()
	tw2.set_parallel(true)
	tw2.tween_property(dog, "position", base_pos, 0.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw2.tween_property(dog, "rotation_degrees", 0.0, 0.10)
	await tw2.finished
	if sprite_child:
		sprite_child.modulate = Color(1, 1, 1, 1)
	else:
		dog.modulate = Color(1, 1, 1, 1)
	_maybe_resume_bob(idx)

func _dog_on_death(idx: int) -> void:
	var dog = _get_dog_node(idx)
	if not dog:
		return
	_stop_dog_bob_loop(idx)
	_dog_cancel_tween(idx)
	var base_pos: Vector2 = dog.position
	var away := Vector2(DOG_KNOCKBACK_DIST, 0)
	var sprite_child := dog.get_node_or_null("Sprite2D")
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(dog, "position", base_pos + away, DOG_KNOCKBACK_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(dog, "rotation_degrees", 6.0, DOG_KNOCKBACK_TIME)
	await tw.finished
	var twf = create_tween()
	if sprite_child:
		twf.tween_property(sprite_child, "modulate:a", 0.0, DOG_FADE_TIME)
	else:
		twf.tween_property(dog, "modulate:a", 0.0, DOG_FADE_TIME)
	await twf.finished
	_play_death_effect_at(dog.global_position)
	dog.hide()

func _dog_counterattack(idx: int) -> void:
	var dog = _get_dog_node(idx)
	if not dog:
		return
	_stop_dog_bob_loop(idx)
	_dog_cancel_tween(idx)
	var base_pos: Vector2 = dog.position
	var forward := Vector2(-DOG_LUNGE_DIST, 0)
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(dog, "position", base_pos + forward, DOG_LUNGE_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(dog, "rotation_degrees", -4.0, DOG_LUNGE_TIME)
	await tw.finished
	var tw2 = create_tween()
	tw2.set_parallel(true)
	tw2.tween_property(dog, "position", base_pos, DOG_RETURN_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw2.tween_property(dog, "rotation_degrees", 0.0, DOG_RETURN_TIME)
	await tw2.finished
	_dog_reset_pose(idx)
	_maybe_resume_bob(idx)

func _maybe_resume_bob(idx: int) -> void:
	if current_phase == "dogs" and not minigame_running and _is_dog_alive(idx):
		_start_dog_agro_loop(idx)

func compute_damage_from_score(score: int, target_type: String) -> int:
	var s: int = int(clamp(score, 0, 100))
	# Perros: permitir matar con un buen minijuego (hasta 2 de daño), o 1 con acierto medio.
	if target_type == "dog":
		if s < 40:
			return 0
		elif s < 70:
			return 1
		else:
			return 2
	# Huaychivo: mantener escala completa.
	if s < 40:
		return 0
	elif s < 70:
		return 1
	elif s < 90:
		return 2
	else:
		return 3

func _apply_weapon_rules(base_damage: int, target_type: String) -> int:
	# Reglas robustas y consistentes:
	# - weapon_a: 0 daño a todos
	# - weapon_b: 0 daño a todos (Jícara no progresa)
	# - weapon_c: daño a todos (según desempeño del minijuego). Si haces mal el minijuego, no haces daño.
	var w := _normalize_weapon(selected_weapon)
	if w == "weapon_a":
		return 0
	if w == "weapon_b":
		return (base_damage if target_type == "dog" else 0)
	if w == "weapon_c":
		# Sin privilegios especiales: requiere buen desempeño para hacer daño
		return base_damage
	return 0

func _weapon_rule_message(target_type: String) -> String:
	var w := _normalize_weapon(selected_weapon)
	if w == "weapon_a":
		# Ya no mostramos diálogo para el arma que no causa daño; mantenemos el comportamiento sin daño en silencio.
		return ""
	if w == "weapon_b" and target_type == "huaychivo":
		return "Esta arma no afecta al Huaychivo. Considera otra opción."
	return ""

func _execute_combat_turn() -> void:
	# Lógica de ataque a los perros
	var dog_to_attack_idx: int = -1
	for i in range(dogs_alive.size()):
		if dogs_alive[i]:
			dog_to_attack_idx = i
			break

	if dog_to_attack_idx != -1:
		var dmg = _get_damage_for("dog")
		dogs_health[dog_to_attack_idx] -= dmg
		if dogs_health[dog_to_attack_idx] < 0:
			dogs_health[dog_to_attack_idx] = 0

		print("Perro %d golpeado, daño: %d, vida restante: %d" % [dog_to_attack_idx + 1, dmg, dogs_health[dog_to_attack_idx]])

		if dogs_health[dog_to_attack_idx] <= 0:
			dogs_alive[dog_to_attack_idx] = false
			var dog_node = get_node_or_null("Characters/Dogs/nahual%d" % (dog_to_attack_idx + 1))
			if dog_node:
				dog_node.hide()
				_play_death_effect_at(dog_node.global_position)

		update_health_ui()
		await _delay(POST_HIT_DELAY)
		await _enemy_retaliation()

		# Verificar si quedan perros
		var any_dog_alive = false
		for is_alive in dogs_alive:
			if is_alive:
				any_dog_alive = true
				break

		if not any_dog_alive:
			print("DEBUG: Todos los perros han sido derrotados")
			await _show_temporary_message("¡Todos los perros derrotados! Ahora enfrenta al Huaychivo", DIALOG_AUTO_ADVANCE_TIME)
			set_phase("huaychivo")
			if btn_attack_dogs:
				btn_attack_dogs.text = "Atacar Huaychivo"

	# Lógica de ataque al Huaychivo (solo si no quedan perros)
	elif current_phase == "huaychivo":
		var dmg_h = _get_damage_for("huaychivo")
		huaychivo_health -= dmg_h
		print("HuayChivo golpeado, daño: %d, vida restante: %d" % [dmg_h, huaychivo_health])

		if huaychivo:
			_play_death_effect_at(huaychivo.global_position)

		update_health_ui()

		if huaychivo_health <= 0:
			print("DEBUG: ¡Victoria! Huaychivo derrotado.")
			if huaychivo:
				huaychivo.hide()
			set_phase("victory")
			# No reactivar el botón ni el turno, el juego termina
			return

		await _delay(POST_HIT_DELAY)
		await _enemy_retaliation()

	# Fin del turno: reactivar controles si el combate continúa
	if current_phase == "dogs" or current_phase == "huaychivo":
		processing_turn = false
		if btn_attack_dogs:
			btn_attack_dogs.disabled = false


func update_health_ui() -> void:
	# Actualiza la visibilidad de los corazones en la UI según player_health
	player_health = clamp(player_health, 0, 6)
	for i in range(6):
		var heart_name := "Heart%d" % (i + 1)
		if healthbar and healthbar.has_node(heart_name):
			var heart := healthbar.get_node(heart_name)
			if heart:
				heart.visible = (i < player_health)

	# Actualizar barra de vida general de enemigos
	if general_enemy_healthbar:
		var max_total := 3 * 3 + 5
		general_enemy_healthbar.max_value = max_total
		var total := 0
		for i in range(3):
			if dogs_alive[i]:
				total += dogs_health[i]
		if huaychivo and huaychivo.visible:
			total += huaychivo_health
		general_enemy_healthbar.value = total


# Reproduce el efecto de muerte (particles) en una posición global y lo detiene tras un corto tiempo
func _play_death_effect_at(global_pos: Vector2) -> void:
	if death_effect == null:
		return
	death_effect.global_position = global_pos
	death_effect.emitting = true
	# apagar tras un breve lapso
	await _delay(0.6)
	death_effect.emitting = false


func _get_huaychivo_max_hp() -> int:
	# Mantener un único sitio para el HP máximo del HuayChivo
	return 5


func _create_tutorial_overlay() -> void:
	tutorial_overlay = Panel.new()
	if canvas:
		canvas.add_child(tutorial_overlay)
	else:
		add_child(tutorial_overlay)
	tutorial_overlay.anchor_left = 0.0
	tutorial_overlay.anchor_top = 0.0
	tutorial_overlay.anchor_right = 1.0
	tutorial_overlay.anchor_bottom = 1.0
	tutorial_overlay.offset_left = 0.0
	tutorial_overlay.offset_top = 0.0
	tutorial_overlay.offset_right = 0.0
	tutorial_overlay.offset_bottom = 0.0
	tutorial_overlay.visible = false
	tutorial_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var overlay_bg := StyleBoxFlat.new()
	overlay_bg.bg_color = Color(0, 0, 0, 0.55)
	tutorial_overlay.add_theme_stylebox_override("panel", overlay_bg)
	timedhit_tutorial = Panel.new()
	tutorial_overlay.add_child(timedhit_tutorial)
	timedhit_tutorial.anchor_left = 0.2
	timedhit_tutorial.anchor_top = 0.2
	timedhit_tutorial.anchor_right = 0.8
	timedhit_tutorial.anchor_bottom = 0.8
	var th_title := Label.new()
	th_title.text = "Golpe Cronometrado"
	timedhit_tutorial.add_child(th_title)
	th_title.anchor_left = 0.0
	th_title.anchor_top = 0.0
	th_title.anchor_right = 1.0
	th_title.anchor_bottom = 0.2
	th_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	th_title.add_theme_font_size_override("font_size", 36)
	th_title.add_theme_color_override("font_color", Color(1, 1, 1))
	var th_desc := Label.new()
	th_desc.text = "Presiona cuando el indicador esté en la zona correcta. Completa 3 aciertos para dañar al enemigo."
	timedhit_tutorial.add_child(th_desc)
	th_desc.anchor_left = 0.05
	th_desc.anchor_top = 0.22
	th_desc.anchor_right = 0.95
	th_desc.anchor_bottom = 0.66
	th_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	th_desc.add_theme_font_size_override("font_size", 24)
	th_desc.add_theme_color_override("font_color", Color(1, 1, 1))
	th_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	var th_start := Button.new()
	th_start.text = "Comenzar"
	timedhit_tutorial.add_child(th_start)
	th_start.anchor_left = 0.37
	th_start.anchor_top = 0.72
	th_start.anchor_right = 0.63
	th_start.anchor_bottom = 0.86
	th_start.custom_minimum_size = Vector2(260, 64)
	th_start.add_theme_font_size_override("font_size", 24)
	var th_style := StyleBoxFlat.new()
	th_style.bg_color = Color(0.2, 0.6, 1.0, 1.0)
	th_style.border_color = Color(1, 1, 1, 1)
	th_style.border_width_top = 2
	th_style.border_width_left = 2
	th_style.border_width_bottom = 2
	th_style.border_width_right = 2
	var th_style_hover := th_style.duplicate()
	th_style_hover.bg_color = Color(0.3, 0.7, 1.0, 1.0)
	var th_style_pressed := th_style.duplicate()
	th_style_pressed.bg_color = Color(0.1, 0.5, 0.9, 1.0)
	th_start.add_theme_stylebox_override("normal", th_style)
	th_start.add_theme_stylebox_override("hover", th_style_hover)
	th_start.add_theme_stylebox_override("pressed", th_style_pressed)
	th_start.pressed.connect(_on_timedhit_tutorial_start)
	timedhit_tutorial.visible = false
	simon_tutorial = Panel.new()
	tutorial_overlay.add_child(simon_tutorial)
	simon_tutorial.anchor_left = 0.2
	simon_tutorial.anchor_top = 0.2
	simon_tutorial.anchor_right = 0.8
	simon_tutorial.anchor_bottom = 0.8
	var si_title := Label.new()
	si_title.text = "Sigue la Secuencia"
	simon_tutorial.add_child(si_title)
	si_title.anchor_left = 0.0
	si_title.anchor_top = 0.0
	si_title.anchor_right = 1.0
	si_title.anchor_bottom = 0.2
	si_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	si_title.add_theme_font_size_override("font_size", 36)
	si_title.add_theme_color_override("font_color", Color(1, 1, 1))
	var si_desc := Label.new()
	si_desc.text = "Observa la secuencia y repítela en el mismo orden. Mejores aciertos, mayor daño."
	simon_tutorial.add_child(si_desc)
	si_desc.anchor_left = 0.05
	si_desc.anchor_top = 0.22
	si_desc.anchor_right = 0.95
	si_desc.anchor_bottom = 0.66
	si_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	si_desc.add_theme_font_size_override("font_size", 24)
	si_desc.add_theme_color_override("font_color", Color(1, 1, 1))
	si_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	var si_start := Button.new()
	si_start.text = "Comenzar"
	simon_tutorial.add_child(si_start)
	si_start.anchor_left = 0.37
	si_start.anchor_top = 0.72
	si_start.anchor_right = 0.63
	si_start.anchor_bottom = 0.86
	si_start.custom_minimum_size = Vector2(260, 64)
	si_start.add_theme_font_size_override("font_size", 24)
	var si_style := StyleBoxFlat.new()
	si_style.bg_color = Color(0.2, 0.6, 1.0, 1.0)
	si_style.border_color = Color(1, 1, 1, 1)
	si_style.border_width_top = 2
	si_style.border_width_left = 2
	si_style.border_width_bottom = 2
	si_style.border_width_right = 2
	var si_style_hover := si_style.duplicate()
	si_style_hover.bg_color = Color(0.3, 0.7, 1.0, 1.0)
	var si_style_pressed := si_style.duplicate()
	si_style_pressed.bg_color = Color(0.1, 0.5, 0.9, 1.0)
	si_start.add_theme_stylebox_override("normal", si_style)
	si_start.add_theme_stylebox_override("hover", si_style_hover)
	si_start.add_theme_stylebox_override("pressed", si_style_pressed)
	si_start.pressed.connect(_on_simon_tutorial_start)
	simon_tutorial.visible = false

func _on_timedhit_tutorial_start() -> void:
	tutorial_overlay.visible = false
	timedhit_tutorial.visible = false
	if not dogs_tutorial_shown:
		dogs_tutorial_shown = true
		practice_active = true
		pending_minigame_type = "timed_hit"
		start_minigame("timed_hit")

func _on_simon_tutorial_start() -> void:
	tutorial_overlay.visible = false
	simon_tutorial.visible = false
	if waiting_huaychivo_instructions:
		waiting_huaychivo_instructions = false
		practice_active = true
		pending_minigame_type = "simon"
		start_minigame("simon")


# Secuencias finales: victoria y derrota
func victory() -> void:
	# Nuevo flujo: Fade out a pantalla de victoria con imagen
	# Ocultar UI de combate
	if action_buttons:
		action_buttons.visible = false
	if btn_attack_dogs:
		btn_attack_dogs.disabled = true
	if btn_attack_huaychivo:
		btn_attack_huaychivo.disabled = true
	if dialog_box:
		dialog_box.visible = false
	if huaychivo_label:
		huaychivo_label.visible = false
	if personaje_label:
		personaje_label.visible = false

	# Crear overlay negro para fade-out
	var fade := ColorRect.new()
	fade.color = Color(0, 0, 0, 1)
	fade.modulate.a = 0.0
	# Anclar a pantalla completa
	if canvas:
		canvas.add_child(fade)
	else:
		add_child(fade)
	fade.anchor_left = 0.0
	fade.anchor_top = 0.0
	fade.anchor_right = 1.0
	fade.anchor_bottom = 1.0
	fade.offset_left = 0.0
	fade.offset_top = 0.0
	fade.offset_right = 0.0
	fade.offset_bottom = 0.0

	# 1) Fade a negro
	var tw = create_tween()
	tw.tween_property(fade, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw.finished

	# 2) Mostrar contenido de "Has ganado" (si existe la escena, incrustarla; si no, un label)
	var win_node: Node = null
	if FileAccess.file_exists("res://Scenes/WinScreen.tscn"):
		var win_packed: PackedScene = load("res://Scenes/WinScreen.tscn")
		if win_packed:
			win_node = win_packed.instantiate()
			if canvas:
				canvas.add_child(win_node)
			else:
				add_child(win_node)
	else:
		# Fallback simple: mostrar un Label centrado
		var lbl := Label.new()
		lbl.text = "¡HAS GANADO!"
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.anchor_left = 0
		lbl.anchor_top = 0
		lbl.anchor_right = 1
		lbl.anchor_bottom = 1
		lbl.offset_left = 0
		lbl.offset_top = 0
		lbl.offset_right = 0
		lbl.offset_bottom = 0
		lbl.add_theme_font_size_override("font_size", 48)
		lbl.add_theme_color_override("font_color", Color(1, 1, 1))
		if canvas:
			canvas.add_child(lbl)
		else:
			add_child(lbl)
		win_node = lbl

	# 3) Fade in desde negro para revelar "Has ganado"
	var tw_in = create_tween()
	tw_in.tween_property(fade, "modulate:a", 0.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw_in.finished

	# 4) Mantener unos segundos visible
	await _delay(2.8)

	# 5) Fade a negro otra vez
	var tw_out = create_tween()
	tw_out.tween_property(fade, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw_out.finished

	# 6) Cambiar a "Regreso a casa"
	var home_paths := [
		"res://Scenes/ReturnHome.tscn",
		"res://Scenes/RegresoCasa.tscn",
		"res://Scenes/Regreso_Hogar.tscn"
	]
	var target_home := ""
	for p in home_paths:
		if FileAccess.file_exists(p):
			target_home = p
			break
	if target_home != "":
		get_tree().change_scene_to_file(target_home)
	else:
		# Si no existe, permanecer en el win overlay y quitar el fade
		var tw_clear = create_tween()
		tw_clear.tween_property(fade, "modulate:a", 0.0, 0.4)

func defeat() -> void:
	# Nuevo flujo: Fade out a pantalla de "Try Again" con imagen
	# Ocultar UI de combate
	if action_buttons:
		action_buttons.visible = false
	if btn_attack_dogs:
		btn_attack_dogs.disabled = true
	if btn_attack_huaychivo:
		btn_attack_huaychivo.disabled = true
	if dialog_box:
		dialog_box.visible = false
	if huaychivo_label:
		huaychivo_label.visible = false
	if personaje_label:
		personaje_label.visible = false

	# Crear overlay negro para fade-out
	var fade := ColorRect.new()
	fade.color = Color(0, 0, 0, 1)
	fade.modulate.a = 0.0
	if canvas:
		canvas.add_child(fade)
	else:
		add_child(fade)
	fade.anchor_left = 0.0
	fade.anchor_top = 0.0
	fade.anchor_right = 1.0
	fade.anchor_bottom = 1.0
	fade.offset_left = 0.0
	fade.offset_top = 0.0
	fade.offset_right = 0.0
	fade.offset_bottom = 0.0

	# Tween de fade-out
	var tw = create_tween()
	tw.tween_property(fade, "modulate:a", 1.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw.finished

	# Cambiar a pantalla de reintento
	if FileAccess.file_exists("res://Scenes/TryAgain.tscn"):
		get_tree().change_scene_to_file("res://Scenes/TryAgain.tscn")
	else:
		# Fallback a selección de armas si no existe
		var selection_paths := [
			"res://Scenes/weapon_selection.tscn",
			"res://Scenes/Seleccion_Armas.tscn",
			"res://Seleccion_Armas.tscn"
		]
		for p in selection_paths:
			if FileAccess.file_exists(p):
				get_tree().change_scene_to_file(p)
				return

func _configure_collision_layers() -> void:
	# Asegurar que perros y HuayChivo estén en capas distintas para no interactuar entre ellos
	print("Configurando capas de colisión")
	# Perros ya están en capa 2 (ver _configure_dogs_collision). Aseguramos que HuayChivo
	# esté en otra capa (por ejemplo 4) y solo colisione con el jugador (capa 1).
	if huaychivo:
		# Si el nodo huaychivo es un CharacterBody2D, usarlo directamente
		if huaychivo is CharacterBody2D:
			huaychivo.collision_layer = 4
			huaychivo.collision_mask = 1
		else:
			# Buscar un CharacterBody2D hijo (por ejemplo: HuayChivo/CharacterBody2D)
			var child_body := huaychivo.get_node_or_null("CharacterBody2D")
			if child_body and child_body is CharacterBody2D:
				child_body.collision_layer = 4
				child_body.collision_mask = 1
			else:
				print("Advertencia: no se encontró CharacterBody2D para HuayChivo; capas no configuradas")
	else:
		print("Advertencia: huaychivo_body no encontrado, no se cambiaron sus capas")


## ----- Missing helper implementations added below -----

func _configure_dogs_collision() -> void:
	# Asegurar que los perros estén en la capa 2 y colisionen con el jugador (capa 1)
	for i in range(3):
		var path = "Characters/Dogs/nahual%d" % (i + 1)
		var node = get_node_or_null(path)
		if node:
			# si el nodo es CharacterBody2D o Area2D, ajustar capas
			if node is CharacterBody2D:
				node.collision_layer = 2
				node.collision_mask = 1
			else:
				# buscar Area2D hijo
				var area = node.get_node_or_null("Area2D")
				if area:
					area.collision_layer = 2
					area.collision_mask = 1
				else:
					print("Advertencia: no se encontró Area2D para %s" % path)

func _configure_dogs_properties() -> void:
	# Inicializar propiedades simples que otros scripts esperan (target_position_x, velocity)
	for n in [nahual1, nahual2, nahual3]:
		if n:
			if not ("target_position_x" in n):
				# usar set metaproperty si fuera necesario
				n.target_position_x = 0
			# asegurar que exista velocity
			if not ("velocity" in n):
				n.velocity = Vector2.ZERO

func can_damage_enemy(target_type: String) -> bool:
	# Devuelve si el arma seleccionada puede dañar al tipo indicado
	var dmg = _get_damage_for(target_type)
	return dmg > 0

func attack_dogs() -> void:
	# Lógica pública para que UI invoque atacar a perros
	# Redirige a la misma lógica que _on_attack_pressed cuando estamos en fase de perros
	if current_phase != "dogs":
		print("attack_dogs ignorado: fase actual = %s" % current_phase)
		return
	_on_attack_pressed()

func change_phase(new_phase: String) -> void:
	# Wrapper sencillo para cambiar fase desde otras escenas o botones
	set_phase(new_phase)


func _get_dialogues_for_weapon() -> Array:
	# Devuelve las líneas con prefijos HUAYCHIVO:/PERSONAJE: según arma (usando arma normalizada)
	var w := _normalize_weapon(selected_weapon if selected_weapon != "" else "weapon_c")
	if w == "weapon_a":
		return [
			"HUAYCHIVO: ¿Creías que podrías escapar de mí, pequeño intruso?",
			"PERSONAJE: Tengo el amuleto maya... ¡no te tengo miedo!",
			"HUAYCHIVO: Ese amuleto no te servirá si no eliges bien tu arma...",
			"HUAYCHIVO: ¡Mis perros, ataquen!"
		]
	elif w == "weapon_b":
		return [
			"HUAYCHIVO: ¿Creías que podrías escapar de mí, pequeño intruso?",
			"PERSONAJE: Tengo el amuleto maya... ¡no te tengo miedo!",
			"HUAYCHIVO: Esa jícara no me hará daño; quizá distraiga a mis perros, pero a mí no me afectará...",
			"HUAYCHIVO: ¡Mis perros, ataquen!"
		]
	else:
		# weapon_c por defecto (Lanza con Obsidiana)
		return [
			"HUAYCHIVO: ¿Creías que podrías escapar de mí, pequeño intruso?",
			"PERSONAJE: Tengo el amuleto maya... ¡y la lanza con obsidiana!",
			"HUAYCHIVO: ¡Esa lanza es poderosa... pero tendrás que usarla bien!",
			"HUAYCHIVO: ¡Mis perros, ataquen!"
		]

func play_dialog_intro() -> void:
	# Diálogo de la Fase 1 — primero explicaciones, luego diálogos de personajes (según arma)
	dialog_lines = [
		"Bienvenido a la batalla final.",
		"Presiona 'Atacar' para vencer a los enemigos",
		"Prepárate para la batalla final"
	]
	dialog_lines.append_array(_get_dialogues_for_weapon())
	current_dialog_index = 0
	# Mostrar la card y la caja de diálogo para explicaciones
	if dialog_card:
		dialog_card.visible = true
	if dialog_box:
		dialog_box.visible = true
	# Ocultar labels de personajes inicialmente
	if dialog_label:
		dialog_label.visible = false
	if huaychivo_label:
		huaychivo_label.visible = false
	if personaje_label:
		personaje_label.visible = false
	_show_current_dialog_line()

func _show_current_dialog_line() -> void:
	if current_dialog_index < dialog_lines.size():
		var line = dialog_lines[current_dialog_index]
		# Asegura que no queden etiquetas anteriores visibles para evitar efecto de "doble texto"
		_hide_all_dialog_texts()
		if line.begins_with("HUAYCHIVO:"):
			var text = line.substr(10).strip_edges() # Remove "HUAYCHIVO: "

			# Animación de entrada suave para el diálogo del Huaychivo
			huaychivo_label.text = text
			huaychivo_label.modulate.a = 0.0
			huaychivo_label.visible = true
			personaje_label.visible = false
			dialog_label.visible = false

			# Ocultar DialogBox para personajes (redundante, ya lo hace _hide_all_dialog_texts)
			if dialog_box:
				dialog_box.visible = false

			# Asegurar que el nombre del personaje (arriba) esté oculto cuando habla Huaychivo
			if personaje_name_label:
				personaje_name_label.visible = false

			# Fade in del label del Huaychivo
			var tween = create_tween()
			tween.tween_property(huaychivo_label, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

			# Auto-avanzar después de DIALOG_AUTO_ADVANCE_TIME si el jugador no interacciona
			var my_idx = current_dialog_index
			await _delay(DIALOG_AUTO_ADVANCE_TIME)
			if current_dialog_index == my_idx and not next_btn_cooldown:
				next_btn_cooldown = true
				current_dialog_index += 1
				_show_current_dialog_line()
				await _delay(0.1)
				next_btn_cooldown = false
		elif line.begins_with("PERSONAJE:"):
			var text = line.substr(10).strip_edges() # Remove "PERSONAJE: "
			var pname: String = _get_selected_character_name()

			# Texto del diálogo del personaje (sin prefijo de nombre)
			personaje_label.text = text
			personaje_label.modulate.a = 0.0
			personaje_label.visible = true
			huaychivo_label.visible = false
			dialog_label.visible = false

			# Ocultar DialogBox para personajes (redundante, ya lo hace _hide_all_dialog_texts)
			if dialog_box:
				dialog_box.visible = false

			# Actualizar el rótulo superior de nombre del personaje con el nombre seleccionado
			if personaje_name_label:
				if pname != "":
					personaje_name_label.text = pname
					personaje_name_label.visible = true
				else:
					# Si no hay nombre seleccionado, ocultar el rótulo para evitar textos genéricos
					personaje_name_label.visible = false

			# Fade in del label del Personaje
			var tween = create_tween()
			tween.tween_property(personaje_label, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

			# Auto-avanzar después de DIALOG_AUTO_ADVANCE_TIME si el jugador no interacciona
			var my_idx2 = current_dialog_index
			await _delay(DIALOG_AUTO_ADVANCE_TIME)
			if current_dialog_index == my_idx2 and not next_btn_cooldown:
				next_btn_cooldown = true
				current_dialog_index += 1
				_show_current_dialog_line()
				await _delay(0.1)
				next_btn_cooldown = false
		else:
			# Explicación: mostrar en dialog_label dentro de DialogBox con animación
			dialog_label.text = line
			dialog_label.modulate.a = 0.0
			dialog_label.visible = true
			huaychivo_label.visible = false
			personaje_label.visible = false

			# Mostrar DialogBox para explicaciones con animación
			if dialog_box:
				dialog_box.modulate.a = 0.0
				dialog_box.visible = true
				var tween = create_tween()
				tween.set_parallel(true)
				tween.tween_property(dialog_box, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE)
				tween.tween_property(dialog_label, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE)

			if dialog_card:
				dialog_card.visible = true

		dialog_next_btn.visible = true
	else:
		# Diálogo terminado: ocultar UI de diálogo con fade out y pasar a fase de perros
		var tween = create_tween()
		tween.set_parallel(true)

		if dialog_box:
			tween.tween_property(dialog_box, "modulate:a", 0.0, 0.3)
		if huaychivo_label and huaychivo_label.visible:
			tween.tween_property(huaychivo_label, "modulate:a", 0.0, 0.3)
		if personaje_label and personaje_label.visible:
			tween.tween_property(personaje_label, "modulate:a", 0.0, 0.3)

		await tween.finished

		if dialog_box:
			dialog_box.visible = false
		if dialog_next_btn:
			dialog_next_btn.visible = false
		if huaychivo_label:
			huaychivo_label.visible = false
		if personaje_label:
			personaje_label.visible = false
		if action_buttons:
			action_buttons.visible = true

		# Actualizar fase a 'dogs'
		set_phase("dogs")

func _on_dialog_next_pressed() -> void:
	# Si estamos mostrando instrucciones del Huaychivo, cerrar y habilitar acción
	if waiting_huaychivo_instructions:
		waiting_huaychivo_instructions = false
		if dialog_box:
			dialog_box.visible = false
		if dialog_next_btn:
			dialog_next_btn.visible = false
		if action_buttons:
			action_buttons.visible = true
		return
	if next_btn_cooldown:
		return
	next_btn_cooldown = true
	dialog_next_btn.disabled = true
	current_dialog_index += 1
	_show_current_dialog_line()
	await _delay(0.5) # cooldown de 0.5 segundos
	next_btn_cooldown = false
	dialog_next_btn.disabled = false
func _center_battle_ui() -> void:
	if action_buttons:
		action_buttons.anchor_left = 0.3
		action_buttons.anchor_right = 0.7
		action_buttons.anchor_top = 0.68
		action_buttons.anchor_bottom = 0.78
		action_buttons.offset_left = 0
		action_buttons.offset_right = 0
		action_buttons.offset_top = 0
		action_buttons.offset_bottom = 0
		if action_buttons is BoxContainer:
			(action_buttons as BoxContainer).alignment = BoxContainer.ALIGNMENT_CENTER
		if btn_attack_dogs:
			btn_attack_dogs.anchor_left = 0.36
			btn_attack_dogs.anchor_right = 0.48
			btn_attack_dogs.anchor_top = 0.68
			btn_attack_dogs.anchor_bottom = 0.74
			btn_attack_dogs.offset_left = 0
			btn_attack_dogs.offset_right = 0
			btn_attack_dogs.offset_top = 0
			btn_attack_dogs.offset_bottom = 0
			btn_attack_dogs.custom_minimum_size = Vector2(220, 52)
		if btn_attack_huaychivo:
			btn_attack_huaychivo.anchor_left = 0.56
			btn_attack_huaychivo.anchor_right = 0.68
			btn_attack_huaychivo.anchor_top = 0.72
			btn_attack_huaychivo.anchor_bottom = 0.78
			btn_attack_huaychivo.offset_left = 0
			btn_attack_huaychivo.offset_right = 0
			btn_attack_huaychivo.offset_top = 0
			btn_attack_huaychivo.offset_bottom = 0
			btn_attack_huaychivo.custom_minimum_size = Vector2(220, 52)
