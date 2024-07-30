extends Window

@onready var textbox = $MarginContainer/VBoxContainer/TextEdit

func _ready():
	self.connect('close_requested', Callable(self,'hide'))

func add_message(message: String):
	textbox.text += message + "\n"

func clear_messages():
	textbox.text = ""

func _on_button_pressed():
	hide()
