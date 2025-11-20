extends Node2D

# Variables del sistema
var is_selecting_weapon = false
var selected_weapon = ""

# Información de las armas (nombres canónicos visibles en UI)
var weapon_info = {
	"weapon_a": {
		"name": "Macana Maya",
		"description": "Bastón de madera, usado por guerreros mayas para combate cuerpo a cuerpo."
	},
	"weapon_b": {
		"name": "Jícara",
		"description": "Jícara pintada y pulida, usada tradicionalmente para servir alimentos y bebidas."
	},
	"weapon_c": {
		"name": "Lanza con Obsidiana",
		"description": "Lanza sagrada con punta de obsidiana, bendecida por los dioses mayas."
	}
}

# Diálogos del amuleto
var dialogs = [
	"Tu amuleto está completo, guerrero valiente...",
	"Pero el Huaychivo se acerca. Debes elegir un arma ancestral.",
	"Toca el arma que deseas invocar. Elige sabiamente..."
]

var current_dialog = 0
var showing_weapon_selection = false

# Referencias a nodos UI
@onready var dialog_popup = $UI/DialogPopup
@onready var dialog_label = $UI/DialogPopup/DialogLabel
@onready var next_button = $UI/DialogPopup/NextButton
@onready var amulet_complete = $AmuletComplete
@onready var weapon_options = $WeaponOptions
@onready var weapon_info_popup = $UI/WeaponInfoPopup
@onready var weapon_title = $UI/WeaponInfoPopup/WeaponTitle
@onready var weapon_description = $UI/WeaponInfoPopup/WeaponDescription
@onready var animation_player = $AmuletComplete/AnimationPlayer

# Referencias a armas - usando tus nombres actuales
@onready var weapon_a = $WeaponOptions/WeaponA
@onready var weapon_b = $WeaponOptions/WeaponB
@onready var weapon_c = $WeaponOptions/WeaponC

# Efectos visuales
@onready var selection_effect = $SelectionEffect

# Audio
var ui_hover_sfx: AudioStreamPlayer
var ui_select_sfx: AudioStreamPlayer
var weapon_confirm_sfx: AudioStreamPlayer
var bgm_player: AudioStreamPlayer

func _ready():
	init_ui()
	show_dialog()

func init_ui():
	# Ocultar elementos iniciales
	weapon_options.hide()
	weapon_info_popup.hide()
	dialog_popup.hide()

	# Configurar amuleto
	amulet_complete.visible = true
	animation_player.play("amulet_idle_glow")

	# Cargar texturas de las armas
	# POR FAVOR, REEMPLAZA CON LOS NOMBRES DE ARCHIVO CORRECTOS PARA weapon_a y weapon_b
	# weapon_a.texture_normal = load("res://assets/NOMBRE_DEL_ARCHIVO_ARMA_A.png")
	# weapon_b.texture_normal = load("res://assets/NOMBRE_DEL_ARCHIVO_ARMA_B.png")
	weapon_c.texture_normal = load("res://assets/lanza.png")

	# Conectar señales
	_connect_signals()

	# Configurar audio
	_setup_audio()

func show_dialog():
	if current_dialog < dialogs.size():
		dialog_label.text = dialogs[current_dialog]
		dialog_popup.show()
	else:
		start_weapon_selection()

func _on_next_pressed():
	print("🔊 Click en Next button")
	if ui_select_sfx:
		ui_select_sfx.play()
	dialog_popup.hide()
	current_dialog += 1

	if current_dialog < dialogs.size():
		# Pequeña pausa antes del siguiente diálogo
		await get_tree().create_timer(0.5).timeout
		show_dialog()
	else:
		start_weapon_selection()

func start_weapon_selection():
	showing_weapon_selection = true

	# Mostrar opciones de armas
	weapon_options.show()

	# Animar entrada de armas
	animate_weapons_entrance()

func animate_weapons_entrance():
	# Posiciones iniciales (fuera de pantalla)
	var original_positions = {
		"weapon_a": weapon_a.position,
		"weapon_b": weapon_b.position,
		"weapon_c": weapon_c.position
	}

	# Mover armas fuera de pantalla
	weapon_a.position.x -= 200
	weapon_b.position.y -= 200
	weapon_c.position.x += 200

	# Animar entrada
	var tween = create_tween()
	tween.set_parallel(true)

	tween.tween_property(weapon_a, "position", original_positions["weapon_a"], 0.8)
	tween.tween_property(weapon_b, "position", original_positions["weapon_b"], 0.8)
	tween.tween_property(weapon_c, "position", original_positions["weapon_c"], 0.8)

	# Efecto de entrada
	tween.tween_property(weapon_a, "modulate:a", 1.0, 0.8)
	tween.tween_property(weapon_b, "modulate:a", 1.0, 0.8)
	tween.tween_property(weapon_c, "modulate:a", 1.0, 0.8)

	await tween.finished
	is_selecting_weapon = true

