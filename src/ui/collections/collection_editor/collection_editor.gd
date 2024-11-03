extends Window

signal name_changed(collection : DBCollection)

var collection_editor_tile = load("res://ui/collections/collection_editor_tile/collection_editor_tile.tscn")

var last_window_size : Vector2i
var collection : DBCollection : set=set_collection # row from the collections table

@onready var grid = $HBoxContainer/Panel/MarginContainer/ScrollContainer/Grid
@onready var scroll_container = $HBoxContainer/Panel/MarginContainer/ScrollContainer
@onready var delete_confirmation = $RemoveFromCollection
@onready var side_bar = $HBoxContainer/VBoxContainer/SideBar
@onready var name_edit = $HBoxContainer/VBoxContainer/Panel/MarginContainer/HBoxContainer/NameEdit
@onready var apply_name_button = $HBoxContainer/VBoxContainer/Panel/MarginContainer/HBoxContainer/ApplyButton

func _process(_delta : float) -> void:
	var new_size = size
	if new_size != last_window_size:
		last_window_size = new_size
		window_size_changed()

func set_collection(collection_in : DBCollection) -> void:
	collection = collection_in
	name_edit.text = collection.name
	side_bar.media_id = collection.id
	side_bar._on_display_changed()
	rebuild_grid()

func window_size_changed() -> void:
	var columns = floor(scroll_container.size.x / Settings.grid_image_size)
	if  columns < 1:
		grid.columns = 1
	else:
		grid.columns = columns

func tile_move_left(media : DBMedia) -> void:
	var image_pos = DB.get_position_in_collection(media.id, collection.id)
	DB.swap_positions_in_collection(media, DB.get_collection_image_by_position(collection.id, (image_pos - 1)), collection)
	rebuild_grid()
	if DB.get_position_in_collection(media.id, collection.id) == 0:
		GlobalData.notify_db_collections_changed()

func tile_move_right(media : DBMedia) -> void:
	var image_pos = DB.get_position_in_collection(media.id, collection.id)
	DB.swap_positions_in_collection(media, DB.get_collection_image_by_position(collection.id, (image_pos + 1)), collection)
	rebuild_grid()
	GlobalData.notify_db_collections_changed()
	if DB.get_position_in_collection(media.id, collection.id) == 0:
		GlobalData.notify_db_collections_changed()

func tile_delete(media : DBMedia) -> void:
	delete_confirmation.media = media
	delete_confirmation.popup_centered()

func rebuild_grid() -> void:
	for tile in get_tree().get_nodes_in_group("collection_editor_grid_tiles"):
		tile.remove_from_group("collection_editor_grid_tiles")
		tile.queue_free()
	
	var db_media : Array[DBMedia] = DB.get_all_images_in_collection(collection.id)
	db_media.sort_custom(compare_by_position)
	for media : DBMedia in db_media:
		var tile = collection_editor_tile.instantiate()
		tile.media = media
		tile.collection_id = collection.id
		tile.move_left.connect(tile_move_left)
		tile.move_right.connect(tile_move_right)
		tile.delete.connect(tile_delete)
		tile.add_to_group("collection_editor_grid_tiles")
		grid.add_child(tile)

func compare_by_position(a : DBMedia, b : DBMedia) -> bool:
	return a.position < b.position

func _on_name_edit_text_changed(new_text : String) -> void:
	apply_name_button.disabled = new_text.is_empty()

func _on_apply_button_pressed() -> void:
	DB.set_collection_name(collection.id, name_edit.text)
	collection.name = name_edit.text
	name_changed.emit(collection)

func _on_close_requested() -> void:
	hide()

func _on_about_to_popup() -> void:
	side_bar.focus()
	side_bar.clear_filter_text()

# confirmed = remove image from collection
func _on_remove_from_collection_confirmed() -> void:
	DB.remove_image_from_collection(delete_confirmation.media.id, collection.id)
	var media : Array[DBMedia] = DB.get_all_images_in_collection(collection.id)
	media.sort_custom(compare_by_position)
	
	var counter = 0
	for entry in media:
		DB.set_position_in_collection(entry.id, collection.id, counter)
		counter += 1
	
	rebuild_grid()
	GlobalData.notify_db_collections_changed()
