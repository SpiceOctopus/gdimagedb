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
	get_tree().root.files_dropped.connect(_on_files_dropped)
	update_grid_info_panel() # the main scene should have its ready call finish last

func _input(_event) -> void:
	if Input.is_action_just_pressed("ui_filedialog_refresh"): # ui_filedialog_refresh <- happens to be assigned to F5 per default
		refresh()
	if Input.is_action_just_pressed("help"):
		GlobalData.help.emit()

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
			await get_tree().create_timer(0.01).timeout
		elif error == ERR_ALREADY_EXISTS:
			import_log.add_message("File %s already in db." % file)
			await get_tree().create_timer(0.01).timeout
		elif error == ERR_FILE_UNRECOGNIZED:
			import_log.add_message("File type %s not supported." % file.get_extension())
			await get_tree().create_timer(0.01).timeout
	
	if import_counter > 0:
		image_grid.load_missing_previews()

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

func update_grid_info_panel() -> void:
	if side_bar == null:
		return
	if GlobalData.current_display_mode == GlobalData.DisplayMode.IMAGES:
		grid_info_panel.set_grid_items_count(image_grid.current_media.size())
	elif GlobalData.current_display_mode == GlobalData.DisplayMode.COLLECTIONS:
		grid_info_panel.set_grid_items_count(collections_grid.grid_item_count())

# hard refresh = clear cache
func refresh() -> void:
	if GlobalData.current_display_mode == GlobalData.DisplayMode.IMAGES:
		image_grid.trigger_visibility_update()
	elif GlobalData.current_display_mode == GlobalData.DisplayMode.COLLECTIONS:
		collections_grid.refresh_grid()

func _on_menu_bar_switch_grids() -> void:
	if GlobalData.current_display_mode == GlobalData.DisplayMode.IMAGES: # switch to collections
		image_grid.visible = false
		collections_grid.visible = true
		GlobalData.current_display_mode = GlobalData.DisplayMode.COLLECTIONS
	else:
		collections_grid.visible = false
		image_grid.visible = true
		GlobalData.current_display_mode = GlobalData.DisplayMode.IMAGES
	
	update_grid_info_panel()

func _on_collections_grid_edit_collection(collection : DBCollection) -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_MAXIMIZED:
		collection_editor.mode = Window.MODE_MAXIMIZED
	else:
		collection_editor.mode = Window.MODE_WINDOWED
		collection_editor.size = Vector2( get_window().get_size().x * 0.9, get_window().get_size().y * 0.9 )
	
	collection_editor.collection = collection
	collection_editor.popup_centered()

func _on_collection_editor_name_changed(collection: DBCollection) -> void:
	collections_grid.update_tile(collection)
