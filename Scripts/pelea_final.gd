extends Node2D

# ----- Variables principales -----
var player_health: int = 6
var dogs_health: Array = [2, 2, 2] # cada perro requiere 2 golpes
var dogs_alive: Array = [true, true, true]
var huaychivo_health: int = 5
var current_phase: String = "dialog" # dialog -> dogs -> huaychivo -> victory/defeat

var selected_weapon: String = "" # viene de Global.selected_weapon
var processing_turn: bool = false # renombrado para evitar shadowing

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
@onready var dialog_next_btn: Button = $CanvasLayer/NextButton
@onready var dialog_card: Panel = $CanvasLayer/DialogBox/Card
var phase_label: Label = null

# Barra de vida general de enemigos
var general_enemy_healthbar: ProgressBar = null

# Barras de vida de enemigos
var dog_healthbars: Array[ProgressBar] = []
var huaychivo_healthbar: ProgressBar = null

# Effects
@onready var hit_flash: ColorRect = $Effects/HitFlash
@onready var death_effect: CPUParticles2D = $Effects/DeathEffect

# ----- Ready -----

func _ready() -> void:
	_initialize_scene()
	_spawn_general_enemy_healthbar()
	# Crear las barras individuales de enemigos en la UI
	_spawn_enemy_healthbars()
	start_intro_sequence()

func _spawn_general_enemy_healthbar() -> void:
	# Instanciar ProgressBar general y agregarla a la HUD
	# Intentamos no depender de recursos externos .tres que pueden no existir
	general_enemy_healthbar = ProgressBar.new()
	general_enemy_healthbar.min_value = 0
	general_enemy_healthbar.max_value = 11 # 2+2+2+5
	general_enemy_healthbar.value = 11
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

func _spawn_enemy_healthbars() -> void:
	# Instanciar ProgressBar para cada perro
	# No dependemos de un recurso externo; creamos barras dinámicamente
	dog_healthbars.clear()
	for i in range(3):
		var bar = ProgressBar.new()
		bar.min_value = 0
		bar.max_value = 2
		bar.value = dogs_health[i]
		# No confiar en percent_visible; mantener la barra visual y ajustar tamaño
		bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar.custom_minimum_size = Vector2(60, 10)
		# Posicionar sobre cada perro
		var dog = [nahual1, nahual2, nahual3][i]
		# Añadir las barras al CanvasLayer (HUD) para que sean Controls
		canvas.add_child(bar)
		# Posición por encima del perro (global)
		bar.global_position = dog.global_position + Vector2(0, -40)
		dog_healthbars.append(bar)

	# Instanciar ProgressBar para Huaychivo
	huaychivo_healthbar = ProgressBar.new()
	huaychivo_healthbar.min_value = 0
	huaychivo_healthbar.max_value = 5
	huaychivo_healthbar.value = huaychivo_health
	# Evitar uso de percent_visible por compatibilidad
	huaychivo_healthbar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	huaychivo_healthbar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	huaychivo_healthbar.custom_minimum_size = Vector2(80, 12)
	canvas.add_child(huaychivo_healthbar)
	huaychivo_healthbar.global_position = huaychivo.global_position + Vector2(0, -50)

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

	# --- PARA PRUEBAS ---
	# Descomenta la siguiente línea para forzar un arma específica.
	# selected_weapon = "weapon_c"

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
			new_btn.position = btn_attack_dogs.position + Vector2(140, 0)
			btn_attack_huaychivo = new_btn
			new_btn.connect("pressed", Callable(self, "_on_attack_pressed"))
	if dialog_next_btn:
		dialog_next_btn.connect("pressed", Callable(self, "_on_dialog_next_pressed"))

	# Configuración inicial de la UI
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

			# Flip horizontal para que el arma apunte hacia la izquierda (dirección del enemigo)
			player_weapon.flip_v = true

			# Buscar marker de mano
			var hand_marker = player_instance.get_node_or_null("Hand")
			if hand_marker:
				player_instance.add_child(player_weapon)
				player_weapon.position = hand_marker.position + Vector2(-10, -15)
			else:
				# Si no hay marker, poner en una posición relativa al personaje
				# Ajustada para que parezca que el personaje sostiene el arma
				player_instance.add_child(player_weapon)
				player_weapon.position = Vector2(-20, -10)

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
	elif current_phase == "victory" or current_phase == "defeat":
		# finales: ocultar controles de combate
		if action_buttons:
			action_buttons.visible = false
		if btn_attack_dogs:
			btn_attack_dogs.disabled = true
	# Ejecutar secuencias finales
	if current_phase == "victory":
		# pequeña pausa para mostrar estado y luego llamar a victory()
		await victory()
	elif current_phase == "defeat":
		await defeat()

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


