extends Control

@onready var item_count = $MarginContainer/HBoxContainer/ValuesContainer/ItemCountValue
@onready var loading_label = $MarginContainer/LoadingLabel

func set_grid_items_count(count : int) -> void:
	$MarginContainer/HBoxContainer.visible = true
	loading_label.visible = false
	item_count.text = str(count)
