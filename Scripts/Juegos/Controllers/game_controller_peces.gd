extends Node

@export var quiz: QuizThemePeces
@export var imgCorrecto: Texture2D
@export var imgIncorrecto: Texture2D

var buttons: Array[Button] = []
var index: int = 0                  # índice actual de pregunta
var correct: int = 0                # contador de respuestas correctas
var answered: bool = false          # indica si ya se respondió la pregunta
var selected_questions: Array = [] # preguntas seleccionadas aleatoriamente

@onready var question_texts: Label = $Control/Pregunta/Texto
@onready var question_imgs : TextureRect = $Control/Pregunta/Imagen
@onready var feedback_image: TextureRect = $Control/Correcto/FeedBackImage

func _ready() -> void:
	MusicManager.play_music("res://audio/peces.ogg")

	# Guardar solo los botones válidos en el arreglo
	for child in $Control/MenuButtons.get_children():
		if child is Button:
			buttons.append(child)

	# Seleccionar preguntas aleatorias
	selected_questions = quiz.theme.duplicate()
	selected_questions.shuffle()
	selected_questions = selected_questions.slice(0, min(6, selected_questions.size()))

	load_quiz()

func load_quiz() -> void:
	answered = false
	feedback_image.texture = null
	feedback_image.visible = false

	var current_question = selected_questions[index]
	question_texts.text = current_question.question_info
	question_imgs.texture = current_question.question_img

	var options = current_question.options

	for i in buttons.size():
		var button = buttons[i]

		# Limpiar contenido anterior del botón
		for child in button.get_children():
			child.queue_free()

		# Instanciar nueva escena animada
		var option_scene = options[i]
		var instance = option_scene.instantiate()
		instance.scale = Vector2(1, 1)  # Ajusta si es necesario

		button.add_child(instance)

		# Desconectar conexiones previas si existen
		if button.pressed.is_connected(_buttons_answer):
			button.pressed.disconnect(_buttons_answer)

		# Conectar con la opción correspondiente
		button.pressed.connect(_buttons_answer.bind(option_scene))

func _buttons_answer(selected_scene: PackedScene) -> void:
	if answered:
		return

	answered = true
	var correct_scene = selected_questions[index].correct

	# Comparación directa entre escenas (más segura que resource_path)
	if selected_scene == correct_scene:
		feedback_image.texture = imgCorrecto
		correct += 1
	else:
		feedback_image.texture = imgIncorrecto

	feedback_image.visible = true
	await get_tree().create_timer(1.5).timeout
	feedback_image.visible = false

	index += 1
	if index < selected_questions.size():
		load_quiz()
	else:
		show_final_score()

func show_final_score():
	Input.set_custom_mouse_cursor(null)

	if correct == selected_questions.size():
		Global.juegos_ganados["juego_peces"] = true
		get_tree().change_scene_to_file("res://Scenes/Juegos/Derriba_al_Pato/Ganaste.tscn")
	else:
		get_tree().change_scene_to_file("res://Scenes/Juegos/Derriba_al_Pato/Perdiste.tscn")
