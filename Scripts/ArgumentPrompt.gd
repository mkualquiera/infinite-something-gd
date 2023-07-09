extends Panel
class_name ArgumentPrompt

var questions: Array
var answers: Array
var current_index: int = 0

@onready var label = $Label
@onready var text = $TextEdit

signal on_questions_answered(answers)

# Called when the node enters the scene tree for the first time.
func _ready():
	hide()
	pass # Replace with function body.
	
func ask_questions(_questions):
	questions = _questions
	answers = []
	current_index = -1
	show()
	update_questions(false)
	
func update_questions(store=true):
	if store:
		var question = questions[current_index]
		answers.append(question + "=" + text.text)
	current_index+=1
	if len(questions) == len(answers):
		emit_signal("on_questions_answered", answers)
		hide()
		return
	label.text = questions[current_index]
	text.text = ""

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

