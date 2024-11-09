extends Control

signal x(tag)

var selected : bool = false : set=set_selected
var color_mode : bool = true

var tag : DBTag

@onready var tag_label = $HBoxContainer/Tag
@onready var x_button = $HBoxContainer/X

func _ready():
	x_button.custom_minimum_size.x = x_button.size.y
	custom_minimum_size.y = x_button.size.y
	if tag != null:
		tag_label.text = tag.tag

func _on_x_pressed():
	x.emit(tag)
	hide()

func set_selected(value : bool):
	selected = value
	if value:
		tag_label.text = "> " + tag.tag
	else:
		tag_label.text = tag.tag

func reset():
	visible = true
	selected = false
	if tag in GlobalData.excluded_tags && color_mode:
		tag_label.add_theme_color_override("font_color", Color.ORANGE_RED)
	elif tag in GlobalData.included_tags && color_mode:
		tag_label.add_theme_color_override("font_color", Color.LIME_GREEN)
	else:
		tag_label.add_theme_color_override("font_color", Color.WHITE)