# Mostrar un mensaje temporal en la caja de diálogo durante `duration` segundos con animación
func _show_temporary_message(text: String, duration: float = 1.4) -> void:
	if dialog_box and dialog_label:
		# Usar el dialog_label principal con animación suave
		dialog_label.text = text
		dialog_label.modulate.a = 0.0
		dialog_label.visible = true
		dialog_box.modulate.a = 0.0
		dialog_box.visible = true
		huaychivo_label.visible = false
		personaje_label.visible = false

		# Fade in
		var tween_in = create_tween()
		tween_in.set_parallel(true)
		tween_in.tween_property(dialog_box, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_SINE)
		tween_in.tween_property(dialog_label, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_SINE)

		await _delay(duration)

		# Fade out al terminar
		var tween_out = create_tween()
		tween_out.set_parallel(true)
		tween_out.tween_property(dialog_box, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_SINE)
		tween_out.tween_property(dialog_label, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_SINE)

		await tween_out.finished

	# Al terminar el mensaje, ocultar la caja si no estamos en dialog
	if current_phase != "dialog":
		if dialog_box:
			dialog_box.visible = false

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

# ----- Helpers -----
func _delay(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

# Calcular daño según arma y tipo de objetivo
func _get_damage_for(target: String) -> int:
	# Mapear exactamente según la especificación del diseño
	var w := selected_weapon if selected_weapon != "" else "inutil"
	# Normalizar cadenas simples
	w = w.to_lower()
	print("DEBUG: Calculando daño para target='%s' con arma='%s'" % [target, w])

	# Aceptar tokens del sistema global y sinónimos
	if w == "weapon_a" or w == "inutil" or w == " inútil" or w == "jicara" or w == "jícara" or w == "jícara decorativa" or w == "jicara decorativa":
		return 0 # Arma inútil - No causa daño a ningún enemigo
	elif w == "weapon_b" or w == "parcial" or w == "honda" or w == "honda yucateca":
		# Parcial: elimina perros (2 dmg) pero no daña al huaychivo
		return 2 if target == "dog" else 0
	elif w == "weapon_c" or w == "correcta" or w == "baston" or w == "bastón" or w == "baston de chechén" or w == "bastón de chechén" or w == "baston de chechen":
		# Correcta: daña ambos - única que puede matar al Huaychivo
		if target == "huaychivo":
			var damage = _get_huaychivo_max_hp()
			print("DEBUG: Daño letal para Huaychivo: %d" % damage)
			return damage # Golpe letal al Huaychivo
		return 2 # Daño normal a perros
	else:
		# Fallback razonable: sin daño a ninguno (comportamiento seguro)
		return 0

# Enemigos responden: un perro vivo ataca con daño menor; si ya no hay perros, HuayChivo ataca con daño mayor
func _enemy_retaliation() -> void:
	# Perros atacan juntos: daño acumulado = número de perros vivos
	var alive_count := 0
	for a in dogs_alive:
		if a:
			alive_count += 1

	if alive_count > 0:
		var pdmg = alive_count
		player_health -= pdmg
		print("Jugador recibe %d de daño por %d perro(s)" % [pdmg, alive_count])
		# Efecto de impacto
		hit_flash.visible = true
		await _delay(ENEMY_HIT_FLASH_DOGS)
		hit_flash.visible = false
		update_health_ui()
	else:
		# HuayChivo ataca con daño mayor
		var hdmg = 2
		player_health -= hdmg
		print("Jugador recibe %d de daño por HuayChivo" % hdmg)
		hit_flash.visible = true
		await _delay(ENEMY_HIT_FLASH_HUAYCHIVO)
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
		"weapon_a": ["weapon_a", "inutil", "jicara", "jícara", "jicara decorativa", "jícara decorativa"],
		"weapon_b": ["weapon_b", "parcial", "honda", "honda yucateca"],
		"weapon_c": ["weapon_c", "correcta", "baston", "bastón", "baston de chechén", "bastón de chechén", "baston de chechen"]
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

	# --- Animación de golpe de Lele ---
	if player_instance:
		var anim_sprite = player_instance.get_node_or_null("AnimatedSprite2D")
		if anim_sprite and anim_sprite.sprite_frames and "Golpe" in anim_sprite.sprite_frames.get_animation_names():
			# Aplicar escala correctiva para la animación "Golpe"
			var corrective_scale_factor = 324.0 / 768.0 # idle_height / golpe_height
			anim_sprite.scale = original_player_sprite_scale * corrective_scale_factor
			anim_sprite.play("Golpe")
			get_tree().create_timer(RETURN_TO_IDLE_DELAY).timeout.connect(_return_player_to_idle)

	# Ejecutar la lógica del turno de forma asíncrona
	_execute_combat_turn()

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
		# Asegurar max consistente
		var max_total := 2 * 3 + 5
		general_enemy_healthbar.max_value = max_total
		var total := 0
		for i in range(3):
			# Actualizar barras individuales si existen
			if i < dog_healthbars.size():
				var bar := dog_healthbars[i]
				if dogs_alive[i]:
					bar.visible = true
					bar.value = dogs_health[i]
				else:
					bar.visible = false
			# acumular para la barra general
			if dogs_alive[i]:
				total += dogs_health[i]
		# Huaychivo
		if huaychivo and huaychivo.visible:
			if huaychivo_healthbar:
				huaychivo_healthbar.visible = huaychivo_health > 0
				huaychivo_healthbar.value = huaychivo_health
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


# Secuencias finales: victoria y derrota
func victory() -> void:
	# Mostrar mensaje de victoria con animación épica
	if dialog_box and dialog_label:
		# Usar el dialog_label principal para mensaje de victoria
		dialog_label.text = "¡VICTORIA!\n\nHas derrotado al Huaychivo.\nEl bastón de chechén ha demostrado su poder sagrado.\n¡Puedes regresar a casa!"
		dialog_label.modulate.a = 0.0
		dialog_label.visible = true
		dialog_box.modulate.a = 0.0
		dialog_box.visible = true
		huaychivo_label.visible = false
		personaje_label.visible = false

		# Animación de entrada dramática
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(dialog_box, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		tween.tween_property(dialog_label, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		tween.tween_property(dialog_label, "scale", Vector2(1.1, 1.1), 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	# Esperar un poco antes de cambiar de escena
	await get_tree().create_timer(3.5).timeout

	# Ir a la escena de regreso a casa
	get_tree().change_scene_to_file("res://Scenes/ReturnHome.tscn")

func defeat() -> void:
	# Mostrar mensaje educativo de derrota según el arma elegida con animación
	if dialog_box and dialog_label:
		var defeat_message = ""

		# Personalizar mensaje según el arma elegida
		if selected_weapon == "weapon_a":
			defeat_message = "DERROTA\n\nLa jícara no es un arma.\nEs un recipiente ceremonial maya.\n\nNecesitas el bastón de chechén\npara vencer al Huaychivo."
		elif selected_weapon == "weapon_b":
			defeat_message = "DERROTA\n\nLa honda solo funciona\ncontra animales pequeños.\n\nNecesitas el bastón de chechén\npara vencer al Huaychivo."
		else:
			defeat_message = "DERROTA\n\nHas sido derrotado...\n\nIntenta de nuevo con\nel bastón de chechén."

		dialog_label.text = defeat_message
		dialog_label.modulate.a = 0.0
		dialog_label.visible = true
		dialog_box.modulate.a = 0.0
		dialog_box.visible = true
		huaychivo_label.visible = false
		personaje_label.visible = false

		# Animación de entrada
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(dialog_box, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)
		tween.tween_property(dialog_label, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)

	# Esperar 4 segundos antes de cambiar
	await _delay(4.0)

	# Ir a GameOver; su script hará la transición automática a la selección de armas.
	if FileAccess.file_exists("res://Scenes/GameOver.tscn"):
		get_tree().change_scene_to_file("res://Scenes/GameOver.tscn")
	else:
		# Fallback directo si GameOver no existe
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
	# Devuelve las líneas con prefijos HUAYCHIVO:/PERSONAJE: según arma
	var w := (selected_weapon if selected_weapon != "" else "weapon_c").to_lower()
	if w in ["weapon_a", "inutil", "jicara", "jícara", "jícara decorativa", "jicara decorativa"]:
		return [
			"HUAYCHIVO: ¿Creías que podrías escapar de mí, pequeño intruso?",
			"PERSONAJE: Tengo el amuleto maya... ¡no te tengo miedo!",
			"HUAYCHIVO: Ese amuleto no te servirá si no eliges bien tu arma...",
			"HUAYCHIVO: ¡Mis perros, ataquen!"
		]
	elif w in ["weapon_b", "parcial", "honda", "honda yucateca"]:
		return [
			"HUAYCHIVO: ¿Creías que podrías escapar de mí, pequeño intruso?",
			"PERSONAJE: Tengo el amuleto maya... ¡no te tengo miedo!",
			"HUAYCHIVO: Esa honda solo asusta a mis perros, pero a mí no me harás daño...",
			"HUAYCHIVO: ¡Mis perros, ataquen!"
		]
	else:
		# weapon_c por defecto
		return [
			"HUAYCHIVO: ¿Creías que podrías escapar de mí, pequeño intruso?",
			"PERSONAJE: Tengo el amuleto maya... ¡y el bastón de Chechén!",
			"HUAYCHIVO: ¡Ese bastón es poderoso... pero tendrás que usarlo bien!",
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
		if line.begins_with("HUAYCHIVO:"):
			var text = line.substr(10).strip_edges() # Remove "HUAYCHIVO: "

			# Animación de entrada suave para el diálogo del Huaychivo
			huaychivo_label.text = text
			huaychivo_label.modulate.a = 0.0
			huaychivo_label.visible = true
			personaje_label.visible = false
			dialog_label.visible = false

			# Ocultar DialogBox para personajes
			if dialog_box:
				dialog_box.visible = false

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

			# Animación de entrada suave para el diálogo del Personaje
			personaje_label.text = text
			personaje_label.modulate.a = 0.0
			personaje_label.visible = true
			huaychivo_label.visible = false
			dialog_label.visible = false

			# Ocultar DialogBox para personajes
			if dialog_box:
				dialog_box.visible = false

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
	if next_btn_cooldown:
		return
	next_btn_cooldown = true
	dialog_next_btn.disabled = true
	current_dialog_index += 1
	_show_current_dialog_line()
	await _delay(0.5) # cooldown de 0.5 segundos
	next_btn_cooldown = false
	dialog_next_btn.disabled = false
