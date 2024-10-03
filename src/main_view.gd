extends Control

@onready var grid = $VBoxContainer/HBoxContainer/Content/ImageGrid
@onready var collections_grid = $VBoxContainer/HBoxContainer/Content/CollectionsGrid
@onready var side_bar = $VBoxContainer/HBoxContainer/VBoxContainer/SideBar
@onready var menu_bar = $VBoxContainer/MenuBar
@onready var import_log = $ImportLog
@onready var grid_info_panel = $VBoxContainer/HBoxContainer/VBoxContainer/GridInfoPanel
@onready var tag_editor = $TagEditor
@onready var collection_editor = $CollectionEditor

# Called when the node enters the scene tree for the first time.
func _ready():
	get_tree().root.connect("files_dropped",Callable(self,"_on_files_dropped"))
	_on_grid_grid_updated()

func _input(_event):
	if Input.is_action_just_pressed("ui_filedialog_refresh"):
		refresh()
	if Input.is_action_just_pressed("clear_thumb_cache_refresh"):
		CacheManager.thumb_mutex.lock()
		CacheManager.thumb_cache.clear()
		CacheManager.thumb_mutex.unlock()
		refresh(true)
	if Input.is_action_just_pressed("help"):
		GlobalData.notify_help_called()

# The timers in this function are required to give the ui time to update.
# Without the timer the import log will just be a black window.
func _on_files_dropped(files):
	import_log.clear_messages()
	import_log.popup_centered()
	
	await get_tree().create_timer(0.1).timeout
	
	for file in files:
		var error = ImportUtil.import_image(file)
		if error == OK:
			import_log.add_message("File %s successfully imported." % file)
			await get_tree().create_timer(0.1).timeout
		elif error == ERR_ALREADY_EXISTS:
			import_log.add_message("File %s already in db." % file)
			await get_tree().create_timer(0.1).timeout
		elif error == ERR_FILE_UNRECOGNIZED:
			import_log.add_message("File type %s not supported." & file.get_extension())
			await get_tree().create_timer(0.1).timeout

	GlobalData.notify_db_images_changed()

func _on_grid_tag_edit(image):
	if tag_editor.min_size.x > DisplayServer.window_get_size().x || tag_editor.min_size.y > DisplayServer.window_get_size().y:
		tag_editor.size = tag_editor.min_size
	else:
		tag_editor.size = Vector2( get_window().get_size().x * 0.9, get_window().get_size().y * 0.9 )
	
	tag_editor.popup_centered()
	tag_editor.media = grid.current_images.duplicate()
	tag_editor.set_current(image["id"])

func _on_menu_bar_refresh_grid():
	refresh()

func _on_grid_grid_updated():
	if side_bar == null:
		return
	
	if GlobalData.current_display_mode == GlobalData.DisplayMode.Images:
		grid_info_panel.set_grid_items_count(grid.current_images.size())
	elif GlobalData.current_display_mode == GlobalData.DisplayMode.Collections:
		grid_info_panel.set_grid_items_count(collections_grid.grid_item_count())

func _on_menu_bar_sort_mode_changed(mode):
	grid.sort_mode = mode

func refresh(hard : bool = false):
	if GlobalData.current_display_mode == GlobalData.DisplayMode.Images:
		grid.refresh_grid(hard)
	elif GlobalData.current_display_mode == GlobalData.DisplayMode.Collections:
		collections_grid.reset_grid()

func _on_menu_bar_switch_grids():
	if GlobalData.current_display_mode == GlobalData.DisplayMode.Images: # switch to collections
		grid.visible = false
		collections_grid.visible = true
		GlobalData.current_display_mode = GlobalData.DisplayMode.Collections
	else:
		collections_grid.visible = false
		grid.visible = true
		GlobalData.current_display_mode = GlobalData.DisplayMode.Images
	
	_on_grid_grid_updated()

func _on_image_grid_file_replaced():
	CacheManager.thumb_mutex.lock()
	CacheManager.thumb_cache.clear()
	CacheManager.thumb_mutex.unlock()
	refresh(true)

func _on_collections_grid_edit_collection(collection):
	if collection_editor.min_size.x > DisplayServer.window_get_size().x || collection_editor.min_size.y > DisplayServer.window_get_size().y:
		collection_editor.size = collection_editor.min_size
	else:
		collection_editor.size = Vector2( get_window().get_size().x * 0.9, get_window().get_size().y * 0.9 )
	
	collection_editor.collection = collection
	collection_editor.popup_centered()
