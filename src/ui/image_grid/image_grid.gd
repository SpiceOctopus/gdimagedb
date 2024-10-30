extends Control

class_name ImageGrid

signal tag_edit(id : int)
signal grid_updated
signal file_replaced
signal thumbnail_load_complete

var db_media : Array[DBMedia] = []
var current_media : Array[DBMedia] = []
var previews : Dictionary = {}

var previews_mutex : Mutex = Mutex.new()

var grid_refresh_thread_id : int = -1
var thumbnail_load_thread_id : int = -1

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
@onready var export_file = $ExportFileDialog

@onready var last_window_size = Vector2i(0,0)

func _ready() -> void:
	drop_files_label.visible = (DB.count_images_in_db() == 0)
	CacheManager.connect("thumb_cache_loading_complete", trigger_load_thumbnails)
	GlobalData.connect("favorites_changed", show_favorites)
	GlobalData.connect("untagged_changed", show_untagged)
	GlobalData.connect("tags_changed", tags_changed)
	GlobalData.connect("db_tags_changed", tags_changed)
	GlobalData.connect("db_images_changed", _on_db_images_changed)
	GlobalData.connect("media_deleted", _on_media_deleted)
	GlobalData.connect("db_collections_changed", refresh_grid)
	connect("thumbnail_load_complete", merge_thumbnail_load_thread)
	db_media = DB.get_all_media()
	grid_refresh_thread_id = WorkerThreadPool.add_task(refresh_grid)
	add_to_collection_window.connect('close_requested', Callable(add_to_collection_window,'hide'))
	add_to_collection_window.min_size = add_to_collection_control.custom_minimum_size
	media_properties_window.connect('close_requested', Callable(media_properties_window,'hide'))
	media_properties_window.min_size = media_properties_control.custom_minimum_size

func _process(_delta) -> void:
	var new_size = DisplayServer.window_get_size()
	if new_size != last_window_size:
		last_window_size = new_size
		window_size_changed()

func tags_changed() -> void:
	if GlobalData.current_display_mode == GlobalData.DisplayMode.Images:
		grid_refresh_thread_id = WorkerThreadPool.add_task(refresh_grid)

func show_favorites() -> void:
	if GlobalData.current_display_mode == GlobalData.DisplayMode.Images:
		grid_refresh_thread_id = WorkerThreadPool.add_task(refresh_grid)

func show_untagged() -> void:
	if GlobalData.current_display_mode == GlobalData.DisplayMode.Images:
		grid_refresh_thread_id = WorkerThreadPool.add_task(refresh_grid)

func window_size_changed() -> void:
	var columns : int = floor(scroll_container.size.x / Settings.grid_image_size)
	if  columns < 1:
		grid_container.columns = 1
	else:
		grid_container.columns = columns

# hard = thumbnail cache has been cleared, reload all previews
func refresh_grid(hard : bool = false) -> void:
	current_media.clear()
	drop_files_label.call_deferred("set_visible", (db_media.size() <= 0))
	
	previews_mutex.lock()
	for preview in previews.values():
		preview.call_deferred("set_visible", false)
	
	for media : DBMedia in db_media:
		if !previews.has(media.id):
			var gridImageInstance = GridImage.new()
			gridImageInstance.set_media(media)
			grid_container.call_deferred("add_child", gridImageInstance)
			gridImageInstance.add_to_group("previews")
			gridImageInstance.connect("double_click", _on_grid_image_double_click)
			gridImageInstance.call_deferred("connect", "right_click", grid_image_right_click)
			gridImageInstance.call_deferred("connect", "click", on_grid_image_click)
			gridImageInstance.call_deferred("connect", "multi_select", _on_grid_image_multi_select)
			gridImageInstance.call_deferred("set_custom_minimum_size", Vector2(Settings.grid_image_size, Settings.grid_image_size))
			gridImageInstance.call_deferred("set_visible", false)
			previews[media.id] = gridImageInstance
	
	var images_without_tags : Array[int] = []
	if GlobalData.show_untagged: # no need to run this if it's not in use
		images_without_tags = DB.get_ids_images_without_tags()
	
	var images_in_collections : Array[int] = DB.get_all_image_ids_in_collections()
	for image in get_images_for_current_view():
		if GlobalData.show_favorites && !image.favorite:
			pass
		elif GlobalData.show_untagged && !(image.id in images_without_tags):
			pass
		elif Settings.hide_images_collections && (image.id in images_in_collections):
			pass
		else:
			previews[image.id].call_deferred("set_visible", true)
			current_media.append(image)
	previews_mutex.unlock()
	
	call_deferred("window_size_changed") # calculates and sets grid proportions
	call_deferred("notify_grid_updated")
	if hard:
		call_deferred("trigger_load_thumbnails")

