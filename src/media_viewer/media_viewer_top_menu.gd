extends Control

signal fit_to_window
signal original_size
signal stretch_mode_changed

@onready var stretch_mode_selector = $HBoxContainer/ViewerStretchMode

func _ready():
	stretch_mode_selector.selected = DB.get_setting_media_viewer_stretch_mode()

func _input(_event):
	if Input.is_action_just_pressed("menu_bar_1"):
		emit_signal("fit_to_window")
	elif Input.is_action_just_pressed("menu_bar_2"):
		emit_signal("original_size")

func _on_button_100_percent_pressed():
	emit_signal("original_size")

func _on_viewer_stretch_mode_item_selected(index):
	DB.set_setting_media_viewer_stretch_mode(index)
	emit_signal("stretch_mode_changed")

func _on_button_fit_to_window_pressed():
	emit_signal("fit_to_window")
