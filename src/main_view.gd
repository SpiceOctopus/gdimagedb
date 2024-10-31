extends Control

@onready var image_grid : ImageGrid = $VBoxContainer/HBoxContainer/Content/ImageGrid
@onready var collections_grid = $VBoxContainer/HBoxContainer/Content/CollectionsGrid
@onready var side_bar = $VBoxContainer/HBoxContainer/VBoxContainer/SideBar
@onready var menu_bar = $VBoxContainer/MenuBar
@onready var import_log = $ImportLog
@onready var grid_info_panel = $VBoxContainer/HBoxContainer/VBoxContainer/GridInfoPanel
@onready var tag_editor = $TagEditor
@onready var collection_editor = $CollectionEditor

func _ready() -> void:
	get_parent().min_size = custom_minimum_size
	get_tree().root.connect("files_dropped",Callable(self,"_on_files_dropped"))
	_on_grid_grid_updated()

func _input(_event) -> void:
	if Input.is_action_just_pressed("ui_filedialog_refresh") && not Input.is_key_pressed(KEY_SHIFT):
		refresh()
	if Input.is_action_just_pressed("clear_thumb_cache_refresh"):
		CacheManager.clear_thumb_cache()
		CacheManager.reload_thumbcache()
		refresh(true)
	if Input.is_action_just_pressed("help"):
		GlobalData.notify_help_called()

# The timers in this function are required to give the ui time to update.
# Without the timer the import log will just be a black window.
func _on_files_dropped(files : PackedStringArray) -> void:
	import_log.clear_messages()
	import_log.popup_centered()
	
	await get_tree().create_timer(0.1).timeout
	
	var import_counter : int = 0
	for file in files:
		var error = ImportUtil.import_image(file)
		if error == OK:
			import_counter += 1
			import_log.add_message("File %s successfully imported." % file)
			await get_tree().create_timer(0.1).timeout
		elif error == ERR_ALREADY_EXISTS:
			import_log.add_message("File %s already in db." % file)
			await get_tree().create_timer(0.1).timeout
		elif error == ERR_FILE_UNRECOGNIZED:
			import_log.add_message("File type %s not supported." % file.get_extension())
			await get_tree().create_timer(0.1).timeout
	
	if import_counter > 0:
		image_grid.refresh_grid()
		image_grid.trigger_load_thumbnails(CacheManager.load_missing_thumbnails())

func _on_grid_tag_edit(id : int) -> void:
	if tag_editor.min_size.x > DisplayServer.window_get_size().x || tag_editor.min_size.y > DisplayServer.window_get_size().y:
		tag_editor.size = tag_editor.min_size
	else:
		tag_editor.size = Vector2( get_window().get_size().x * 0.9, get_window().get_size().y * 0.9 )
	
	tag_editor.popup_centered()
	tag_editor.media_set = image_grid.current_media.duplicate()
	tag_editor.set_current(id)

func _on_menu_bar_refresh_grid() -> void:
	refresh()

func _on_grid_grid_updated() -> void:
	if side_bar == null:
		return
	
	if GlobalData.current_display_mode == GlobalData.DisplayMode.Images:
		grid_info_panel.set_grid_items_count(image_grid.current_media.size())
	elif GlobalData.current_display_mode == GlobalData.DisplayMode.Collections:
		grid_info_panel.set_grid_items_count(collections_grid.grid_item_count())

# hard refresh = clear cache
func refresh(hard : bool = false) -> void:
	if GlobalData.current_display_mode == GlobalData.DisplayMode.Images:
		image_grid.queue_refresh_grid(hard)
	elif GlobalData.current_display_mode == GlobalData.DisplayMode.Collections:
		collections_grid.refresh_grid()

func _on_menu_bar_switch_grids() -> void:
	if GlobalData.current_display_mode == GlobalData.DisplayMode.Images: # switch to collections
		image_grid.visible = false
		collections_grid.visible = true
		GlobalData.current_display_mode = GlobalData.DisplayMode.Collections
	else:
		collections_grid.visible = false
		image_grid.visible = true
		GlobalData.current_display_mode = GlobalData.DisplayMode.Images
	
	_on_grid_grid_updated()

func _on_image_grid_file_replaced() -> void:
	CacheManager.clear_thumb_cache()
	refresh(true)

func _on_collections_grid_edit_collection(collection) -> void:
	if collection_editor.min_size.x > DisplayServer.window_get_size().x || collection_editor.min_size.y > DisplayServer.window_get_size().y:
		collection_editor.size = collection_editor.min_size
	else:
		collection_editor.size = Vector2( get_window().get_size().x * 0.9, get_window().get_size().y * 0.9 )
	
	collection_editor.collection = collection
	collection_editor.popup_centered()
