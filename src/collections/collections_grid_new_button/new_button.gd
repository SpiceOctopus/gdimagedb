extends Control

@onready var dialog = $NewCollection

func _on_button_pressed():
	dialog.popup_centered()
