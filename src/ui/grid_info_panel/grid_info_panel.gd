extends Control

@onready var item_count = $MarginContainer/HBoxContainer/ValuesContainer/ItemCountValue

func set_grid_items_count(count : int):
	item_count.text = str(count)
