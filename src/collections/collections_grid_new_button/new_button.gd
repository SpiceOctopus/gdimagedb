extends Control

signal new_collection

func _on_button_pressed():
	emit_signal("new_collection")
