extends Node2D

@export var min_rotations: int = 3
@export var max_rotations: int = 6
@export var deceleration: float = 150.0 # cuánto se desacelera por segundo

var _target_rotation: float = 0.0
var _current_speed: float = 0.0
var _rotating: bool = false
var _selected_area: Area2D = null

func _ready() -> void:
	MusicManager.play_music("res://audio/ruleta.ogg")
	
	if Global.ronda_actual == 0:
		Global.respuestas_correctas = 0
	
	randomize()

	# Restaurar estado si volvemos de otra escena
	if Global.ruleta_rotation != 0.0:
		$SpriteRuleta.rotation_degrees = Global.ruleta_rotation
		$Panel/Win.text = Global.area_seleccionada
		_rotating = false
		_current_speed = 0.0
	else:
		$Panel/Win.text = ""

func _process(delta: float) -> void:
	if _rotating:
		if _current_speed > 0.0:
			$SpriteRuleta.rotation_degrees += _current_speed * delta
			_current_speed -= deceleration * delta
		else:
			_current_speed = 0.0
			_rotating = false
			_show_winner_and_change_scene()

func _on_button_pressed() -> void:
	_start_roulette()

func _start_roulette() -> void:
	# Limpiar estado guardado
	Global.ruleta_rotation = 0.0
	Global.area_seleccionada = ""

	# Calcular rotación aleatoria final
	var rotations = randi_range(min_rotations, max_rotations)
	var random_offset = randf_range(0, 360)
	_target_rotation = (rotations * 360.0) + random_offset

	# Resetear estado
	_selected_area = null
	$SpriteRuleta.rotation_degrees = 0.0
	_current_speed = sqrt(2 * deceleration * _target_rotation)
	_rotating = true

	# Limpiar mensaje anterior
	$Panel/Win.text = ""

	# Reactivar colisiones si aplica
	for node in $SpriteRuleta.get_children():
		for child in node.get_children():
			if child is CollisionShape2D:
				child.disabled = false

func _on_area_manecilla_area_entered(area: Area2D) -> void:
	_selected_area = area

func _show_winner_and_change_scene() -> void:
	if _selected_area:
		var area_name = _selected_area.name
		$Panel/Win.text = area_name

		# GUARDAR estado actual
		Global.ruleta_rotation = $SpriteRuleta.rotation_degrees
		Global.area_seleccionada = area_name

		await get_tree().create_timer(1.5).timeout

		match area_name:
			"OPERACIONES CON NÚMEROS NATURALES":
				get_tree().change_scene_to_file("res://Scenes/Juegos/Ruleta/items_ruleta/Ruleta_ONN/Operaciones-Numeros-Naturales.tscn")
			"FRACCIONES":
				get_tree().change_scene_to_file("res://Scenes/Juegos/Ruleta/items_ruleta/Ruleta_Fracc/Fracciones.tscn")
			"NÚMEROS DECIMALES":
				get_tree().change_scene_to_file("res://Scenes/Juegos/Ruleta/items_ruleta/Ruleta_ND/Numeros-Decimales.tscn")
			"PROBLEMAS CON MÚLTIPLOS Y DIVISORES":
				get_tree().change_scene_to_file("res://Scenes/Juegos/Ruleta/items_ruleta/Ruleta_Multi-Div/Multi-Div.tscn")
			"PERÍMETRO Y ÁREA":
				get_tree().change_scene_to_file("res://Scenes/Juegos/Ruleta/items_ruleta/Ruleta_PyA/Perimetro-Area.tscn")
			"MEDICIÓN Y UNIDADES":
				get_tree().change_scene_to_file("res://Scenes/Juegos/Ruleta/items_ruleta/Ruleta_MedyUnid/Medición-Unidades.tscn")
			"GRÁFICAS Y DATOS":
				get_tree().change_scene_to_file("res://Scenes/Juegos/Ruleta/items_ruleta/Ruleta_Graf/Gráficos-Datos.tscn")
			"PATRONES Y SECUENCIAS":
				get_tree().change_scene_to_file("res://Scenes/Juegos/Ruleta/items_ruleta/Ruleta_Secuencia/Secuencia.tscn")
			"PORCENTAJES":
				get_tree().change_scene_to_file("res://Scenes/Juegos/Ruleta/items_ruleta/Ruleta_Porcent/Porcentaje.tscn")
			"ÁNGULOS Y GEOMETRÍA":
				get_tree().change_scene_to_file("res://Scenes/Juegos/Ruleta/items_ruleta/Ruleta_Angulos-Geo/Angulos-Geometría.tscn")
			"PROBABILIDAD BÁSICA":
				get_tree().change_scene_to_file("res://Scenes/Juegos/Ruleta/items_ruleta/Ruleta_Prob/Probabiildad-Basica.tscn")
			"ECUACIONES SENCILLAS":
				get_tree().change_scene_to_file("res://Scenes/Juegos/Ruleta/items_ruleta/Ruleta_Ecua/Ecuaciones.tscn")
			_:
				print("No se encontró una escena para el área: ", area_name)
	else:
		$Panel/Win.text = "No se detectó área ganadora."


func _on_salir_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Juegos/Atinale_al_Puerquito/Perdiste.tscn")
