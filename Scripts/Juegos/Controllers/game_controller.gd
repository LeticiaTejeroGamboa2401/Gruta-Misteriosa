extends Node

@export var quiz: QuizTheme
@export var imgCorrecto: Texture2D
@export var imgIncorrecto: Texture2D

var buttons: Array[Button]
var index: int = 0            # índice actual de pregunta
var correct: int = 0          # contador de respuestas correctas
var answered: bool = false    # indica si ya se respondió la pregunta


@onready var question_texts: Label = $Control/Panel/Preguntas/PreguntaTexto
@onready var feedback_image: TextureRect = $Control/FeedBackImage

func _ready() -> void:
	for button in $Control/Botones/MenuButton.get_children():
		buttons.append(button)
	load_quiz()

func load_quiz() -> void:
	# Resetear estado
	answered = false
	question_texts.text = quiz.theme[index].question_info
	
	var options = quiz.theme[index].options
	for i in buttons.size():
		var tex_rect := buttons[i].get_node("TextureRect") as TextureRect
		tex_rect.texture = options[i]
		# Asegura que no se conecte más de una vez
		if not buttons[i].pressed.is_connected(_buttons_answer):
			buttons[i].pressed.connect(_buttons_answer.bind(buttons[i]))

func _buttons_answer(button) -> void:
	if answered:
		return  # Ignorar si ya se respondió esta pregunta
	
	answered = true  # Marcar como respondida

	var tex_rect = button.get_node("TextureRect") as TextureRect
	var selected_texture = tex_rect.texture

	# Mostrar imagen correspondiente
	if selected_texture == quiz.theme[index].correct:
		feedback_image.texture = imgCorrecto
		correct += 1
	else:
		feedback_image.texture = imgIncorrecto

	feedback_image.visible = true

	# Esperar 1.5 segundos, luego avanzar
	await get_tree().create_timer(1.5).timeout
	feedback_image.visible = false

	# Pasar a siguiente pregunta
	index += 1
	if index < quiz.theme.size():
		load_quiz()
	else:
		show_final_score()

func show_final_score():
	if correct == quiz.theme.size():  # todas correctas
		get_tree().change_scene_to_file("res://Scenes/Juegos/Adivina_el_Producto/Ganaste.tscn")
	else:
		get_tree().change_scene_to_file("res://Scenes/mapa.tscn")
	
