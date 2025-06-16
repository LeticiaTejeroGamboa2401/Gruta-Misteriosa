extends Area2D

@onready var sprite = $AnimatedSprite2D
var ya_clickeado = false

func animar():
	if not ya_clickeado:
		sprite.play("click")
		ya_clickeado = true
