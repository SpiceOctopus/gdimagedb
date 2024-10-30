extends Control

signal add(tag)

var selected : bool = false : set=set_selected

var tag

@onready var tag_label : Label = $HBoxContainer/Tag
@onready var add_button = $HBoxContainer/ShaderButtonPlus

func _ready() -> void:
	custom_minimum_size.y = add_button.size.y
	if tag != null:
		tag_label.text = tag["tag"]

func _on_add_pressed() -> void:
	add.emit(tag)
	hide()

func set_selected(value : bool) -> void:
	selected = value
	if value:
		tag_label.text = "> " + tag["tag"]
	else:
		tag_label.text = tag["tag"]

func reset() -> void:
	visible = true
	selected = false
