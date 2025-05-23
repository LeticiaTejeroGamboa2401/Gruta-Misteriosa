extends Control

func _ready():
	$VideoPlayer.play()

	# Activamos loop
	$VideoPlayer.loop = true

	# Esperamos 5 segundos y luego cambiamos de escena
	await get_tree().create_timer(5).timeout
	get_tree().change_scene_to_file("res://Scenes/bosque_nahual.tscn")
