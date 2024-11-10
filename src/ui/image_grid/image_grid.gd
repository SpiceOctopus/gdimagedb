extends Control

class_name ImageGrid

signal tag_edit(id : int)
signal grid_updated

var db_media : Array[DBMedia] = []
var current_media : Array[DBMedia] = []
var previews : Array[GridImage] = []

var previews_mutex : Mutex = Mutex.new()
var exiting : bool = false

@onready var grid_container = $MarginContainer/ScrollContainer/GridContainer
@onready var scroll_container = $MarginContainer/ScrollContainer
@onready var add_to_collection_window = $AddToCollection
@onready var media_properties_window = $MediaProperties
@onready var replace_file_window = $ReplaceFileWindow
@onready var drop_files_label = $DropFilesLabel
@onready var import_log = $ImportLog
@onready var delete_file = $DeleteFile
@onready var export_file = $ExportFileDialog
@onready var right_click_menu = $PopupMenu

@onready var last_window_size = Vector2i(0,0)

func _ready() -> void:
	drop_files_label.visible = (DB.count_images_in_db() <= 0)
	await get_tree().create_timer(0.01).timeout # give the ui a moment to display
	GlobalData.favorites_changed.connect(trigger_visibility_update)
	GlobalData.untagged_changed.connect(trigger_visibility_update)
	GlobalData.tags_changed.connect(trigger_visibility_update)
	GlobalData.db_tags_changed.connect(trigger_visibility_update)
	GlobalData.media_deleted.connect(_on_media_deleted)
	GlobalData.db_collections_changed.connect(trigger_visibility_update)
	GlobalData.sort_mode_changed.connect(sort_grid)
	db_media = DB.get_all_media()
	
	var loader_threads : Array[Thread] = []
	
	for i in OS.get_processor_count():
		var data : Array[DBMedia] = []
		if i == OS.get_processor_count() - 1: # last thread
			@warning_ignore("integer_division")
			data = db_media.slice(i * (db_media.size() / OS.get_processor_count()), db_media.size())
		else:
			@warning_ignore("integer_division")
			data = db_media.slice(i * (db_media.size() / OS.get_processor_count()), (i + 1) * (db_media.size() / OS.get_processor_count()))
		var thread = Thread.new()
		thread.start(initialize_grid_chunk.bind(data))
		loader_threads.append(thread)
	
	for thread : Thread in loader_threads:
		thread.wait_to_finish()
	
	previews.sort_custom(sort_by_id_asc)
	
	for preview : GridImage in previews:
		grid_container.add_child(preview)
	
	manage_preview_visibility()

func _process(_delta : float) -> void:
	if DisplayServer.window_get_size() != last_window_size:
		last_window_size = DisplayServer.window_get_size()
		window_size_changed()

func _exit_tree() -> void:
	exiting = true

func initialize_grid_chunk(chunk : Array[DBMedia]):
	for media : DBMedia in chunk:
		if exiting:
			return
		
		var gridImageInstance = GridImage.new()
		gridImageInstance.current_media = media
		gridImageInstance.double_click.connect(_on_grid_image_double_click)
		gridImageInstance.right_click.connect(grid_image_right_click)
		gridImageInstance.click.connect(on_grid_image_click)
		#gridImageInstance.multi_select.connect(_on_grid_image_multi_select) # feature not implemented yet
		gridImageInstance.custom_minimum_size = Vector2(Settings.grid_image_size, Settings.grid_image_size)
		gridImageInstance.visible = true
		gridImageInstance.load_thumbnail()
		previews_mutex.lock()
		previews.append(gridImageInstance)
		previews_mutex.unlock()

func sort_by_id_desc(a, b) -> bool:
	if a.current_media.id > b.current_media.id:
		return true
	return false

func sort_by_id_asc(a, b) -> bool:
	if a.current_media.id < b.current_media.id:
		return true
	return false

func load_missing_previews() -> void:
	db_media = DB.get_all_media()
	var preview_ids : Array[int] = []
	for preview : GridImage in previews:
		preview_ids.append(preview.current_media.id)
	
	for media : DBMedia in db_media:
		if media.id not in preview_ids:
			var gridImageInstance = GridImage.new()
			gridImageInstance.current_media = media
			gridImageInstance.double_click.connect(_on_grid_image_double_click)
			gridImageInstance.right_click.connect(grid_image_right_click)
			gridImageInstance.click.connect(on_grid_image_click)
			#gridImageInstance.multi_select.connect(_on_grid_image_multi_select) # feature not implemented yet
			gridImageInstance.custom_minimum_size = Vector2(Settings.grid_image_size, Settings.grid_image_size)
			gridImageInstance.visible = true
			gridImageInstance.load_thumbnail()
			previews.append(gridImageInstance)
	
	sort_grid()
	manage_preview_visibility()

