extends Node

@export var quiz: QuizThemeAlcancia
@export var imgCorrecto: Texture2D
@export var imgIncorrecto: Texture2D
@export var imgDefault: Texture2D  # ← Imagen por defecto

var buttons: Array[Button]
var index: int = 0                  # índice actual de pregunta
var correct: int = 0                # contador de respuestas correctas
var answered: bool = false          # indica si ya se respondió la pregunta
var selected_questions: Array = []  # preguntas seleccionadas aleatoriamente

@onready var question_texts: Label = $Control/Pregunta/PreguntaTexto
@onready var feedback_image: TextureRect = $Control/Puerquito

func _ready() -> void:
	MusicManager.play_music("res://audio/money.ogg")
	
	for button in $Control/Botones/MenuButton.get_children():
		buttons.append(button)
	
	# Seleccionar preguntas aleatorias
	selected_questions = quiz.theme.duplicate()
	selected_questions.shuffle()
	selected_questions = selected_questions.slice(0, 6)

	load_quiz()

func load_quiz() -> void:
	# Resetear estado
	answered = false
	feedback_image.texture = imgDefault  # ← imagen por defecto
	feedback_image.visible = true
	question_texts.text = selected_questions[index].question_info

	var options = selected_questions[index].options
	for i in buttons.size():
		buttons[i].text = options[i] 

		# Asegura que no se conecte más de una vez
		if not buttons[i].pressed.is_connected(_buttons_answer):
			buttons[i].pressed.connect(_buttons_answer.bind(buttons[i]))

func _buttons_answer(button) -> void:
	if answered:
		return  # Ignorar si ya se respondió esta pregunta

	answered = true  # Marcar como respondida

	var selected_text = button.text

	# Mostrar imagen correspondiente
	if selected_text == selected_questions[index].correct:
		feedback_image.texture = imgCorrecto
		correct += 1
	else:
		feedback_image.texture = imgIncorrecto

	feedback_image.visible = true

	# Esperar 1.5 segundos, luego avanzar
	await get_tree().create_timer(1.5).timeout
	feedback_image.visible = false
	feedback_image.texture = imgDefault  # ← volver a imagen por defecto

	# Pasar a siguiente pregunta
	index += 1
	if index < selected_questions.size():
		load_quiz()
	else:
		show_final_score()

func show_final_score():
	if correct == selected_questions.size():  # todas correctas
		Global.juegos_ganados["juego_puerquito"] = true
		get_tree().change_scene_to_file("res://Scenes/Juegos/Atinale_al_Puerquito/Ganaste.tscn")
	else:
		get_tree().change_scene_to_file("res://Scenes/Juegos/Atinale_al_Puerquito/Perdiste.tscn")


func _on_salir_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Juegos/Atinale_al_Puerquito/Perdiste.tscn")
