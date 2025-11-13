extends Control

@export var auto_delay: float = 3.0
@export var selection_paths: Array[String] = [
	"res://Scenes/weapon_selection.tscn",
	"res://Scenes/Seleccion_Armas.tscn",
	"res://Seleccion_Armas.tscn"
]

func _ready() -> void:
	# Iniciar el temporizador de redirección al seleccionar armas
	call_deferred("_start_redirect")

func _start_redirect() -> void:
	await get_tree().create_timer(auto_delay).timeout
	for p in selection_paths:
		if FileAccess.file_exists(p):
			get_tree().change_scene_to_file(p)
			return
	push_warning("No se encontró la escena de selección de armas; permanece en TryAgain.")
