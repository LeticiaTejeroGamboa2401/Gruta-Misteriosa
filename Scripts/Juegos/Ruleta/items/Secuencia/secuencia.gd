extends Node

@export var quiz: QuizThemeRuletaGraficos
@export var imgCorrecto: Texture2D
@export var imgIncorrecto: Texture2D

var buttons: Array[Button]
var answered: bool = false
var selected_question

@onready var question_texts: Label = $Control/Pregunta/Texto
@onready var feedback_image: TextureRect = $Control/Feedback/TextureRect

func _ready() -> void:
	for button in $Control/MenuButton.get_children():
		buttons.append(button)
	
	# Elegir una pregunta aleatoria del tema
	var questions = quiz.theme.duplicate()
	questions.shuffle()
	selected_question = questions[0]

	# Mostrar texto e imagen
	question_texts.text = selected_question.question_info

	var options = selected_question.options
	for i in buttons.size():
		buttons[i].text = options[i]
		
		if not buttons[i].pressed.is_connected(_buttons_answer):
			buttons[i].pressed.connect(_buttons_answer.bind(buttons[i]))

func _buttons_answer(button) -> void:
	if answered:
		return

	answered = true
	var selected_text = button.text

	if selected_text == selected_question.correct:
		feedback_image.texture = imgCorrecto
		Global.respuestas_correctas += 1
	else:
		feedback_image.texture = imgIncorrecto

	feedback_image.visible = true
	await get_tree().create_timer(1.5).timeout
	feedback_image.visible = false

	# Sumar una ronda
	Global.ronda_actual += 1

	# Ver si se completaron las 5 rondas
	if Global.ronda_actual >= Global.total_rondas:
		if Global.respuestas_correctas == Global.total_rondas:
			Global.juegos_ganados["juego_ruleta"] = true
			get_tree().change_scene_to_file("res://Scenes/Juegos/Ruleta/FinalGanaste.tscn")
		else:
			get_tree().change_scene_to_file("res://Scenes/Juegos/Ruleta/FinalPerdiste.tscn")
	else:
		get_tree().change_scene_to_file("res://Scenes/Juegos/Ruleta/ruleta.tscn")
