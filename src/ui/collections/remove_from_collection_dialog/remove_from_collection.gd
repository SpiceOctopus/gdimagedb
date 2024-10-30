extends Window

signal confirmed

var media : DBMedia

func _on_cancel_pressed():
	hide()

func _on_ok_pressed():
	confirmed.emit()
	hide()

func _on_close_requested():
	hide()
