extends Window

@onready var control = $NewCollection

func _on_close_requested():
	hide()
	control.txt_name.text = ""
	control.btn_accept.disabled = true

func _on_about_to_popup():
	control.txt_name.grab_focus()
	control.refresh()

func _on_new_collection_create_new():
	_on_close_requested()
