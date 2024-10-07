extends Control

signal grid_updated
signal edit_collection

var new_button_instance = load("res://collections/collections_grid_new_button/new_button.tscn").instantiate()
var grid_tile_instance = load("res://collections/collections_grid_tile/grid_tile.tscn").instantiate()
var viewer_instance = load("res://media_viewer/media_viewer.tscn").instantiate()

var db_collections = [] # to be filled with all collections available in the database
var tiles = {} # cached tiles for the grid

@onready var grid_container = $MarginContainer/ScrollContainer/GridContainer
@onready var last_window_size = Vector2i(0,0)
@onready var delete_dialog = $DeleteCollection
@onready var popup_menu = $PopupMenu

func _ready():
	refresh_grid()
	GlobalData.connect("favorites_changed", refresh_grid)
	GlobalData.connect("untagged_changed", refresh_grid)
	GlobalData.connect("tags_changed", refresh_grid)
	GlobalData.connect("db_collections_changed", refresh_grid)
	GlobalData.connect("collection_deleted", _on_collection_deleted)

func _process(_delta):
	var new_size = DisplayServer.window_get_size()
	if new_size != last_window_size:
		last_window_size = new_size
		window_size_changed()

func refresh_grid():
	if grid_container.get_children().has(new_button_instance):
		grid_container.remove_child(new_button_instance) # remove here, add back to the end
	
	for tile in tiles.values():
		tile.visible = false
	
	db_collections = DB.get_all_collections()
	
	for collection in db_collections:
		if !tiles.has(collection["id"]):
			var instance = grid_tile_instance.duplicate()
			instance.custom_minimum_size = Vector2(Settings.grid_image_size, Settings.grid_image_size)
			instance.connect("double_click", tile_double_click)
			instance.connect("right_click", tile_right_click)
			instance.visible = false
			grid_container.add_child(instance)
			instance.collection = collection
			tiles[collection["id"]] = instance
	
	new_button_instance.custom_minimum_size = Vector2(Settings.grid_image_size, Settings.grid_image_size)
	grid_container.add_child(new_button_instance)
	
	var collections_without_tags = DB.get_ids_collections_without_tags()
	var current_tiles = {}
	
	if !((GlobalData.included_tags.size() > 0) || (GlobalData.excluded_tags.size() > 0)):
		current_tiles = tiles
	else:
		for collection in DB.get_collections_for_tags(GlobalData.included_tags, GlobalData.excluded_tags):
			current_tiles[collection["id"]] = tiles[collection["id"]]
	
	for tile in current_tiles.values():
		if GlobalData.show_favorites && !tile.collection["fav"]:
			pass
		elif GlobalData.show_untagged && !(tile.collection["id"] in collections_without_tags):
			pass
		else:
			tile.visible = true
	
	grid_updated.emit()

func tile_double_click(collection):
	var instance = viewer_instance.duplicate()
	var images = DB.get_all_images_in_collection(collection["id"])
	images.sort_custom(compare_by_position)
	instance.images = images
	
	# add code to resume collection from last seen image
	
	#for image in images:
	#	if image["id"] == senderImage["id"]:
	#		instance.current_image = images.find(image)
	
	var window = Window.new()
	window.hide()
	get_tree().get_root().add_child(window)
	window.size = DisplayServer.window_get_size()
	if DisplayServer.window_get_mode() == 2: # 2 = maximized. Not sure how to address the enum properly
		window.mode = Window.MODE_MAXIMIZED
	window.add_child(instance)
	window.title = collection["collection"]
	window.popup_centered()
	window.connect("close_requested", Callable(window, "queue_free"))

func compare_by_position(a, b):
	return a["position"] < b["position"]

func tile_right_click(collection):
	$PopupMenu.position = DisplayServer.mouse_get_position()
	$PopupMenu.collection = collection
	$PopupMenu.popup()

func window_size_changed():
	var columns = floor($MarginContainer.size.x / Settings.grid_image_size)
	if  columns < 1:
		grid_container.columns = 1
	else:
		grid_container.columns = columns

func _on_popup_menu_edit():
	edit_collection.emit($PopupMenu.collection)

func _on_popup_menu_delete():
	delete_dialog.collection = popup_menu.collection
	delete_dialog.popup_centered()

func grid_item_count():
	return grid_container.get_child_count() - 1

func _on_visibility_changed() -> void:
	if grid_container == null:
		return
	for child in grid_container.get_children():
		child.visible = visible

func _on_collection_deleted(id):
	tiles[id].queue_free()
	tiles.erase(id)
	refresh_grid()
