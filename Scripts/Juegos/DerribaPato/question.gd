extends Resource

class_name QuizQuestionPatito

@export var question_info: String
@export var type: Enum.QuestionType
@export var options: Array[PackedScene]
@export var correct: PackedScene
