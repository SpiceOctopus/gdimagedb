extends Control

signal new_collection

func _on_button_pressed():
	new_collection.emit()
