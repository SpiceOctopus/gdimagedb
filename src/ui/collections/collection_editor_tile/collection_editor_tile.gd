extends Control

signal delete(media : DBMedia)
signal move_left(media : DBMedia)
signal move_right(media : DBMedia)

var load_thread : Thread = Thread.new()
var media : DBMedia
var collection_id : int

@onready var display = $VBoxContainer/TextureRect
@onready var order_label = $VBoxContainer/HBoxContainer/OrderLabel
@onready var button_left = $VBoxContainer/HBoxContainer/MoveLeftButton
@onready var button_right = $VBoxContainer/HBoxContainer/MoveRightButton

func _ready() -> void:
	display.texture = CacheManager.get_thumbnail(media)
	display.custom_minimum_size = Vector2(Settings.grid_image_size, Settings.grid_image_size)
	custom_minimum_size = Vector2(Settings.grid_image_size, display.custom_minimum_size.y + $VBoxContainer/HBoxContainer.custom_minimum_size.y)
	update_ui()

func _on_btn_move_left_pressed() -> void:
	move_left.emit(media)

func _on_btn_move_right_pressed() -> void:
	move_right.emit(media)

func _on_delete_button_pressed() -> void:
	delete.emit(media)

func update_ui() -> void:
	order_label.text = str(media.position)
	
	button_left.disabled = false
	button_right.disabled = false
	
	if media.position <= 0: # first one
		button_left.disabled = true
	if media.position >= (DB.get_collection_count(collection_id) - 1): # last one
		button_right.disabled = true
