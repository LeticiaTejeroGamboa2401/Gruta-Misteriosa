extends Control

func _ready():
	$VideoPlayer.play()

	# Esperamos 5 segundos y luego cambiamos de escena
	await get_tree().create_timer(9).timeout
	#get_tree().change_scene_to_file("res://Scenes/Efecto2.tscn") <- debería dirigirse al mapa
