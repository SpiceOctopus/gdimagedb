extends Control

signal fit_to_window
signal original_size
signal stretch_mode_changed

@onready var stretch_mode_selector = $HBoxContainer/ViewerStretchMode

func _ready():
	stretch_mode_selector.selected = DB.get_setting_media_viewer_stretch_mode()

func _input(_event):
	if Input.is_action_just_pressed("menu_bar_1"):
		fit_to_window.emit()
	elif Input.is_action_just_pressed("menu_bar_2"):
		original_size.emit()

func _on_button_100_percent_pressed():
	original_size.emit()

func _on_viewer_stretch_mode_item_selected(index):
	DB.set_setting_media_viewer_stretch_mode(index)
	stretch_mode_changed.emit()

func _on_button_fit_to_window_pressed():
	fit_to_window.emit()
