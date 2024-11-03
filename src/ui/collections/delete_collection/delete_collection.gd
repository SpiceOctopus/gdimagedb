extends Window

var collection : DBCollection :
	set(collection_in):
		collection = collection_in
		message.text = "Delete collection \"%s\"?" % collection.name

@onready var message = $MarginContainer/VBoxContainer/Label

func _on_ok_button_pressed() -> void:
	DB.delete_collection(collection.id)
	GlobalData.notify_collection_deleted(collection.id)
	hide()

func _on_cancel_button_pressed() -> void:
	hide()

func _on_close_requested() -> void:
	hide()
