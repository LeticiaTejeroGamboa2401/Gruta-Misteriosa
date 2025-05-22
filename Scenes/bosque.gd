extends Control

var murcielago_escena = preload("res://Scenes/Murcielago_Volando.tscn")

func _ready():
	$HuayChivo.visible = false  # Asegúrate de que esté oculto al iniciar

	var posiciones = [Vector2(1000, 100), Vector2(750, 200), Vector2(600, 100)]

	for pos in posiciones:
		var murcielago = murcielago_escena.instantiate()
		add_child(murcielago)
		murcielago.position = pos
		murcielago.visible = true

	await get_tree().create_timer(5).timeout
	_on_huay_chivo_draw()

	await get_tree().create_timer(3).timeout
	get_tree().change_scene_to_file("res://Scenes/historia2.tscn")

func _on_huay_chivo_draw() -> void:
	$HuayChivo.visible = true
