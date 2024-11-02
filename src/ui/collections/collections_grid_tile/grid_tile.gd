extends Control

signal double_click
signal right_click
signal click

var collection : set=set_collection
var image : DBMedia

@onready var lbl_name = $CollectionNameLabel
@onready var title_image = $TitleImage

func _ready() -> void:
	# name label background
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color("DARK_SLATE_GRAY", 0.9)
	lbl_name.add_theme_stylebox_override("normal", stylebox)
	GlobalData.connect("db_collections_changed", queue_thumbnail_refresh)
	title_image.texture = load("res://gfx/loading.png")

func _input(event) -> void:
	if !visible:
		return
	elif ! (event is InputEventMouseButton) || !get_global_rect().has_point(event.global_position):
		return
	
	if event.double_click:
		if DB.get_all_images_in_collection(collection["id"]).size() > 0:
			double_click.emit(collection)
	elif event.is_pressed() and event.button_index == MOUSE_BUTTON_RIGHT:
		right_click.emit(collection)

func _gui_input(ev) -> void:
	if !visible:
		return
	if ev is InputEventMouseButton and ev.is_pressed() and ev.button_index == MOUSE_BUTTON_LEFT and !ev.double_click:
		click.emit(self)

func set_collection(collection_param) -> void:
	lbl_name.text = collection_param["collection"]
	collection = collection_param
	image = DB.get_first_image_in_collection(collection["id"])
	var img = CacheManager.get_thumbnail(image)
	if img != null:
		title_image.texture = img
	else:
		title_image.texture = load("res://gfx/collection_placeholder_icon.png")

func set_selected(is_selected : bool) -> void:
	if(is_selected):
		title_image.set_material(load("res://ui/image_grid/outline_material.tres"))
	else:
		title_image.set_material(null)

func queue_thumbnail_refresh() -> void:
	image = DB.get_first_image_in_collection(collection["id"])
	if not image == null:
		if CacheManager.thumb_cache.has(image.id):
			title_image.texture = CacheManager.thumb_cache[image.id]
	else:
		title_image.texture = load("res://gfx/collection_placeholder_icon.png")
