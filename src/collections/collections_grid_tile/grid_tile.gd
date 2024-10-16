extends Control

signal double_click
signal right_click

var collection : set=set_collection, get=get_collection
var collection_internal
var load_thread = Thread.new()
var image

@onready var lbl_name = $CollectionNameLabel
@onready var title_image = $TitleImage

func _ready():
	# name label background
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color("DARK_SLATE_GRAY", 0.9)
	lbl_name.add_theme_stylebox_override("normal", stylebox)

func _exit_tree():
	if load_thread.is_started():
		load_thread.wait_to_finish()

func _input(event):
	if get_parent().get_parent().get_parent().visible == false:
		return
	elif ! (event is InputEventMouseButton) || !get_global_rect().has_point(event.global_position):
		return
	
	if event.double_click:
		if DB.get_all_images_in_collection(collection["id"]).size() > 0:
			emit_signal("double_click", collection)
	elif event.is_pressed() and event.button_index == MOUSE_BUTTON_RIGHT:
		emit_signal("right_click", collection)

func set_collection(collection_param):
	lbl_name.text = collection_param["collection"]
	collection_internal = collection_param
	image = DB.get_first_image_in_collection(collection["id"])
	if !image.is_empty():
		if CacheManager.thumb_cache.has(image["id"]):
			title_image.texture = CacheManager.thumb_cache[image["id"]]
		else:
			load_thread.start(Callable(self,"async_load"))

func async_load():
	var thumb_path = DB.db_path_to_full_thumb_path(image["path"])
	var dir = DirAccess.open(OS.get_executable_path().get_base_dir())
	if dir.file_exists(thumb_path):
		var tmp = ImageUtil.TextureFromFile(thumb_path)
		title_image.texture = tmp
		CacheManager.thumb_mutex.lock()
		CacheManager.thumb_cache[image["id"]] = tmp
		CacheManager.thumb_mutex.unlock()
	elif image["path"].get_extension() in Settings.supported_video_files:
		title_image.texture = load("res://gfx/video_placeholder.png")

func get_collection():
	return collection_internal
