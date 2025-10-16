extends Node

# Personaje seleccionado
var selected_character_scene: PackedScene = null
var selected_character_name: String = ""
var selected_weapon = ""
var selected_weapon_texture: Texture2D = null

# Reaparición en el mapa
var respawn_position: Vector2 = Vector2(100, 250) # Posición por defecto
var use_respawn_in_scene: String = "res://Scenes/mapa.tscn"

# Status de los juegos
var juegos_ganados = {
	"juego_puerquito": false,
	"juego_patito": false,
	"juego_producto": false,
	"juego_caballo": false,
	"juego_peces": false,
	"juego_dardos": false,
	"juego_ruleta": false,
}

# Vidas en el juego del nahual
var lives: int = 3

var ruleta_rotation := 0.0
var area_seleccionada := ""
var total_rondas: int = 5
var ronda_actual: int = 0
var respuestas_correctas: int = 0
