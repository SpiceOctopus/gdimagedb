extends Control

signal add(tag)
signal remove(tag)

var selected : bool = false : set=set_selected

var tag : DBTag

@onready var tag_label = $HBoxContainer/Tag
@onready var remove_button = $HBoxContainer/Remove
@onready var add_button = $HBoxContainer/Add

func _ready():
	remove_button.custom_minimum_size.x = remove_button.size.y
	add_button.custom_minimum_size.x = add_button.size.y
	custom_minimum_size.y = add_button.size.y
	if tag != null:
		tag_label.text = tag.tag

func _on_add_pressed():
	add.emit(tag)
	hide()

func _on_remove_pressed():
	remove.emit(tag)
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
