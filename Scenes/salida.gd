extends Area2D


func _change_scene():
	get_tree().change_scene_to_file("res://Scenes/AluxEncuentroFinal.tscn")


func _on_body_entered(body: Node2D) -> void:
	var isAllGamesCompleted = true
	#for isDone in Global.juegos_ganados.values():
		#if not isDone:
			#isAllGamesCompleted = false
			#return
	if isAllGamesCompleted:
		_change_scene()
