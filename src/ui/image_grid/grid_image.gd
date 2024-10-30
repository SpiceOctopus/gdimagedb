extends TextureRect

class_name GridImage

signal double_click(media : DBMedia)
signal right_click(media : DBMedia)
signal click
signal multi_select

var current_media : DBMedia
var selected = false

func _ready() -> void:
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

func _exit_tree() -> void:
	texture = null

func set_media(media : DBMedia) -> void:
	current_media = media
	texture = load("res://gfx/loading.png")

func load_thumbnail() -> void:
	if CacheManager.thumb_cache.has(current_media.id):
		call_deferred("set_texture", CacheManager.thumb_cache[current_media.id])
	elif current_media.path.get_extension() in Settings.supported_video_files:
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
