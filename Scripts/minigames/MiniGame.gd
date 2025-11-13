extends Control
class_name MiniGame

signal finished(success: bool, score: int)

var _config: Dictionary = {}
var _running: bool = false

func start(config := {}):
	# Debe ser llamado por el integrador justo después de instanciar
	_config = config
	_running = true
	set_process(true)

func _end(success: bool, score: int) -> void:
	if not _running:
		return
	_running = false
	emit_signal("finished", success, clamp(score, 0, 100))
	queue_free()

func cancel() -> void:
	_end(false, 0)
