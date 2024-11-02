extends Window

var collection : set=set_collection

@onready var message = $MarginContainer/VBoxContainer/Label

func set_collection(collection_in) -> void:
	collection = collection_in
	message.text = "Delete collection \"%s\"?" % collection["collection"]

func _on_cancel_button_pressed() -> void:
	hide()

func _on_ok_button_pressed() -> void:
	DB.delete_collection(collection["id"])
	GlobalData.notify_collection_deleted(collection["id"])
	hide()

func _on_close_requested() -> void:
	hide()
