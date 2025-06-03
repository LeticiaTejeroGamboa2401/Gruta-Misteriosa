extends Node

# Personaje seleccionado
var selected_character_scene: PackedScene = null
var selected_character_name: String = ""

# Reaparición en el mapa
var respawn_position: Vector2 = Vector2(100, 250)  # Posición por defecto
var use_respawn_in_scene: String = "res://Scenes/mapa.tscn"

# Status de los juegos
var juegos_ganados = {
	"juego_puerquito": false,
	"juego_patito": false,
	"juego_producto": false,
	"juego_caballo": false,
}
