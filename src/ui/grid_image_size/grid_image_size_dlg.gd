extends Window

signal refresh_grid

@onready var spinbox = $MarginContainer/HBoxContainer/SpinBox

func _ready():
	spinbox.value = Settings.grid_image_size

func _on_ButtonOK_pressed():
	Settings.grid_image_size = spinbox.value
	emit_signal("refresh_grid") # update config file

func _on_close_requested():
	hide()