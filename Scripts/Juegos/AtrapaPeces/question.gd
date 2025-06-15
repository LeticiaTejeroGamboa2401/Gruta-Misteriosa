extends Resource

class_name QuizQuestionPecesitos

@export var question_info: String
@export var question_img: Texture2D
@export var type: Enum.QuestionType
@export var options: Array[PackedScene]
@export var correct: PackedScene
