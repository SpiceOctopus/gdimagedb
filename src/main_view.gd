extends Control

var tag_editor_scene = load("res://tag_editor/tag_editor.tscn")

@onready var grid = $VBoxContainer/HBoxContainer/Content/MarginContainer/ImageGrid
@onready var collections_grid = $VBoxContainer/HBoxContainer/Content/MarginContainer/CollectionsGrid
@onready var side_bar = $VBoxContainer/HBoxContainer/MarginContainer/SideBar
@onready var menu_bar = $VBoxContainer/MenuBar
@onready var import_log = $ImportLog

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
	var tag_editor_window = Window.new()
	tag_editor_window.hide() # super weird bugfix to make popup_centered work
	add_child(tag_editor_window)
	tag_editor_window.title = "Tag Editor"
	var tag_editor_instance = tag_editor_scene.instantiate()
	tag_editor_window.add_child(tag_editor_instance)
	
	# size
	if tag_editor_instance.custom_minimum_size.x > DisplayServer.window_get_size().x || tag_editor_instance.custom_minimum_size.y > DisplayServer.window_get_size().y:
		tag_editor_window.min_size = tag_editor_instance.custom_minimum_size
		tag_editor_window.size = tag_editor_instance.custom_minimum_size
	else:
		tag_editor_window.min_size = tag_editor_instance.custom_minimum_size
		tag_editor_window.size = Vector2( get_window().get_size().x * 0.9, get_window().get_size().y * 0.9 )
	
	tag_editor_window.connect('close_requested',Callable(tag_editor_window,'queue_free'))
	tag_editor_window.popup_centered()
	tag_editor_instance.image = image

func _on_menu_bar_refresh_grid():
	refresh()

func _on_grid_grid_updated():
	if side_bar == null:
		return
	
	if GlobalData.current_display_mode == GlobalData.DisplayMode.Images:
		side_bar.get_node("MarginContainer/VBoxContainer/GridInfoPanel").set_grid_items_count(grid.current_images.size())
	elif GlobalData.current_display_mode == GlobalData.DisplayMode.Collections:
		side_bar.get_node("MarginContainer/VBoxContainer/GridInfoPanel").set_grid_items_count(collections_grid.grid_item_count())

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
