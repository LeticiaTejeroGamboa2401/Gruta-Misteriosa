extends Node2D

# Variables del sistema
var is_selecting_weapon = false
var selected_weapon = ""

# Información de las armas (puedes cambiar estos datos cuando definas las armas definitivas)
var weapon_info = {
	"weapon_a": {
		"name": "Arma Ancestral A",
		"description": "Arma tradicional maya con poder espiritual."
	},
	"weapon_b": {
		"name": "Arma Ancestral B", 
		"description": "Arma sagrada usada por guerreros mayas."
	},
	"weapon_c": {
		"name": "Arma Ancestral C",
		"description": "Arma mística bendecida por los dioses mayas."
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
	
	# Conectar señales
	_connect_signals()

func show_dialog():
	if current_dialog < dialogs.size():
		dialog_label.text = dialogs[current_dialog]
		dialog_popup.show()
	else:
		start_weapon_selection()

func _on_next_pressed():
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
	get_tree().change_scene_to_file("res://final_battle.tscn")

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
			"description": "Bastón de madera de chicozapote, usado por guerreros mayas para combate cuerpo a cuerpo."
		},
		"weapon_b": {
			"name": "Honda Maya", 
			"description": "Arma de proyectiles usada para cazar, hecha de fibras de henequén trenzadas."
		},
		"weapon_c": {
			"name": "Lanza con Obsidiana",
			"description": "Lanza sagrada con punta de obsidiana volcánica, bendecida por los dioses mayas."
		}
	}

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
