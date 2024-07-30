extends Control

signal grid_updated

var new_button_scene = load("res://collections/collections_grid_new_button/new_button.tscn")
var new_dlg_scene = load("res://collections/new_collection_dialog/new_collection.tscn")
var grid_tile_scene = load("res://collections/collections_grid_tile/grid_tile.tscn")
var viewer_scene = load("res://media_viewer/media_viewer.tscn")
var collection_editor_scene = load("res://collections/collection_editor/collection_editor.tscn")

var show_only_favorites : bool = GlobalData.show_favorites
var show_only_untagged : bool = GlobalData.show_untagged

@onready var grid_container = $ScrollContainer/GridContainer
@onready var last_window_size = Vector2i(0,0)
@onready var delete_dialog = $DeleteCollection
@onready var popup_menu = $PopupMenu
@onready var new_collection_dialog = $NewCollectionDialog

func _ready():
	reset_grid()
	GlobalData.connect("favorites_changed", show_favorites)
	GlobalData.connect("untagged_changed", show_untagged)
	GlobalData.connect("tags_changed", _on_tags_changed)

func _process(_delta):
	var new_size = DisplayServer.window_get_size()
	if new_size != last_window_size:
		last_window_size = new_size
		window_size_changed()

func _on_tags_changed():
	if GlobalData.current_display_mode == GlobalData.DisplayMode.Collections:
		reset_grid()

func show_untagged():
	if show_only_untagged != GlobalData.show_untagged:
		show_only_untagged = GlobalData.show_untagged
		reset_grid()

func show_favorites():
	if show_only_favorites != GlobalData.show_favorites: # avoid doing lots of unnecessary stuff
		show_only_favorites = GlobalData.show_favorites
		reset_grid()

func reset_grid():
	for tile in get_tree().get_nodes_in_group("collections_grid_tiles"):
		tile.remove_from_group("collections_grid_tiles")
		grid_container.remove_child(tile)
		tile.queue_free()
	
	var all_collections
	if GlobalData.included_tags.size() > 0 || GlobalData.excluded_tags.size() > 0:
		all_collections = DB.get_collections_for_tags(GlobalData.included_tags, GlobalData.excluded_tags)
	else:
		all_collections = DB.get_all_collections()
	
	for collection in all_collections:
		if show_only_favorites && collection["fav"] == 0:
			continue
		if GlobalData.show_untagged && DB.get_tags_for_collection(collection["id"]).size() > 0:
			continue
		
		var grid_tile_instance = grid_tile_scene.instantiate()
		grid_tile_instance.custom_minimum_size = Vector2(Settings.grid_image_size, Settings.grid_image_size)
		grid_tile_instance.connect("double_click", tile_double_click)
		grid_tile_instance.connect("right_click", tile_right_click)
		grid_tile_instance.add_to_group("collections_grid_tiles")
		$ScrollContainer/GridContainer.add_child(grid_tile_instance)
		grid_tile_instance.collection = collection
	
	var new_button_instance = new_button_scene.instantiate()
	new_button_instance.custom_minimum_size = Vector2(Settings.grid_image_size, Settings.grid_image_size)
	new_button_instance.connect("new_collection", new_collection)
	new_button_instance.add_to_group("collections_grid_tiles")
	$ScrollContainer/GridContainer.add_child(new_button_instance)
	
	emit_signal("grid_updated")

func tile_double_click(collection):
	var viewer_instance = viewer_scene.instantiate()
	var images = DB.get_all_images_in_collection(collection["id"])
	images.sort_custom(compare_by_position)
	viewer_instance.images = images
	
	# add code to resume collection from last seen image
	
	#for image in images:
	#	if image["id"] == senderImage["id"]:
	#		viewer_instance.current_image = images.find(image)
	
	var window = Window.new()
	window.hide()
	get_tree().get_root().add_child(window)
	window.size = DisplayServer.window_get_size()
	if DisplayServer.window_get_mode() == 2: # 2 = maximized. Not sure how to address the enum properly
		window.mode = Window.MODE_MAXIMIZED
	viewer_instance.connect("closing", Callable(window, "queue_free"))
	window.add_child(viewer_instance)
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
	var columns = floor($ScrollContainer.size.x / Settings.grid_image_size)
	if  columns < 1:
		grid_container.columns = 1
	else:
		grid_container.columns = columns

func new_collection():
	new_collection_dialog.popup_centered()

func _on_popup_menu_edit():
	var window = Window.new()
	window.hide()
	var editor_instance = collection_editor_scene.instantiate()
	editor_instance.collection = $PopupMenu.collection
	window.title = "Collection Editor"
	get_tree().get_root().add_child(window)
	window.size = DisplayServer.window_get_size()
	if DisplayServer.window_get_mode() == 2: # 2 = maximized. Not sure how to address the enum properly
		window.mode = Window.MODE_MAXIMIZED
	window.add_child(editor_instance)
	
	window.min_size = editor_instance.custom_minimum_size
	window.popup_centered()
	window.connect("close_requested", Callable(window, "queue_free"))

func _on_popup_menu_delete():
	delete_dialog.collection = popup_menu.collection
	delete_dialog.popup_centered()

func grid_item_count():
	return grid_container.get_child_count() - 1

func _on_new_collection_create_new():
	reset_grid()

func _on_delete_collection_deleted():
	reset_grid()
