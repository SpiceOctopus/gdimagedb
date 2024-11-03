extends Window

var linecount : int = 0

@onready var textbox = $MarginContainer/VBoxContainer/TextEdit

func add_message(message: String) -> void:
	linecount += 1
	textbox.text += message + "\n"
	textbox.scroll_vertical = linecount + 1 # scrolling to INF as recommended on the forums does not work in GD 4.3

func clear_messages() -> void:
	textbox.text = ""
	linecount = 0

func _on_button_pressed() -> void:
	hide()

func _on_close_requested() -> void:
	hide()
