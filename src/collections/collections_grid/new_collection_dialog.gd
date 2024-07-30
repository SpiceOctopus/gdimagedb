extends Window

@onready var control = $MarginContainer/NewCollection

func _on_close_requested():
	hide()
	control.txt_name.text = ""
	control.btn_accept.disabled = true

func _on_about_to_popup():
	control.txt_name.grab_focus()

func _on_new_collection_create_new():
	_on_close_requested()
