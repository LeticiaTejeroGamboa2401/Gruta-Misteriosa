extends CharacterBody2D


func _ready() -> void:
	$AnimatedSprite2D.play("arriba-abajo")
	visible = true
