extends Control

signal grid_updated
signal edit_collection(collection : DBCollection)

var new_button_instance = load("res://ui/collections/collections_grid_new_button/new_button.tscn").instantiate()

var db_collections : Array[DBCollection] = [] # to be filled with all collections available in the database
var tiles : Dictionary = {} # cached tiles for the grid

@onready var grid_container = $MarginContainer/ScrollContainer/GridContainer
@onready var last_window_size = Vector2i(0,0)
@onready var delete_dialog = $DeleteCollection
@onready var popup_menu = $PopupMenu

func _ready() -> void:
	refresh_grid()
	GlobalData.favorites_changed.connect(refresh_grid)
	GlobalData.untagged_changed.connect(refresh_grid)
	GlobalData.tags_changed.connect(refresh_grid)
	GlobalData.db_collections_changed.connect(refresh_grid)
	GlobalData.collection_deleted.connect(_on_collection_deleted)
	new_button_instance.custom_minimum_size = Vector2(Settings.grid_image_size, Settings.grid_image_size)

func _process(_delta : float) -> void:
	if DisplayServer.window_get_size() != last_window_size:
		last_window_size = DisplayServer.window_get_size()
		window_size_changed()

func refresh_grid() -> void:
	if grid_container.get_children().has(new_button_instance):
		grid_container.remove_child(new_button_instance) # remove here, add back to the end
	
	for tile in tiles.values():
		tile.visible = false
	
	db_collections = DB.get_all_collections()
	
	for collection : DBCollection in db_collections:
		if !tiles.has(collection.id):
			var instance = load("res://ui/collections/collections_grid_tile/grid_tile.tscn").instantiate()
			instance.custom_minimum_size = Vector2(Settings.grid_image_size, Settings.grid_image_size)
			instance.double_click.connect(tile_double_click)
			instance.right_click.connect(tile_right_click)
			instance.click.connect(on_grid_tile_click)
			instance.visible = false
			instance.collection = collection
			grid_container.add_child(instance)
			tiles[collection.id] = instance
	grid_container.add_child(new_button_instance)
	
	var collections_without_tags : Array[int] = DB.get_ids_collections_without_tags()
	var current_tiles : Dictionary = {}
	
	if !((GlobalData.included_tags.size() > 0) || (GlobalData.excluded_tags.size() > 0)):
		current_tiles = tiles
	else:
		for collection : DBCollection in DB.get_collections_for_tags(GlobalData.included_tags, GlobalData.excluded_tags):
			current_tiles[collection.id] = tiles[collection.id]
	
	for tile in current_tiles.values():
		if GlobalData.show_favorites && !tile.collection.fav:
			pass
		elif GlobalData.show_untagged && !(tile.collection.id in collections_without_tags):
			pass
		else:
			tile.visible = true
		
		if GlobalData.current_display_mode != GlobalData.DisplayMode.COLLECTIONS: # overrides all other possibilites
			tile.visible = false
	
	grid_updated.emit()

func tile_double_click(collection : DBCollection) -> void:
	var instance = load("res://ui/media_viewer/media_viewer.tscn").instantiate()
	var images : Array[DBMedia] = DB.get_all_images_in_collection(collection.id)
	images.sort_custom(compare_by_position)
	instance.media_set = images
	
	# add code to resume collection from last seen image
	
	#for image in images:
	#	if image["id"] == senderImage["id"]:
	#		instance.current_image = images.find(image)
	
	var window : Window = Window.new()
	window.hide()
	get_tree().get_root().add_child(window)
	window.size = DisplayServer.window_get_size()
	if DisplayServer.window_get_mode() == 2: # 2 = maximized. Not sure how to address the enum properly
		window.mode = Window.MODE_MAXIMIZED
	window.add_child(instance)
	instance.closing.connect(window.queue_free) # required to allow closing with esc key
	instance.visible = true
	window.title = collection.name
	window.close_requested.connect(window.queue_free)
	window.popup_centered()

func compare_by_position(a : DBMedia, b : DBMedia) -> bool:
	return a.position < b.position

func tile_right_click(collection : DBCollection) -> void:
	$PopupMenu.position = DisplayServer.mouse_get_position()
	$PopupMenu.collection = collection
	$PopupMenu.popup()

func window_size_changed() -> void:
	var columns = floor($MarginContainer.size.x / Settings.grid_image_size)
	if  columns < 1:
		grid_container.columns = 1
	else:
		grid_container.columns = columns

func _on_popup_menu_edit() -> void:
	edit_collection.emit($PopupMenu.collection)

func _on_popup_menu_delete() -> void:
	delete_dialog.collection = popup_menu.collection
	delete_dialog.popup_centered()

func grid_item_count() -> int:
	return grid_container.get_child_count() - 1

func _on_visibility_changed() -> void:
	if grid_container == null:
		return
	for child in grid_container.get_children():
		child.visible = visible

func _on_collection_deleted(id : int) -> void:
	tiles[id].queue_free()
	tiles.erase(id)
	refresh_grid()

func on_grid_tile_click(grid_tile) -> void:
	for tile in tiles.values():
		tile.set_selected(false)
	grid_tile.set_selected(true)

func update_tile(collection : DBCollection) -> void:
	tiles[collection.id].collection = collection
