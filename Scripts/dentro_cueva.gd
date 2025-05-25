extends Area2D


func _ready() -> void:
	$sombra.visible = false

func _on_body_entered(body: Node) -> void:
	if body.name == "Lucy_Player" or body.name == "Lele_Player":
		$sombra.visible = true
		await get_tree().create_timer(3).timeout
		get_tree().change_scene_to_file("res://Scenes/historia4.tscn")