func sort_grid() -> void:
	for node in grid_container.get_children():
		grid_container.remove_child(node)
	
	match GlobalData.grid_sort_mode:
		GlobalData.GridSortMode.IMPORT_ASC:
			previews.sort_custom(sort_by_id_asc)
		GlobalData.GridSortMode.IMPORT_DESC:
			previews.sort_custom(sort_by_id_desc)
		GlobalData.GridSortMode.RANDOM:
			previews.shuffle()
	
	for preview : GridImage in previews:
		grid_container.add_child(preview)
	grid_updated.emit()

func manage_preview_visibility() -> void:
	current_media.clear()
	for preview in previews:
		preview.visible = false
	
	var images_without_tags : Dictionary = {}
	if GlobalData.show_untagged: # no need to run this if it's not in use
		images_without_tags = DB.get_ids_images_without_tags()
	
	var images_in_collections : Dictionary = DB.get_all_image_ids_in_collections()
	var current_media_ids : Array[int] = DB.get_media_ids_for_tags(GlobalData.included_tags, GlobalData.excluded_tags)
	
	for preview : GridImage in previews:
		if preview.current_media.id not in current_media_ids:
			pass
		elif GlobalData.show_favorites && !preview.current_media.favorite:
			pass
		elif GlobalData.show_untagged && !images_without_tags.has(preview.current_media.id):
			pass
		elif Settings.hide_images_collections && images_in_collections.has(preview.current_media.id):
			pass
		else:
			preview.visible = true
			current_media.append(preview.current_media)
	
	grid_updated.emit()

func trigger_visibility_update() -> void:
	if GlobalData.current_display_mode == GlobalData.DisplayMode.IMAGES:
		manage_preview_visibility()

func window_size_changed() -> void:
	var columns : int = floor(scroll_container.size.x / Settings.grid_image_size)
	if  columns < 1:
		grid_container.columns = 1
	else:
		grid_container.columns = columns

func get_images_for_current_view() -> Array[DBMedia]:
	if !((GlobalData.included_tags.size() > 0) || (GlobalData.excluded_tags.size() > 0)):
		return db_media
	else:
		return DB.get_images_for_tags(GlobalData.included_tags, GlobalData.excluded_tags)

func _on_grid_image_double_click(sender_media : DBMedia) -> void:
	var viewer_window = load("res://ui/media_viewer/media_viewer_window.tscn").instantiate()
	
	var image_set : Array[DBMedia] = []
	for preview in previews:
		if preview.visible:
			image_set.append(preview.current_media)
	
	viewer_window.media_set = image_set
	for image : DBMedia in image_set:
		if image.id == sender_media.id:
			viewer_window.current_image = image_set.find(image)
	
	add_child(viewer_window)
	viewer_window.hide()
	viewer_window.size = DisplayServer.window_get_size()
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_MAXIMIZED:
		viewer_window.mode = Window.MODE_MAXIMIZED
	
	viewer_window.popup_centered()

func grid_image_right_click(media : DBMedia) -> void:
	right_click_menu.position = DisplayServer.mouse_get_position()
	right_click_menu.media = media
	right_click_menu.popup()

func _on_PopupMenu_favorite_changed(id : int, fav : bool) -> void:
	for preview in previews:
		if preview.current_media.id == id:
			preview.current_media.favorite = fav

func _on_PopupMenu_tag_edit(id : int) -> void:
	tag_edit.emit(id)

func _on_PopupMenu_properties(media : DBMedia) -> void:
	media_properties_window.media = media
	media_properties_window.popup_centered()
	sort_grid()

func on_grid_image_click(grid_image : GridImage) -> void:
	grid_image.selected = true
	for preview in previews:
		if preview != grid_image:
			preview.selected = false

func _on_popup_menu_add_to_collection(image_id : int) -> void:
	add_to_collection_window.image_id = image_id
	add_to_collection_window.popup_centered()

func _on_grid_image_multi_select(_image):
	return # inactive for now
	#image.set_selected(true)

func _on_popup_menu_replace_file(media : DBMedia) -> void:
	replace_file_window.media = media
	replace_file_window.popup_centered()

func _on_replace_file_window_confirmed() -> void:
	var error : Error = ImportUtil.replace_file(replace_file_window.media, replace_file_window.current_path)
	
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
	CacheManager.remove_thumbnail(replace_file_window.media.id)
	previews[replace_file_window.media.id].load_thumbnail()

func _on_popup_menu_delete(media : DBMedia) -> void:
	delete_file.media = media
	delete_file.popup_centered()

func _on_media_deleted(id : int) -> void:
	previews[id].queue_free()
	previews_mutex.lock()
	previews.erase(id)
	previews_mutex.unlock()
	db_media = DB.get_all_media()

func _on_popup_menu_export(image : DBMedia) -> void:
	export_file.media = image
	export_file.popup_centered()
