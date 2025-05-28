extends Node

var current_track = ""

func play_music(path: String):
	if current_track == path:
		return  # Ya está sonando esta canción
	current_track = path
	var audio = load(path)
	if audio is AudioStream:
		audio.loop = true  # Activar loop por código
	$MusicPlayer.stream = audio
	$MusicPlayer.play()
