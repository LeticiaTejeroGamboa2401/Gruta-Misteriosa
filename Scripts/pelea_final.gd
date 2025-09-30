extends Node2D

# ----- Variables principales -----
var player_health: int = 6
var dogs_health: Array = [2, 2, 2] # cada perro requiere 2 golpes
var dogs_alive: Array = [true, true, true]
var huaychivo_health: int = 5
var current_phase: String = "dialog" # dialog -> dogs -> huaychivo -> victory/defeat

var selected_weapon: String = "" # viene de Global.selected_weapon
var processing_turn: bool = false # renombrado para evitar shadowing
@export var test_selected_weapon: String = "weapon_c" # Para pruebas: si no está vacío, forza la arma seleccionada (ej: "correcta")

# ----- Variables para el sistema de diálogos -----
var dialog_lines: Array = []
var current_dialog_index: int = 0
var next_btn_cooldown: bool = false

# Referencia al personaje para controlar movimiento
var player_instance: Node2D = null
# Referencia al arma instanciada
var player_weapon: Node2D = null

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
@onready var btn_attack_huaychivo: Button = get_node_or_null("CanvasLayer/ActionButtons/AttackHuaychivo") # Fix incorrect path if needed
# Verificar path completo si el botón no se encuentra
@onready var dialog_box: Control = $CanvasLayer/DialogBox
@onready var dialog_label: Label = $CanvasLayer/DialogBox/Label
@onready var huaychivo_label: Label = $CanvasLayer/HuaychivoLabel
@onready var personaje_label: Label = $CanvasLayer/PersonajeLabel
@onready var dialog_next_btn: Button = $CanvasLayer/NextButton
@onready var dialog_card: ColorRect = $CanvasLayer/DialogBox/Card
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
	if Engine.has_singleton("Global") and Global.has_property("selected_weapon"):
		selected_weapon = Global.selected_weapon
	# Preferir variable de prueba si fue configurada en el inspector
	if test_selected_weapon != "":
		selected_weapon = test_selected_weapon
	if selected_weapon == "":
		selected_weapon = "inutil"

	# Normalizar el token del arma a "weapon_a|weapon_b|weapon_c" para evitar variantes
	selected_weapon = _normalize_weapon(selected_weapon)


	# Single attack button flow: use AttackDogs as the single attack button and hide the Huaychivo-specific button
	# Conectar señales usando Callable para compatibilidad
	if btn_attack_dogs:
		btn_attack_dogs.connect("pressed", Callable(self, "_on_attack_pressed"))
	# Conectar el botón de atacar HuayChivo a la misma lógica unificada
	if btn_attack_huaychivo:
		# Conectarlo al handler unificado
		if not btn_attack_huaychivo.is_connected("pressed", Callable(self, "_on_attack_pressed")):
			btn_attack_huaychivo.connect("pressed", Callable(self, "_on_attack_pressed"))
		# Solo se mostrará cuando sea relevante (fase huaychivo)
	if dialog_next_btn:
		dialog_next_btn.connect("pressed", Callable(self, "_on_dialog_next_pressed"))
	# Ocultar el botón Next al iniciar la escena
	dialog_next_btn.visible = false
	# Mantener la card oculta hasta que empiecen los diálogos
	if dialog_card:
		dialog_card.visible = false
	# Ocultar botones de ataque hasta que terminen los diálogos
	if action_buttons:
		action_buttons.visible = false

	# Ocultar los labels de personajes inicialmente
	if huaychivo_label:
		huaychivo_label.visible = false
	if personaje_label:
		personaje_label.visible = false

	# Mejorar la legibilidad del label de diálogo: usar autowrap inteligente y tamaño
	if dialog_label:
		# Preferir el modo de autowrap del TextServer (como hace DialogBox.gd) cuando esté disponible
		if Engine.has_singleton("TextServer"):
			dialog_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

		# Intentar aumentar fuente si hay una fuente en el Theme (get_theme_font) o evitar tocar la fuente
		var f = null
		if dialog_label.has_method("get_theme_font"):
			f = dialog_label.get_theme_font("font")
		# Si encontramos un font tipo DynamicFont con size, ajustarlo; si no, aplicar fallback de escala
		if f and ("size" in f):
			var new_size = int(f.size * 1.4)
			if new_size < 18:
				new_size = 18
			f.size = new_size
			# Aplicar la fuente con la API disponible en esta versión de Godot
			if dialog_label.has_method("add_font_override"):
				dialog_label.add_font_override("font", f)
			elif dialog_label.has_method("add_theme_font_override"):
				dialog_label.add_theme_font_override("font", f)
			elif dialog_label.has_method("add_theme_font"):
				dialog_label.add_theme_font("font", f)
			else:
				print("Aviso: no se pudo aplicar la fuente (método desconocido en esta versión de Godot).")
		else:
			# Intentar cargar directamente la TTF importada y asignarla al Theme del Label.
			var font_path := "res://font/Supermarket of Love.ttf"
			var font_res = null
			if FileAccess.file_exists(font_path):
				font_res = load(font_path)
			else:
				var alt := "res://font/Chonky Bunny.ttf"
				if FileAccess.file_exists(alt):
					font_res = load(alt)
			# Si cargamos algo, intentar aplicarlo (si el recurso soporta tamaño, no garantizado)
			if font_res:
				if "size" in font_res:
					font_res.size = 32
				# Aplicar la fuente con la API disponible
				if dialog_label.has_method("add_font_override"):
					dialog_label.add_font_override("font", font_res)
				elif dialog_label.has_method("add_theme_font_override"):
					dialog_label.add_theme_font_override("font", font_res)
				elif dialog_label.has_method("add_theme_font"):
					dialog_label.add_theme_font("font", font_res)
				else:
					print("Aviso: no se pudo aplicar la fuente a dialog_label; asigna un DynamicFont en el inspector.")
			else:
				print("Aviso: no se pudo cargar la fuente para dialog_label; asigna un DynamicFont en el inspector para ajustar tamaño.")

	update_health_ui()
	_spawn_player()
	hit_flash.visible = false
	_configure_dogs_collision()
	_configure_dogs_properties()
	_configure_collision_layers()

	# Evitar parpadeo: asegurarse de que el HuayChivo empiece invisible (alpha 0)
	if huaychivo:
		# Preferir el Sprite2D hijo si existe
		var sprite_child := huaychivo.get_node_or_null("Sprite2D")
		if sprite_child:
			sprite_child.modulate.a = 0.0
			sprite_child.visible = true
			# Voltear horizontalmente para que mire al lado correcto (espejo)
			sprite_child.scale.x = - abs(sprite_child.scale.x)
		else:
			# Si no hay sprite hijo, girar el nodo principal
			if huaychivo.has_method("set_flip_h") or huaychivo.has_property("flip_h"):
				huaychivo.flip_h = true
			else:
				huaychivo.scale.x = - abs(huaychivo.scale.x)
			huaychivo.visible = false

		# Crear label de debug para mostrar fase actual/siguiente en pantalla
		phase_label = Label.new()
		phase_label.name = "PhaseLabel"
		phase_label.text = ""
		phase_label.position = Vector2(12, 12)
		phase_label.add_theme_color_override("font_color", Color(1, 1, 1))
		# Ajuste de alineación compatible: algunas versiones usan 'horizontal_alignment' o 'align'
		if "horizontal_alignment" in phase_label:
			phase_label.set("horizontal_alignment", 0)
		elif "align" in phase_label:
			phase_label.set("align", 0)
		canvas.add_child(phase_label)
		# Inicializar texto de fase
		_set_phase_label_text()

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


