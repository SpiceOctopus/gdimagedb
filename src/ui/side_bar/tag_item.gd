extends Control

signal add(tag)
signal remove(tag)
signal x(tag)

var selected : bool = false : set=set_selected

var tag

@onready var tag_label = $HBoxContainer2/Tag
@onready var remove_button = $HBoxContainer2/HBoxContainer/Remove
@onready var add_button = $HBoxContainer2/HBoxContainer/Add
@onready var x_button = $HBoxContainer2/HBoxContainer/X

func _ready():
	remove_button.custom_minimum_size.x = remove_button.size.y
	add_button.custom_minimum_size.x = add_button.size.y
	x_button.custom_minimum_size.x = x_button.size.y
	custom_minimum_size.y = add_button.size.y
	tag_label.text = tag["tag"]

func _on_add_pressed():
	emit_signal("add", tag)
	hide()

func _on_remove_pressed():
	emit_signal("remove", tag)
	hide()

func _on_x_pressed():
	emit_signal("x", tag)
	hide()

func set_selected(value : bool):
	selected = value
	if value:
		tag_label.text = "> " + tag["tag"]
	else:
		tag_label.text = tag["tag"]

func reset():
	visible = true
	selected = false
	if tag in GlobalData.excluded_tags:
		tag_label.set("theme_override_colors/font_color", Color.ORANGE_RED)
	elif tag in GlobalData.included_tags:
		tag_label.set("theme_override_colors/font_color", Color.LIME_GREEN)
	else:
		tag_label.set("theme_override_colors/font_color", Color.WHITE)

func set_button_visibility(add_visible : bool, remove_visible : bool, x_visible : bool):
	add_button.visible = add_visible
	remove_button.visible = remove_visible
	x_button.visible = x_visible
