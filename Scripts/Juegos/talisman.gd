extends Control


func _ready():
	MusicManager.play_music("res://audio/triunfo.ogg")
	await get_tree().create_timer(5.0).timeout
	get_tree().quit()
	
