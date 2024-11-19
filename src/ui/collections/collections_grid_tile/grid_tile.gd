extends Control

signal double_click(collection : DBCollection)
signal right_click(collection : DBCollection)
signal click

var image : DBMedia
var collection : DBCollection :
	set(collection_param):
		if collection_param == null:
			collection = null
			return
		
		collection = collection_param
		image = DB.get_first_image_in_collection(collection.id)

@onready var lbl_name = $CollectionNameLabel
@onready var title_image = $TitleImage

func _ready() -> void:
	# name label background
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color("DARK_SLATE_GRAY", 0.9)
	lbl_name.add_theme_stylebox_override("normal", stylebox)
	GlobalData.db_collections_changed.connect(thumbnail_refresh)
	title_image.texture = CacheManager.loading_placeholder
	custom_minimum_size = Vector2(Settings.grid_image_size, Settings.grid_image_size)
	lbl_name.text = collection.name
	var img = CacheManager.get_thumbnail(image)
	if img != null:
		title_image.texture = img
	else:
		title_image.texture = CacheManager.collection_placeholder

func _input(event: InputEvent) -> void:
	if not visible:
		return
	elif not (event is InputEventMouseButton) || !get_global_rect().has_point(event.global_position):
		return
	
	if event.double_click:
		if DB.get_all_images_in_collection(collection.id).size() > 0:
			double_click.emit(collection)
	elif event.is_pressed() and event.button_index == MOUSE_BUTTON_RIGHT:
		right_click.emit(collection)

func _gui_input(event: InputEvent) -> void:
	if !visible:
		return
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT and !event.double_click:
		click.emit(self)

func set_selected(is_selected : bool) -> void:
	if(is_selected):
		title_image.material = CacheManager.outline_material
	else:
		title_image.material = null

func thumbnail_refresh() -> void:
	image = DB.get_first_image_in_collection(collection.id)
	if not image == null:
		title_image.texture = CacheManager.get_thumbnail(image)
	else:
		title_image.texture = CacheManager.collection_placeholder
