extends TextureRect

class_name GridImage

signal double_click
signal right_click
signal click
signal multi_select

var current_image
var selected = false

func _ready():
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

func _exit_tree():
	texture = null

# param is a row of image data from the db
func set_image(image):
	current_image = image
	
	if CacheManager.thumb_cache.has(current_image["id"]):
		texture = CacheManager.thumb_cache[current_image["id"]]
	else:
		WorkerThreadPool.add_task(async_load)

func async_load():
	var thumb_path = DB.db_path_to_full_thumb_path(current_image["path"])
	var dir = DirAccess.open(OS.get_executable_path().get_base_dir())
	if dir.file_exists(thumb_path):
		var tmp = ImageUtil.TextureFromFile(thumb_path)
		call_deferred("set_image_internal", tmp)
		CacheManager.call_deferred("add_thumbnail", current_image["id"], tmp)
	elif current_image["path"].get_extension() in Settings.supported_video_files:
		call_deferred("set_image_internal", load("res://gfx/video_placeholder.png"))

func _gui_input(ev):
	if ev is InputEventMouseButton and ev.is_pressed() and ev.button_index == MOUSE_BUTTON_LEFT and !ev.double_click:
		if ev.shift_pressed:
			multi_select.emit(self)
		else:
			click.emit(self)
	elif ev is InputEventMouseButton and ev.is_pressed() and ev.button_index == MOUSE_BUTTON_LEFT and ev.double_click:
		double_click.emit(current_image)
	elif ev is InputEventMouseButton and ev.is_pressed() and ev.button_index == MOUSE_BUTTON_RIGHT:
		right_click.emit(current_image)

func set_selected(is_selected):
	selected = is_selected
	if(selected):
		set_material(load("res://ui/image_grid/outline_material.tres"))
	else:
		set_material(null)

func set_image_internal(image):
	texture = image
