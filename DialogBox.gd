extends Control

var label

func _ready():
	label = Label.new()
	label.position = Vector2(20, 20)
	label.size = Vector2(600, 100)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(label)

func display_text(text):
	label.text = text
	# Add typewriter effect
	label.visible_characters = 0
	var tween = create_tween()
	tween.tween_property(label, "visible_characters", text.length(), 1.0)