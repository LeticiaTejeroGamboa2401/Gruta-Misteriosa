extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Lucy_Player" or body.name == "Lele_Player":
		if not Global.juegos_ganados["juego_peces"]:
			Global.use_respawn_in_scene = "res://Scenes/Mapa.tscn"
			call_deferred("_change_scene")
		else:
			print("Ya ganaste este juego. No puedes volver a entrar.")


func _change_scene():
		get_tree().change_scene_to_file("res://Scenes/Juegos/Atrapa_Peces/Confirmacion_Juego.tscn")
