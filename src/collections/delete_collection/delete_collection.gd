extends Window

signal deleted

var collection : set=set_collection

@onready var message = $MarginContainer/VBoxContainer/Label

func set_collection(collection_in):
	collection = collection_in
	message.text = "Delete collection \"%s\"?" % collection["collection"]

func _on_cancel_button_pressed():
	hide()

func _on_ok_button_pressed():
	DB.delete_collection(collection["id"])
	emit_signal("deleted")
	hide()

func _on_close_requested():
	hide()
