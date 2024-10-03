extends Control

signal double_click
signal right_click

var collection : set=set_collection, get=get_collection
var collection_internal
var image

@onready var lbl_name = $CollectionNameLabel
@onready var title_image = $TitleImage

func _ready():
	# name label background
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color("DARK_SLATE_GRAY", 0.9)
	lbl_name.add_theme_stylebox_override("normal", stylebox)

func _input(event):
	if !visible:
		return
	elif ! (event is InputEventMouseButton) || !get_global_rect().has_point(event.global_position):
		return
	
	if event.double_click:
		if DB.get_all_images_in_collection(collection["id"]).size() > 0:
			double_click.emit(collection)
	elif event.is_pressed() and event.button_index == MOUSE_BUTTON_RIGHT:
		right_click.emit(collection)

func set_collection(collection_param):
	lbl_name.text = collection_param["collection"]
	collection_internal = collection_param
	image = DB.get_first_image_in_collection(collection["id"])
	if !image.is_empty():
		if CacheManager.thumb_cache.has(image["id"]):
			title_image.texture = CacheManager.thumb_cache[image["id"]]
		else:
			WorkerThreadPool.add_task(async_load)

func async_load():
	var thumb_path = DB.db_path_to_full_thumb_path(image["path"])
	var dir = DirAccess.open(OS.get_executable_path().get_base_dir())
	if dir.file_exists(thumb_path):
		var tmp = ImageUtil.TextureFromFile(thumb_path)
		if is_instance_valid(title_image):
			title_image.call_deferred("set_texture", tmp)
		CacheManager.call_deferred("add_thumbnail", image["id"], tmp)
	elif image["path"].get_extension() in Settings.supported_video_files:
		if is_instance_valid(title_image):
			title_image.call_deferred("set_texture", load("res://gfx/video_placeholder.png"))

func get_collection():
	return collection_internal
