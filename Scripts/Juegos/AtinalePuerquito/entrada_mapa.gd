extends Area2D


func _on_body_entered(body: Node) -> void:
	if body.name == "Lucy_Player" or body.name == "Lele_Player":
		Global.respawn_position = Vector2(908, 307) # reaparece más abajo
		Global.use_respawn_in_scene = "res://Scenes/Mapa.tscn"  # pon aquí el path real del mapa
		call_deferred("_change_scene")


func _change_scene():
		get_tree().change_scene_to_file("res://Scenes/Juegos/Atinale_al_Puerquito/Confirmar_Juego.tscn")