func _on_weapon_selected(weapon_type: String):
	if not is_selecting_weapon:
		return

	is_selecting_weapon = false
	selected_weapon = weapon_type

	# Guardar selección en Global
	Global.selected_weapon = weapon_type

	# Obtener la textura del arma desde el Sprite2D hijo del botón
	var weapon_button = get_weapon_button(weapon_type)
	if weapon_button:
		# Los botones tienen un Sprite2D hijo con la textura del arma
		var sprite_child = null
		for child in weapon_button.get_children():
			if child is Sprite2D:
				sprite_child = child
				break

		if sprite_child and sprite_child.texture:
			Global.selected_weapon_texture = sprite_child.texture
			print("DEBUG: Textura de arma guardada: ", sprite_child.texture.resource_path)
		else:
			# Fallback: intentar usar texture_normal del botón
			if weapon_button.texture_normal:
				Global.selected_weapon_texture = weapon_button.texture_normal
				print("DEBUG: Textura de arma guardada desde texture_normal")
			else:
				print("ADVERTENCIA: No se pudo obtener la textura del arma seleccionada")

	# Efecto visual de selección
	show_selection_effect(weapon_type)

	# Mostrar información del arma seleccionada
	show_weapon_confirmation(weapon_type)

func show_selection_effect(weapon_type: String):
	var weapon_button = get_weapon_button(weapon_type)

	# Efecto de brillo/selección
	var tween = create_tween()
	tween.set_parallel(true)

	# Hacer brillar el arma seleccionada
	tween.tween_property(weapon_button, "modulate", Color.YELLOW, 0.3)
	tween.tween_property(weapon_button, "scale", Vector2(1.2, 1.2), 0.3)

	# Desvanecer las otras armas
	for weapon in [weapon_a, weapon_b, weapon_c]:
		if weapon != weapon_button:
			tween.tween_property(weapon, "modulate:a", 0.3, 0.5)

func show_weapon_confirmation(weapon_type: String):
	# Reproducir sonido de confirmación épico
	if weapon_confirm_sfx:
		weapon_confirm_sfx.play()

	var info = weapon_info[weapon_type]

	# Actualizar el texto del diálogo con información del arma seleccionada
	dialog_label.text = info["name"] + "\n" + info["description"] + "\n\n¡Arma seleccionada! Preparándote para la batalla..."

	# Mostrar el diálogo en lugar del popup de información
	dialog_popup.show()

	# Ocultar el popup de información por si estaba visible
	weapon_info_popup.hide()

	# Continuar después de unos segundos
	await get_tree().create_timer(3.0).timeout
	transition_to_battle()


func transition_to_battle():
	# Efecto de transición
	var tween = create_tween()
	tween.set_parallel(true)

	# Desvanecer todo
	tween.tween_property(weapon_options, "modulate:a", 0.0, 1.0)
	tween.tween_property(weapon_info_popup, "modulate:a", 0.0, 1.0)

	# Hacer brillar el amuleto intensamente
	animation_player.play("amulet_final_glow")

	await tween.finished

	# Cambiar a escena de batalla
	get_tree().change_scene_to_file("res://Scenes/WalkToBattle.tscn")

func get_weapon_button(weapon_type: String) -> TextureButton:
	match weapon_type:
		"weapon_a":
			return weapon_a
		"weapon_b":
			return weapon_b
		"weapon_c":
			return weapon_c
		_:
			return null

func _on_weapon_hover_entered(weapon_type: String):
	# Reproducir sonido de hover
	print("🔊 Hover en arma: ", weapon_type)
	if ui_hover_sfx:
		ui_hover_sfx.play()

	if not is_selecting_weapon:
		return

	# Mostrar información del arma
	var info = weapon_info[weapon_type]
	weapon_title.text = info["name"]
	weapon_description.text = info["description"]
	weapon_info_popup.show()

	# Efecto visual de hover
	var weapon_button = get_weapon_button(weapon_type)
	var tween = create_tween()
	tween.tween_property(weapon_button, "scale", Vector2(1.1, 1.1), 0.2)

func _on_weapon_hover_exited(weapon_type: String):
	if not is_selecting_weapon:
		return

	# Ocultar información
	weapon_info_popup.hide()

	# Restaurar escala
	var weapon_button = get_weapon_button(weapon_type)
	var tween = create_tween()
	tween.tween_property(weapon_button, "scale", Vector2(1.0, 1.0), 0.2)

