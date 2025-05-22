extends CharacterBody2D

@export var velocidad: float = -60

func _ready():
	$AnimatedSprite2D.play("Vuelo")
	visible = true

func _physics_process(delta):
	velocity.x = velocidad
	move_and_slide()
