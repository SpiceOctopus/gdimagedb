extends Control

var collection_editor_tile = load("res://collections/collection_editor_tile/collection_editor_tile.tscn")

var last_window_size : Vector2i
var collection : get=get_collection, set=set_collection # row from the collections table
var collection_internal

@onready var grid = $HBoxContainer/Panel/MarginContainer/ScrollContainer/Grid
@onready var scroll_container = $HBoxContainer/Panel/MarginContainer/ScrollContainer
@onready var delete_confirmation = $ConfirmationDialog
@onready var side_bar = $HBoxContainer/SideBar

func _ready():
	rebuild_grid()
	side_bar.collection = collection

func _process(_delta):
	var new_size = get_parent().size
	if new_size != last_window_size:
		last_window_size = new_size
		window_size_changed()

func window_size_changed():
	var columns = floor(scroll_container.size.x / Settings.grid_image_size)
	if  columns < 1:
		grid.columns = 1
	else:
		grid.columns = columns

func tile_move_left(image):
	var image_pos = DB.get_position_in_collection(image["id"], collection["id"])
	DB.swap_positions_in_collection(image, DB.get_collection_image_by_position(collection["id"], (image_pos - 1)), collection)
	rebuild_grid()

func tile_move_right(image):
	var image_pos = DB.get_position_in_collection(image["id"], collection["id"])
	DB.swap_positions_in_collection(image, DB.get_collection_image_by_position(collection["id"], (image_pos + 1)), collection)
	rebuild_grid()

func tile_delete(image):
	delete_confirmation.image = image
	delete_confirmation.popup_centered()

func rebuild_grid():
	for tile in get_tree().get_nodes_in_group("collection_editor_grid_tiles"):
		tile.remove_from_group("collection_editor_grid_tiles")
		tile.queue_free()
	
	var images = DB.get_all_images_in_collection(collection["id"])
	images.sort_custom(compare_by_position)
	for image in images:
		var tile = collection_editor_tile.instantiate()
		tile.image = image
		tile.collection = collection
		tile.connect("move_left", tile_move_left)
		tile.connect("move_right", tile_move_right)
		tile.connect("delete", tile_delete)
		tile.add_to_group("collection_editor_grid_tiles")
		grid.add_child(tile)

func compare_by_position(a, b):
	return a["position"] < b["position"]

func set_collection(collection_in):
	collection_internal = collection_in

func get_collection():
	return collection_internal

func _on_confirmation_dialog_confirmed():
	DB.remove_image_from_collection(delete_confirmation.image["id"], collection["id"])
	var images = DB.get_all_images_in_collection(collection["id"])
	images.sort_custom(compare_by_position)
	
	var counter = 0
	for img in images:
		DB.set_position_in_collection(img["id"], collection["id"], counter)
		counter += 1
	
	rebuild_grid()
