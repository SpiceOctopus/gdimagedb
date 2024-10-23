extends Window

signal confirmed

var image

func _on_cancel_pressed():
	hide()

func _on_ok_pressed():
	confirmed.emit()
	hide()

func _on_close_requested():
	hide()
