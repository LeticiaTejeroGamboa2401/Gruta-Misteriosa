extends Node

@export var quiz: QuizThemeCaballo
@export var imgCorrecto: Texture2D
@export var imgIncorrecto: Texture2D

var buttons: Array[Button]
var index: int = 0
var correct: int = 0
var answered: bool = false
var selected_questions: Array = []

var caballo_blanco_movido := false
var caballo_negro_movido := false

@onready var question_texts: Label = $Control/InfoTexto/Pregunta
@onready var feedback_image: TextureRect = $Control/Respuesta/FeedBack
@onready var caballo_blanco: Node2D = $Control/CaballoBlanco
@onready var caballo_negro: Node2D = $Control/CaballoNegro

func _ready() -> void:
	MusicManager.play_music("res://audio/caballos.ogg")

	for button in $Control/MenuButton.get_children():
		buttons.append(button)

	# Seleccionar preguntas aleatorias
	selected_questions = quiz.theme.duplicate()
	selected_questions.shuffle()
	selected_questions = selected_questions.slice(0, 6)

	load_quiz()

func load_quiz() -> void:
	answered = false
	feedback_image.visible = false  # Ocultar hasta que se responda
	question_texts.text = selected_questions[index].question_info

	var options = selected_questions[index].options
	for i in buttons.size():
		buttons[i].text = options[i]

		if not buttons[i].pressed.is_connected(_buttons_answer):
			buttons[i].pressed.connect(_buttons_answer.bind(buttons[i]))

func _buttons_answer(button) -> void:
	if answered:
		return

	answered = true
	var selected_text = button.text

	if selected_text == selected_questions[index].correct:
		feedback_image.texture = imgCorrecto
		feedback_image.visible = true
		correct += 1

		if not caballo_blanco_movido:
			caballo_blanco.position.x += 150
			caballo_blanco_movido = true
		else:
			caballo_blanco.position.x += 170
	else:
		feedback_image.texture = imgIncorrecto
		feedback_image.visible = true

		if not caballo_negro_movido:
			caballo_negro.position.x += 150
			caballo_negro_movido = true
		else:
			caballo_negro.position.x += 170

	await get_tree().create_timer(1.5).timeout
	feedback_image.visible = false

	index += 1
	if index < selected_questions.size():
		load_quiz()
	else:
		show_final_score()

func show_final_score():
	if correct == selected_questions.size():
		Global.juegos_ganados["juego_caballo"] = true
		get_tree().change_scene_to_file("res://Scenes/Juegos/Atinale_al_Puerquito/Ganaste.tscn")
	else:
		get_tree().change_scene_to_file("res://Scenes/Juegos/Atinale_al_Puerquito/Perdiste.tscn")


func _on_salir_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Juegos/Atinale_al_Puerquito/Perdiste.tscn")
