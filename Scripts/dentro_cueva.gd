extends Control


func _ready():
	$sombra.visible = false  # Asegúrate de que esté oculto al iniciar

	await get_tree().create_timer(5).timeout
	_on_sombra_draw()

	await get_tree().create_timer(3).timeout
	get_tree().change_scene_to_file("res://Scenes/historia2.tscn")
	
func _on_sombra_draw() -> void:
	$sombra.visible = true
