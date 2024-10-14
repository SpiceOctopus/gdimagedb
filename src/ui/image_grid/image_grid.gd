extends Control

class_name ImageGrid

signal tag_edit
signal grid_updated
signal file_replaced

enum SortMode { none, pos }

var db_images = []
var current_images = []
var previews = {}

var sort_mode : SortMode = SortMode.none : set=set_sort_mode

var previews_mutex = Mutex.new()

@onready var grid_container = $MarginContainer/ScrollContainer/GridContainer
@onready var scroll_container = $MarginContainer/ScrollContainer
@onready var add_to_collection_window = $AddToCollectionWindow
@onready var add_to_collection_control = $AddToCollectionWindow/AddToCollection
@onready var media_properties_window = $MediaPropertiesWindow
@onready var media_properties_control = $MediaPropertiesWindow/MediaProperties
@onready var replace_file_window = $ReplaceFileWindow
@onready var drop_files_label = $DropFilesLabel
@onready var import_log = $ImportLog
@onready var delete_file = $DeleteFile

@onready var last_window_size = Vector2i(0,0)

func _ready():
	if DB.count_images_in_db() == 0:
		drop_files_label.visible = true
	GlobalData.connect("favorites_changed", show_favorites)
	GlobalData.connect("untagged_changed", show_untagged)
	GlobalData.connect("tags_changed", tags_changed)
	GlobalData.connect("db_tags_changed", tags_changed)
	GlobalData.connect("db_images_changed", _on_db_images_changed)
	GlobalData.connect("media_deleted", _on_media_deleted)
	GlobalData.connect("db_collections_changed", refresh_grid)
	db_images = DB.get_all_images()
	WorkerThreadPool.add_task(refresh_grid)
	add_to_collection_window.connect('close_requested', Callable(add_to_collection_window,'hide'))
	add_to_collection_window.min_size = add_to_collection_control.custom_minimum_size
	media_properties_window.connect('close_requested', Callable(media_properties_window,'hide'))
	media_properties_window.min_size = media_properties_control.custom_minimum_size

func _process(_delta):
	var new_size = DisplayServer.window_get_size()
	if new_size != last_window_size:
		last_window_size = new_size
		window_size_changed()

func tags_changed():
	if GlobalData.current_display_mode == GlobalData.DisplayMode.Images:
		refresh_grid()

func show_favorites():
	if GlobalData.current_display_mode == GlobalData.DisplayMode.Images:
		refresh_grid()

func show_untagged():
	if GlobalData.current_display_mode == GlobalData.DisplayMode.Images:
		refresh_grid()

func window_size_changed():
	var columns = floor(scroll_container.size.x / Settings.grid_image_size)
	if  columns < 1:
		grid_container.columns = 1
	else:
		grid_container.columns = columns

func set_sort_mode(mode):
	sort_mode = mode
	refresh_grid()

func refresh_grid(hard : bool = false):
	current_images.clear()
	
	if hard:
		previews_mutex.lock()
		previews.clear()
		previews_mutex.unlock()
		for grid_image in grid_container.get_children():
			grid_image.free()
	
	drop_files_label.call_deferred("set_visible", (db_images.size() <= 0))
	
	for preview in previews.values():
		preview.visible = false
	
	for image in db_images:
		if !previews.has(image["id"]):
			var gridImageInstance = GridImage.new()
			gridImageInstance.set_image(image)
			grid_container.call_deferred("add_child", gridImageInstance)
			gridImageInstance.add_to_group("previews")
			gridImageInstance.connect("double_click",Callable(self,"_on_input_grid_image"))
			gridImageInstance.connect("right_click",Callable(self,"grid_image_right_click"))
			gridImageInstance.connect("click",Callable(self,"on_grid_image_click"))
			gridImageInstance.connect("multi_select", _on_grid_image_multi_select)
			gridImageInstance.custom_minimum_size = Vector2(Settings.grid_image_size, Settings.grid_image_size)
			gridImageInstance.visible = false
			previews_mutex.lock()
			previews[image["id"]] = gridImageInstance
			previews_mutex.unlock()
	
	var images_without_tags = []
	if GlobalData.show_untagged: # no need to run this if it's not in use
		for entry in DB.get_ids_images_without_tags():
			images_without_tags.append(entry["id"])
	
	var images_in_collections = DB.get_all_image_ids_in_collections()
	for image in get_images_for_current_view():
		if GlobalData.show_favorites && !image["fav"]:
			pass
		elif GlobalData.show_untagged && !(image["id"] in images_without_tags):
			pass
		elif Settings.hide_images_collections && (image["id"] in images_in_collections):
			pass
		else:
			previews[image["id"]].call_deferred("set_visible", true)
			current_images.append(image)
	
	call_deferred("window_size_changed") # calculates and sets grid proportions
	call_deferred("notify_grid_updated")