# Mostrar un mensaje temporal en la caja de diálogo durante `duration` segundos
func _show_temporary_message(text: String, duration: float = 1.4) -> void:
	if dialog_box and huaychivo_label:
		dialog_box.visible = true
		huaychivo_label.text = text
		huaychivo_label.visible = true
		personaje_label.visible = false
		dialog_label.visible = false
	await _delay(duration)
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
		# Default razonable: sin daño a ninguno (comportamiento seguro)
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
		await _delay(0.14)
		hit_flash.visible = false
		update_health_ui()
	else:
		# HuayChivo ataca con daño mayor
		var hdmg = 2
		player_health -= hdmg
		print("Jugador recibe %d de daño por HuayChivo" % hdmg)
		hit_flash.visible = true
		await _delay(0.18)
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

func _spawn_player() -> void:
	var scene: PackedScene
	if Engine.has_singleton("Global") and Global.has_property("selected_character_scene"):
		scene = Global.selected_character_scene
	else:
		var scene_path = "res://Scenes/Lele_Player.tscn"
		if FileAccess.file_exists(scene_path):
			scene = load(scene_path)
		else:
			print("ADVERTENCIA: No se encontró la escena del personaje")

	if scene and scene is PackedScene:
		var inst = scene.instantiate()
		inst.position = player_spawn.position
		# Voltear horizontalmente el nodo visual del personaje si existe
		var sprite_child := inst.get_node_or_null("Sprite2D")
		if sprite_child:
			sprite_child.scale.x = - abs(sprite_child.scale.x)
		else:
			inst.scale.x = - abs(inst.scale.x)
		characters.add_child(inst)
		player_instance = inst

		# Instanciar y adjuntar el arma seleccionada según el valor de selected_weapon
		var weapon_map = {
			"weapon_a": "res://Scenes/Weapon_A.tscn",
			"weapon_b": "res://Scenes/Weapon_B.tscn",
			"weapon_c": "res://Scenes/Weapon_C.tscn"
		}
		var weapon_scene_path = weapon_map[selected_weapon] if weapon_map.has(selected_weapon) else "res://Scenes/Weapon_A.tscn"
		if not FileAccess.file_exists(weapon_scene_path):
			weapon_scene_path = "res://Scenes/Weapon_A.tscn"
		if FileAccess.file_exists(weapon_scene_path):
			var weapon_scene = load(weapon_scene_path)
			if weapon_scene and weapon_scene is PackedScene:
				player_weapon = weapon_scene.instantiate()
				# Buscar marker de mano
				var hand_marker = player_instance.get_node_or_null("Hand")
				if hand_marker:
					player_instance.add_child(player_weapon)
					player_weapon.position = hand_marker.position
				else:
					# Si no hay marker, poner en el centro
					player_instance.add_child(player_weapon)
					player_weapon.position = Vector2.ZERO


		# Slide hacia la izquierda tras spawnear
		var slide_tween = create_tween()
		var target_x = inst.position.x - 200.0
		slide_tween.tween_property(inst, "position:x", target_x, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

# ----- Configuración -----
func _configure_dogs_collision() -> void:
	# Perros en capa 2 (valor entero 2) y solo colisionan con la capa 1 (jugador/ataques)
	nahual1.collision_layer = 2
	nahual2.collision_layer = 2
	nahual3.collision_layer = 2
	nahual1.collision_mask = 1
	nahual2.collision_mask = 1
	nahual3.collision_mask = 1

func _set_dogs_target_positions(target_x: float) -> void:
	nahual1.target_position_x = target_x
	nahual2.target_position_x = target_x
	nahual3.target_position_x = target_x

func _configure_dogs_properties() -> void:
	nahual1.target_position_x = 575
	nahual2.target_position_x = 575
	nahual3.target_position_x = 575

	nahual1.speed = 200
	nahual2.speed = 220
	nahual3.speed = 240

# ----- Métodos faltantes -----
func _on_attack_dogs_pressed() -> void:
	# Punto de entrada legacy re-encaminado al handler unificado
	_on_attack_pressed()

func _on_attack_huaychivo_pressed() -> void:
	# Punto de entrada re-encaminado al handler unificado
	_on_attack_pressed()

func _on_attack_pressed() -> void:
	# Unified attack handler. If there are any dogs alive, attack the first one.
	# Una vez muertos todos, atacar al HuayChivo.
	# Solo aceptar ataques en fases de combate
	print("DEBUG: Ataque iniciado en fase: %s, arma: %s" % [current_phase, selected_weapon])

	if current_phase != "dogs" and current_phase != "huaychivo":
		print("No se puede atacar en la fase actual: %s" % current_phase)
		return

	if processing_turn:
		print("DEBUG: Ya hay un turno en proceso, ignorando")
		return
	processing_turn = true

	# Deshabilitar botón hasta que termine el turno
	if btn_attack_dogs:
		btn_attack_dogs.disabled = true

	# ...existing code...

	# Si aún hay perros vivos, reutilizar la lógica existente
	var idx: int = -1
	for i in range(dogs_alive.size()):
		if dogs_alive[i]:
			idx = i
			break

	if idx != -1:
		# atacar perro usando daño por arma
		var dmg = _get_damage_for("dog")
		dogs_health[idx] -= dmg
		# evitar HP negativo
		if dogs_health[idx] < 0:
			dogs_health[idx] = 0
		print("Perro %d golpeado (unificado), daño: %d, vida restante: %d" % [idx + 1, dmg, dogs_health[idx]])
		if dogs_health[idx] <= 0:
			dogs_alive[idx] = false
			var node_path := "Characters/Dogs/nahual%d" % (idx + 1)
			if has_node(node_path):
				var dog_node := get_node(node_path)
				if dog_node:
					dog_node.hide()
					_play_death_effect_at(dog_node.global_position)
		# actualizar UI (la UI de enemigos es mínima por ahora)
		update_health_ui()

		# Después del ataque del jugador, permitir una breve respuesta enemiga
		await _delay(0.25)
		await _enemy_retaliation()
		processing_turn = false
		# Reactivar botón si la fase aún permite atacar
		if current_phase == "dogs" or current_phase == "huaychivo":
			if btn_attack_dogs:
				btn_attack_dogs.disabled = false
		# Verificar si quedan perros
		var any_alive := false
		for a in dogs_alive:
			if a:
				any_alive = true
				break
		if not any_alive:
			print("DEBUG: Todos los perros han sido derrotados")
			# Mostrar mensaje intermedio y luego cambiar a fase HuayChivo
			await _show_temporary_message("¡Todos los perros derrotados! Ahora enfrenta al Huaychivo", 1.4)
			set_phase("huaychivo")

			# Asegurar que el botón esté configurado correctamente para la fase huaychivo
			if btn_attack_dogs:
				btn_attack_dogs.text = "Atacar Huaychivo"
				btn_attack_dogs.disabled = false
				print("DEBUG: Botón actualizado para atacar al Huaychivo")
		return

# Si no hay perros, atacar al HuayChivo
	if current_phase == "huaychivo":
		print("DEBUG: Atacando al huaychivo con arma: %s" % selected_weapon)
		var dmg_h = _get_damage_for("huaychivo")
		print("DEBUG: selected_weapon='%s' -> damage to huaychivo computed=%d" % [selected_weapon, dmg_h])
		huaychivo_health -= dmg_h
		print("HuayChivo golpeado, daño: %d, vida restante: %d" % [dmg_h, huaychivo_health])

		# Efecto visual del golpe
		if huaychivo:
			_play_death_effect_at(huaychivo.global_position)

		update_health_ui()

		# Si el golpe fue letal (arma correcta), victoria inmediata sin contraataque
		if huaychivo_health <= 0:
			print("DEBUG: ¡Victoria! Huaychivo derrotado.")
			if huaychivo:
				huaychivo.hide()
			processing_turn = false
			set_phase("victory")
			return # Solo si el HuayChivo sigue vivo, contraataque
		await _delay(0.25)
		await _enemy_retaliation()
		processing_turn = false
		if current_phase == "dogs" or current_phase == "huaychivo":
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
	# Mostrar mensaje de victoria y cambiar de escena o volver al mapa
	if dialog_box and huaychivo_label:
		dialog_box.visible = true

		# Mensaje educativo sobre mitología maya
		if selected_weapon == "weapon_c":
			huaychivo_label.text = "¡Victoria! Has derrotado al Huaychivo con el bastón de chechén, el arma tradicional maya. El chechén es un árbol sagrado cuya madera tiene propiedades especiales. En la cultura maya, elegir la herramienta correcta es clave para resolver problemas."
		else:
			# No debería ocurrir, pero por si acaso
			huaychivo_label.text = "¡Victoria! Has derrotado al Huaychivo y puedes regresar a casa"

		huaychivo_label.visible = true
		personaje_label.visible = false
		dialog_label.visible = false
	# pequeños efectos visuales
	await _delay(1.2)
	# Intentar ir a la escena de la casa si existe, sino mostrar GameOver
	if FileAccess.file_exists("res://Casa.tscn"):
		get_tree().change_scene_to_file("res://Casa.tscn")
	elif FileAccess.file_exists("res://Scenes/mapa.tscn"):
		get_tree().change_scene_to_file("res://Scenes/mapa.tscn")
	else:
		# Fallback: ir a GameOver (que muestra imagen estática)
		if FileAccess.file_exists("res://Scenes/GameOver.tscn"):
			get_tree().change_scene_to_file("res://Scenes/GameOver.tscn")

func defeat() -> void:
	# Mostrar mensaje educativo de derrota según el arma elegida
	if dialog_box and huaychivo_label:
		dialog_box.visible = true

		# Personalizar mensaje según el arma elegida
		if selected_weapon == "weapon_a":
			huaychivo_label.text = "Has sido derrotado. La jícara decorativa no es un arma, sino un recipiente ceremonial maya. Para vencer al Huaychivo necesitas un arma con poder sagrado. Intenta con el bastón de chechén."
		elif selected_weapon == "weapon_b":
			huaychivo_label.text = "Has sido derrotado. La honda yucateca solo funciona contra animales pequeños. El Huaychivo es una criatura mágica que solo puede ser vencida con un arma especial: el bastón de chechén."
		else:
			huaychivo_label.text = "Has sido derrotado... Intenta de nuevo eligiendo el bastón de chechén para vencer al Huaychivo."

		huaychivo_label.visible = true
		personaje_label.visible = false
		dialog_label.visible = false

	# Esperar 3 segundos antes de cambiar
	await _delay(3.0)

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
			huaychivo_label.text = text
			huaychivo_label.visible = true
			personaje_label.visible = false
			dialog_label.visible = false # Hide the main label
			# Ocultar DialogBox para personajes
			if dialog_box:
				dialog_box.visible = false
		elif line.begins_with("PERSONAJE:"):
			var text = line.substr(10).strip_edges() # Remove "PERSONAJE: "
			personaje_label.text = text
			personaje_label.visible = true
			huaychivo_label.visible = false
			dialog_label.visible = false # Hide the main label
			# Ocultar DialogBox para personajes
			if dialog_box:
				dialog_box.visible = false
		else:
			# Explicación: mostrar en dialog_label dentro de DialogBox
			dialog_label.text = line
			dialog_label.visible = true
			huaychivo_label.visible = false
			personaje_label.visible = false
			# Mostrar DialogBox para explicaciones
			if dialog_box:
				dialog_box.visible = true
			if dialog_card:
				dialog_card.visible = true
		dialog_next_btn.visible = true
	else:
		# Diálogo terminado: ocultar UI de diálogo y pasar a fase de perros
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