func _connect_signals():
	# Botón siguiente
	if next_button.pressed.is_connected(_on_next_pressed):
		next_button.pressed.disconnect(_on_next_pressed)
	next_button.pressed.connect(_on_next_pressed)

	# Botones de armas - usando tus nombres actuales
	if weapon_a.pressed.is_connected(_on_weapon_selected):
		weapon_a.pressed.disconnect(_on_weapon_selected)
	weapon_a.pressed.connect(_on_weapon_selected.bind("weapon_a"))

	if weapon_b.pressed.is_connected(_on_weapon_selected):
		weapon_b.pressed.disconnect(_on_weapon_selected)
	weapon_b.pressed.connect(_on_weapon_selected.bind("weapon_b"))

	if weapon_c.pressed.is_connected(_on_weapon_selected):
		weapon_c.pressed.disconnect(_on_weapon_selected)
	weapon_c.pressed.connect(_on_weapon_selected.bind("weapon_c"))

	# Hover effects
	weapon_a.mouse_entered.connect(_on_weapon_hover_entered.bind("weapon_a"))
	weapon_a.mouse_exited.connect(_on_weapon_hover_exited.bind("weapon_a"))

	weapon_b.mouse_entered.connect(_on_weapon_hover_entered.bind("weapon_b"))
	weapon_b.mouse_exited.connect(_on_weapon_hover_exited.bind("weapon_b"))

	weapon_c.mouse_entered.connect(_on_weapon_hover_entered.bind("weapon_c"))
	weapon_c.mouse_exited.connect(_on_weapon_hover_exited.bind("weapon_c"))

# Función para actualizar información de armas (úsala cuando definas las armas definitivas)
func update_weapon_info():
	# Ejemplo de cómo puedes actualizar la información cuando la tengas definida
	weapon_info = {
		"weapon_a": {
			"name": "Macana Maya",
			"description": "Bastón de madera, usado por guerreros mayas para combate cuerpo a cuerpo."
		},
		"weapon_b": {
			"name": "Jícara",
			"description": "Jícara pintada y pulida, usada tradicionalmente para servir alimentos y bebidas."
		},
		"weapon_c": {
			"name": "Lanza con Obsidiana",
			"description": "Lanza sagrada con punta de obsidiana, bendecida por los dioses mayas."
		}
	}

func _setup_audio() -> void:
	print("🎵 Configurando audio en weapon_selection...")
	# Hover sobre armas
	ui_hover_sfx = AudioStreamPlayer.new()
	ui_hover_sfx.stream = load("res://assets/sounds/kenney_ui-audio-2/Audio/rollover3.ogg")
	ui_hover_sfx.volume_db = 0
	ui_hover_sfx.bus = "Master"
	add_child(ui_hover_sfx)
	print("✅ Hover SFX configurado")

	# Click en botón Next
	ui_select_sfx = AudioStreamPlayer.new()
	ui_select_sfx.stream = load("res://assets/sounds/kenney_interface-sounds/Audio/click_001.ogg")
	ui_select_sfx.volume_db = 0
	ui_select_sfx.bus = "Master"
	add_child(ui_select_sfx)
	print("✅ Select SFX configurado")

	# Confirmación de arma seleccionada
	weapon_confirm_sfx = AudioStreamPlayer.new()
	weapon_confirm_sfx.stream = load("res://assets/sounds/kenney_digital-audio/Audio/powerUp3.ogg")
	weapon_confirm_sfx.volume_db = 0
	weapon_confirm_sfx.bus = "Master"
	add_child(weapon_confirm_sfx)
	print("✅ Weapon confirm SFX configurado")

	# Música de fondo
	bgm_player = AudioStreamPlayer.new()
	bgm_player.stream = load("res://audio/suspenso.ogg")
	bgm_player.volume_db = -12
	bgm_player.bus = "Master"
	bgm_player.autoplay = true # Iniciar automáticamente
	add_child(bgm_player)
	print("✅ BGM suspenso configurado y reproduciendo")

# Función de debug
func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F2:
			print("Debug - Weapon Selection:")
			print("- Is selecting: ", is_selecting_weapon)
			print("- Selected weapon: ", selected_weapon)
			print("- Current dialog: ", current_dialog)
			print("- Showing weapon selection: ", showing_weapon_selection)
		elif event.keycode == KEY_F3:
			# Debug: Actualizar info de armas
			update_weapon_info()
			print("Weapon info updated!")