func trigger_load_thumbnails() -> void:
	thumbnail_load_thread_id = WorkerThreadPool.add_task(async_load_thumbnails)

func async_load_thumbnails() -> void:
	for preview : GridImage in previews.values():
		preview.load_thumbnail()
	thumbnail_load_complete.emit.call_deferred()

func merge_thumbnail_load_thread() -> void:
	WorkerThreadPool.wait_for_task_completion(thumbnail_load_thread_id)

func notify_grid_updated() -> void:
	grid_updated.emit()
	WorkerThreadPool.wait_for_task_completion(grid_refresh_thread_id)

func get_images_for_current_view() -> Array[DBMedia]:
	if !((GlobalData.included_tags.size() > 0) || (GlobalData.excluded_tags.size() > 0)):
		return db_media
	else:
		return DB.get_images_for_tags(GlobalData.included_tags, GlobalData.excluded_tags)

func _on_grid_image_double_click(sender_media : DBMedia) -> void:
	var instance : MediaViewer = load("res://ui/media_viewer/media_viewer.tscn").instantiate()
	instance.media_set = current_media.duplicate()
	for image : DBMedia in current_media:
		if image.id == sender_media.id:
			instance.current_image = current_media.find(image)
	
	var window : Window = Window.new()
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

func grid_image_right_click(media : DBMedia) -> void:
	$PopupMenu.position = DisplayServer.mouse_get_position()
	$PopupMenu.media = media
	$PopupMenu.popup()

func _on_PopupMenu_favorite_changed(id : int, fav : bool) -> void:
	for preview in previews.values():
		if preview.current_media.id == id:
			preview.current_media.favorite = fav

func _on_PopupMenu_tag_edit(id : int) -> void:
	tag_edit.emit(id)

func _on_PopupMenu_properties(media : DBMedia) -> void:
	media_properties_control.media = media
	media_properties_window.popup_centered()

func on_grid_image_click(grid_image : GridImage) -> void:
	grid_image.set_selected(true)
	for preview in get_tree().get_nodes_in_group("previews"):
		if preview != grid_image:
			preview.set_selected(false)

func _on_popup_menu_add_to_collection(image_id : int) -> void:
	add_to_collection_control.image_id = image_id
	add_to_collection_window.popup_centered()

func _on_db_images_changed() -> void:
	db_media = DB.get_all_media()
	grid_refresh_thread_id = WorkerThreadPool.add_task(refresh_grid)

func _on_grid_image_multi_select(_image):
	return # inactive for now
	#image.set_selected(true)

func _on_popup_menu_replace_file(media : DBMedia) -> void:
	replace_file_window.media = media
	replace_file_window.popup_centered()

func _on_replace_file_window_confirmed() -> void:
	var error = ImportUtil.replace_file(replace_file_window.media, replace_file_window.current_path)
	
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
	
	db_media = DB.get_all_media()
	file_replaced.emit()

func _on_popup_menu_delete(media : DBMedia) -> void:
	delete_file.media = media
	delete_file.popup_centered()

func _on_media_deleted(id : int) -> void:
	previews[id].queue_free()
	previews_mutex.lock()
	previews.erase(id)
	previews_mutex.unlock()

func _on_popup_menu_export(image : DBMedia) -> void:
	export_file.media = image
	export_file.popup_centered()

func queue_refresh_grid(hard : bool = false) -> void:
	if hard:
		previews_mutex.lock()
		previews.clear()
		previews_mutex.unlock()
		for grid_image in grid_container.get_children():
			grid_image.free()
		grid_refresh_thread_id = WorkerThreadPool.add_task(Callable(refresh_grid).bind(hard))
	else:
		grid_refresh_thread_id = WorkerThreadPool.add_task(refresh_grid)
		
