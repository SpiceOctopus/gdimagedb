extends Window

signal refresh_grid

@onready var spinbox = $MarginContainer/HBoxContainer/SpinBox

func _ready() -> void:
	spinbox.value = Settings.grid_image_size

func _on_ButtonOK_pressed() -> void:
	Settings.grid_image_size = spinbox.value
	refresh_grid.emit() # update config file

func _on_close_requested() -> void:
	hide()
