extends Node

@export var quiz: QuizThemeDardos
@export var imgCorrecto: Texture2D
@export var imgIncorrecto: Texture2D

var buttons: Array[Button]
var index: int = 0                  # Índice actual de pregunta
var correct: int = 0                # Contador de respuestas correctas
var answered: bool = false          # Indica si ya se respondió una pregunta
var selected_questions: Array = []  # Preguntas seleccionadas aleatoriamente
var vidas: int = 3                  # Vidas disponibles por pregunta

@onready var question_texts: Label = $Control/Pregunta/Texto
@onready var feedback_image: TextureRect = $Control/Acierto/FeedBack
@onready var vidas_label: Label = $Control/dardos_vida

func _ready() -> void:
	MusicManager.play_music("res://audio/dardos.ogg")

	# Guardar botones en arreglo
	for button in $Control/MenuButton.get_children():
		buttons.append(button)

	# Seleccionar preguntas aleatorias
	selected_questions = quiz.theme.duplicate()
	selected_questions.shuffle()
	selected_questions = selected_questions.slice(0, 6)

	load_quiz()

func load_quiz() -> void:
	answered = false
	vidas = 3
	vidas_label.text = "x %d" % vidas
	feedback_image.texture = null
	feedback_image.visible = false

	var current_question = selected_questions[index]
	question_texts.text = current_question.question_info
	var options = current_question.options

	for i in buttons.size():
		var button = buttons[i]

		# Limpiar contenido anterior del botón
		for child in button.get_children():
			child.queue_free()

		# Instanciar nueva escena animada
		var option_scene = options[i]
		var instance = option_scene.instantiate()

		# Escala opcional (ajústala si tus globos son grandes)
		instance.scale = Vector2(1, 1)

		# Agregar globo al botón
		button.add_child(instance)

		# Desconectar conexiones previas si las hay
		if button.pressed.is_connected(_buttons_answer):
			button.pressed.disconnect(_buttons_answer)

		# Conectar botón con la función, pasando el botón y la escena
		button.pressed.connect(_buttons_answer.bind(button, option_scene))

func _buttons_answer(button_presionado: Button, selected_scene: PackedScene) -> void:
	if answered:
		return

	# Animar solo el globo de este botón
	for child in button_presionado.get_children():
		if child.has_method("animar"):
			child.animar()
			break

	# Validar si la respuesta fue correcta
	var correct_scene = selected_questions[index].correct

	if selected_scene.resource_path == correct_scene.resource_path:
		feedback_image.texture = imgCorrecto
		feedback_image.visible = true
		correct += 1
		answered = true

		await get_tree().create_timer(1.5).timeout
		feedback_image.visible = false

		index += 1
		if index < selected_questions.size():
			load_quiz()
		else:
			show_final_score()
	else:
		feedback_image.texture = imgIncorrecto
		feedback_image.visible = true
		vidas -= 1
		vidas_label.text = "x %d" % vidas

		await get_tree().create_timer(1.5).timeout
		feedback_image.visible = false

		if vidas <= 0:
			answered = true
			index += 1
			if index < selected_questions.size():
				load_quiz()
			else:
				show_final_score()

func show_final_score():
	Input.set_custom_mouse_cursor(null)
	if correct == selected_questions.size():
		Global.juegos_ganados["juego_dardos"] = true
		get_tree().change_scene_to_file("res://Scenes/Juegos/Derriba_al_Pato/Ganaste.tscn")
	else:
		get_tree().change_scene_to_file("res://Scenes/Juegos/Derriba_al_Pato/Perdiste.tscn")

func _on_salir_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Juegos/Derriba_al_Pato/Perdiste.tscn")
