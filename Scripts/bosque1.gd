extends Area2D

func _ready() -> void:
	$HuayChivo.visible = false

func _on_body_entered(body: Node) -> void:
	if body.name == "Lucy_Player" or body.name == "Lele_Player":
		$HuayChivo.visible = true
		await get_tree().create_timer(3.0).timeout
		get_tree().change_scene_to_file("res://Scenes/historia2.tscn")
