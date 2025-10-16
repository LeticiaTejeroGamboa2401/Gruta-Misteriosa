extends Node2D

# Variables del juego
var correct_answers = 0
var answers_needed = 3
var questions_attempted = 0
var total_questions = 5

# Sistema de bloqueo para evitar interacciones múltiples
var is_processing_answer = false
var is_showing_feedback = false
var can_show_next_question = true

var dialogs = [
	"¡Guerrero valiente! Has reunido los seis fragmentos sagrados.",
	"Para fusionarlos, debes demostrar tu sabiduría una vez más.",
	"Responde correctamente a tres de mis cinco preguntas.",
	"¡El amuleto está completo! \nToma su poder.",
	"¡Oh no! No has logrado completar los retos.\n¿Estás seguro de haber completado todas las pruebas del pueblo?"
]

var current_dialog = 0
var showing_final = false
var showing_fail = false

## Banco de preguntas contextualizado para Yucatán, matemáticas 5°-6° primaria
var question_bank = [
	{"text": "En una feria, Juan compró 3 bolsas de naranjas con 8 naranjas cada una. ¿Cuántas naranjas compró en total?",
	 "options": ["24 naranjas ✅", "11 naranjas", "18 naranjas"],
	 "correct": 0},

	{"text": "Si una guayabera cuesta $250 y tienes $600, ¿cuánto te sobra después de comprar una?",
	 "options": ["$350 ✅", "$400", "$250"],
	 "correct": 0},

	{"text": "En una charola hay 36 panuchos. Si se reparten entre 6 niños por igual, ¿cuántos panuchos recibe cada uno?",
	 "options": ["6 ✅", "5", "8"],
	 "correct": 0},

	{"text": "Una pirámide maya tiene 4 lados iguales y cada lado mide 12 metros. ¿Cuál es el perímetro?",
	 "options": ["48 metros ✅", "36 metros", "24 metros"],
	 "correct": 0},

	{"text": "Si en una jarra hay 2 litros de horchata y cada vaso sirve 250 ml, ¿cuántos vasos puedes llenar?",
	 "options": ["8 vasos ✅", "6 vasos", "10 vasos"],
	 "correct": 0}
]
var selected_questions = []

# Sistema de feedback
@onready var feedback = $UI/Feedback
var correct_img = preload("res://images/respuesta_correcta.png")
var incorrect_img = preload("res://images/respuesta_incorrecta.png")

# Referencias a nodos UI para mejor rendimiento
@onready var dialog_popup = $UI/DialogPopup
@onready var dialog_label = $UI/DialogPopup/DialogLabel
@onready var problem_popup = $UI/ProblemPopup
@onready var question_label = $UI/ProblemPopup/QuestionLabel
@onready var option_buttons = $UI/ProblemPopup/OptionButtons
@onready var counter_label = $UI/CounterLabel
@onready var next_button = $UI/DialogPopup/NextButton
@onready var amulet_complete = $AmuletComplete
@onready var animation_player = $AmuletComplete/AnimationPlayer

func _ready():
	randomize()
	setup_questions()
	spawn_player()
	init_ui()
	# Iniciar animación del amuleto PRIMERO (después de 1 segundo)
	start_amulet_animation_delayed()
	# Esperar a que pase el delay antes de mostrar diálogos
	await get_tree().create_timer(1.0).timeout
	show_dialog()

func setup_questions():
	question_bank.shuffle()
	selected_questions = question_bank.slice(0, total_questions)

	# Mezclar opciones para cada pregunta de manera más segura
	for q in selected_questions:
		var correct_option = q["options"][q["correct"]]
		q["options"].shuffle()
		q["correct"] = q["options"].find(correct_option)

func spawn_player():
	if Global.selected_character_scene:
		var player = Global.selected_character_scene.instantiate()
		player.name = Global.selected_character_name
		add_child(player)
		player.position = $PlayerSpawnPoint.position

func init_ui():
	# El amuleto debe estar visible desde el inicio
	amulet_complete.visible = true
	problem_popup.hide()
	dialog_popup.hide()
	feedback.hide()
	update_counter_display()
	_connect_signals()

func start_amulet_animation_delayed():
	# Esperar 1 segundo antes de iniciar la animación del amuleto
	await get_tree().create_timer(1.0).timeout
	if animation_player:
		animation_player.play("amulet_glow")

