extends Area2D


func _on_body_entered(body: Node) -> void:
	if body.name == "Lucy_Player" or body.name == "Lele_Player":
		call_deferred("_change_scene")


func _change_scene():
		get_tree().change_scene_to_file("res://Scenes/DentroCueva.tscn")