func notify_grid_updated():
	grid_updated.emit()

func get_images_for_current_view():
	if !((GlobalData.included_tags.size() > 0) || (GlobalData.excluded_tags.size() > 0)):
		return db_images
	else:
		return DB.get_images_for_tags(GlobalData.included_tags, GlobalData.excluded_tags)

func compare_by_position(a, b):
	return a["position"] < b["position"]

func _on_input_grid_image(senderImage):
	var instance = load("res://ui/media_viewer/media_viewer.tscn").instantiate()
	instance.images = current_images.duplicate()
	for image in current_images:
		if image["id"] == senderImage["id"]:
			instance.current_image = current_images.find(image)
	
	var window = Window.new()
	window.hide()
	add_child(window)
	window.size = DisplayServer.window_get_size()
	if DisplayServer.window_get_mode() == 2: # 2 = maximized. Not sure how to address the enum properly
		window.mode = Window.MODE_MAXIMIZED
	instance.connect("closing", Callable(window, "queue_free"))
	instance.visible = true
	window.add_child(instance)
	window.title = "Media Viewer"
	window.popup_centered()
	window.connect("close_requested", Callable(window, "queue_free"))

func grid_image_right_click(image):
	$PopupMenu.position = DisplayServer.mouse_get_position()
	$PopupMenu.image = image
	$PopupMenu.popup()

func _on_PopupMenu_favorite_changed(id, fav):
	for preview in previews.values():
		if preview.current_image["id"] == id:
			preview.current_image["fav"] = fav

func _on_PopupMenu_tag_edit(image):
	tag_edit.emit(image)

func _on_PopupMenu_properties(image):
	media_properties_control.image = image
	media_properties_window.popup_centered()

func on_grid_image_click(grid_image):
	grid_image.set_selected(true)
	for preview in get_tree().get_nodes_in_group("previews"):
		if preview != grid_image:
			preview.set_selected(false)

func _on_popup_menu_add_to_collection(image):
	add_to_collection_control.image = image
	add_to_collection_window.popup_centered()

func _on_db_images_changed():
	db_images = DB.get_all_images()
	refresh_grid()

func _on_grid_image_multi_select(_image):
	return # inactive for now
	#image.set_selected(true)

func _on_popup_menu_replace_file(file):
	replace_file_window.file = file
	replace_file_window.popup_centered()

func _on_replace_file_window_confirmed():
	var error = ImportUtil.replace_file(replace_file_window.file, replace_file_window.current_path)
	
	import_log.clear_messages()
	import_log.popup_centered()
	
	await get_tree().create_timer(0.1).timeout
	
	if error == OK:
		import_log.add_message("File %s successfully imported." % replace_file_window.current_path)
		await get_tree().create_timer(0.1).timeout
	elif error == ERR_ALREADY_EXISTS:
		import_log.add_message("File %s already in db." % replace_file_window.current_path)
		await get_tree().create_timer(0.1).timeout
	elif error == ERR_FILE_UNRECOGNIZED:
		import_log.add_message("File type %s not supported." & replace_file_window.current_path.get_extension())
		await get_tree().create_timer(0.1).timeout
	
	db_images = DB.get_all_images()
	file_replaced.emit()

func _on_popup_menu_delete(image):
	delete_file.image = image
	delete_file.popup_centered()

func _on_media_deleted(id):
	previews[id].queue_free()
	previews_mutex.lock()
	previews.erase(id)
	previews_mutex.unlock()