func fade_out_amulet():
	# Hacer fade-out del amuleto antes de comenzar las preguntas
	if amulet_complete:
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(amulet_complete, "modulate:a", 0.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await tween.finished
		amulet_complete.visible = false

func update_counter_display():
	if correct_answers >= answers_needed:
		counter_label.text = "¡Completado! %d/%d" % [correct_answers, answers_needed]
	else:
		counter_label.text = "Aciertos: %d/%d\nPreguntas: %d/%d" % [correct_answers, answers_needed, questions_attempted, total_questions]

func show_dialog():
	if showing_final:
		show_final_dialog()
	elif showing_fail:
		show_fail_dialog()
	elif current_dialog < 3:
		show_sequence_dialog()

func show_final_dialog():
	dialog_label.text = dialogs[3]
	dialog_popup.show()

func show_fail_dialog():
	dialog_label.text = dialogs[4]
	dialog_popup.show()

func show_sequence_dialog():
	dialog_label.text = dialogs[current_dialog]
	dialog_popup.show()

func _on_next_pressed():
	# Evitar múltiples clics
	if is_processing_answer:
		return

	dialog_popup.hide()

	if showing_final:
		complete_amulet()
	elif showing_fail:
		restart_challenge()
	else:
		current_dialog += 1
		if current_dialog >= 3 && correct_answers < answers_needed:
			# Hacer fade-out del amuleto antes de mostrar preguntas
			await fade_out_amulet()
			show_question()
		else:
			show_dialog()

func show_question():
		# Solo mostrar pregunta si no estamos procesando
		if not can_show_next_question or questions_attempted >= total_questions:
			return

		var q = selected_questions[questions_attempted]
		question_label.text = q["text"]
		# Cambiar color de texto a negro (Godot 4)
		question_label.add_theme_color_override("font_color", Color(0, 0, 0))

		# Configurar botones de opciones
		for i in range(min(3, option_buttons.get_child_count())):
			var button = option_buttons.get_child(i)
			button.text = q["options"][i]
			button.disabled = false # Asegurar que estén habilitados

		problem_popup.show()

func _on_answer_selected(index):
	# Sistema de bloqueo robusto
	if is_processing_answer or is_showing_feedback:
		return

	is_processing_answer = true
	can_show_next_question = false

	# Deshabilitar todos los botones para evitar múltiples clics
	disable_option_buttons()

	var q = selected_questions[questions_attempted]
	var is_correct = (index == q["correct"])

	# Mostrar feedback y esperar
	await show_feedback(is_correct)

	# Procesar respuesta
	handle_answer(is_correct)
	questions_attempted += 1
	update_counter_display()

	# Reactivar sistema después del feedback
	is_processing_answer = false
	can_show_next_question = true

	# Continuar con el flujo
	check_progress()

func disable_option_buttons():
	for i in range(option_buttons.get_child_count()):
		option_buttons.get_child(i).disabled = true

func enable_option_buttons():
	for i in range(option_buttons.get_child_count()):
		option_buttons.get_child(i).disabled = false

func show_feedback(is_correct: bool):
	is_showing_feedback = true

	# Configurar imagen de feedback
	feedback.texture = correct_img if is_correct else incorrect_img

	# Ocultar popup de pregunta y mostrar feedback
	problem_popup.hide()
	feedback.show()

	# Esperar tiempo definido para el feedback
	await get_tree().create_timer(1.5).timeout

	# Ocultar feedback
	feedback.hide()
	is_showing_feedback = false

func handle_answer(is_correct: bool):
	if is_correct:
		correct_answers += 1
		# Opcional: reproducir sonido de acierto
		# AudioManager.play_sound("correct")
	else:
		# Opcional: reproducir sonido de error
		# AudioManager.play_sound("incorrect")
		pass

func check_progress():
	if correct_answers >= answers_needed:
		showing_final = true
		show_dialog()
	elif questions_attempted >= total_questions:
		showing_fail = true
		show_dialog()
	else:
		# Pequeña pausa antes de mostrar la siguiente pregunta
		await get_tree().create_timer(0.5).timeout
		show_question()

func complete_amulet():
	amulet_complete.visible = true
	animation_player.play("amulet_glow")
	#Global.amulet_complete = true

	# Esperar solo 1 segundo en lugar de esperar toda la animación
	await get_tree().create_timer(1.0).timeout

	# Iniciar fade out inmediatamente
	var fade_rect = $FadeRect
	var tween = create_tween()
	fade_rect.modulate.a = 0.0 # Asegurar que empieza transparente
	tween.tween_property(fade_rect, "modulate:a", 1.0, 1.0) # Fade a negro en 1.0s (más rápido)

	await tween.finished

	# Cambiar escena
	get_tree().change_scene_to_file("res://Scenes/weapon_selection.tscn")

func restart_challenge():
	# Reiniciar variables de estado
	reset_game_state()

	# Reiniciar UI
	update_counter_display()
	problem_popup.hide()
	feedback.hide()

	# Generar nuevas preguntas
	setup_questions()

	# Volver al diálogo de preguntas
	current_dialog = 2
	show_dialog()

func reset_game_state():
	correct_answers = 0
	questions_attempted = 0
	showing_fail = false
	is_processing_answer = false
	is_showing_feedback = false
	can_show_next_question = true

func _connect_signals():
	# Conectar señal del botón siguiente
	if next_button.pressed.is_connected(_on_next_pressed):
		next_button.pressed.disconnect(_on_next_pressed)
	next_button.pressed.connect(_on_next_pressed)

	# Conectar botones de opciones
	for i in range(option_buttons.get_child_count()):
		var button = option_buttons.get_child(i)
		if button.pressed.is_connected(_on_answer_selected):
			button.pressed.disconnect(_on_answer_selected)
		button.pressed.connect(_on_answer_selected.bind(i))

# Función de utilidad para debugging
func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F1:
			print("Debug Info:")
			print("- Processing answer: ", is_processing_answer)
			print("- Showing feedback: ", is_showing_feedback)
			print("- Can show next: ", can_show_next_question)
			print("- Questions attempted: ", questions_attempted)
			print("- Correct answers: ", correct_answers)
