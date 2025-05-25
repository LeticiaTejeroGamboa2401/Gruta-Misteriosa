extends Control

var murcielago_escena = preload("res://Scenes/Murcielago_Volando.tscn")

func _ready():
	

	var posiciones = [Vector2(1000, 100), Vector2(750, 200), Vector2(600, 100)]

	for pos in posiciones:
		var murcielago = murcielago_escena.instantiate()
		add_child(murcielago)
		murcielago.position = pos
		murcielago.visible = true
