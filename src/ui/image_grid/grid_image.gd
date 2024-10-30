extends TextureRect

class_name GridImage

signal double_click(media : DBMedia)
signal right_click(media : DBMedia)
signal click
signal multi_select

var current_media : DBMedia
var selected = false
var exiting : bool = false

func _ready() -> void:
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

func _exit_tree() -> void:
	exiting = true
	texture = null

func set_media(media : DBMedia) -> void:
	current_media = media
	
	if CacheManager.thumb_cache.has(current_media.id):
		texture = CacheManager.thumb_cache[current_media.id]
	else:
		texture = load("res://gfx/loading.png")
		WorkerThreadPool.add_task(async_load)

func async_load() -> void:
	if exiting:
		return
	var dir : DirAccess = DirAccess.open(OS.get_executable_path().get_base_dir())
	if dir.file_exists(current_media.thumb_path):
		var tmp : ImageTexture = ImageUtil.TextureFromFile(current_media.thumb_path)
		if not is_instance_valid(self):
			return
		call_deferred("set_texture", tmp)
		CacheManager.call_deferred("add_thumbnail", current_media.id, tmp)
	elif current_media.path.get_extension() in Settings.supported_video_files:
		if is_instance_valid(self):
			call_deferred("set_texture", load("res://gfx/video_placeholder.png"))

func _gui_input(ev) -> void:
	if ev is InputEventMouseButton and ev.is_pressed() and ev.button_index == MOUSE_BUTTON_LEFT and !ev.double_click:
		if ev.shift_pressed:
			multi_select.emit(self)
		else:
			click.emit(self)
	elif ev is InputEventMouseButton and ev.is_pressed() and ev.button_index == MOUSE_BUTTON_LEFT and ev.double_click:
		double_click.emit(current_media)
	elif ev is InputEventMouseButton and ev.is_pressed() and ev.button_index == MOUSE_BUTTON_RIGHT:
		right_click.emit(current_media)

func set_selected(is_selected : bool) -> void:
	selected = is_selected
	if(selected):
		set_material(load("res://ui/image_grid/outline_material.tres"))
	else:
		set_material(null)
