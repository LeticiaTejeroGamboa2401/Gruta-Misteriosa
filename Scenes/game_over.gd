extends Sprite2D

# Tiempo (en segundos) que se mostrará la pantalla Game Over antes de regresar
@export var delay_seconds: float = 3.0
# Ruta de la escena de selección de armas (nombre real en el proyecto)
@export var next_scene_path: String = "res://Scenes/weapon_selection.tscn"

var _transitioning: bool = false

func _ready() -> void:
    # Iniciar la transición diferida para asegurar que el árbol esté listo
    call_deferred("_begin_timer")

func _begin_timer() -> void:
    # Intentar corregir la ruta si la principal no existe
    if not FileAccess.file_exists(next_scene_path):
        var alternatives := [
            "res://Scenes/Seleccion_Armas.tscn",
            "res://Seleccion_Armas.tscn"
        ]
        for alt in alternatives:
            if FileAccess.file_exists(alt):
                next_scene_path = alt
                break
    # Esperar el tiempo configurado y luego cambiar de escena
    await get_tree().create_timer(delay_seconds).timeout
    _do_transition()

func _unhandled_input(event: InputEvent) -> void:
    # Permitir que el jugador acelere la transición con una tecla o clic
    if _transitioning:
        return
    if event is InputEventKey and event.pressed:
        _do_transition()
    elif event is InputEventMouseButton and event.pressed:
        _do_transition()

func _do_transition() -> void:
    if _transitioning:
        return
    _transitioning = true
    if FileAccess.file_exists(next_scene_path):
        get_tree().change_scene_to_file(next_scene_path)
    else:
        push_warning("No se encontró la escena de selección de armas: %s" % next_scene_path)
