extends CharacterBody2D


func _ready() -> void:
	$AnimatedSprite2D.play("nado")
	visible = true
