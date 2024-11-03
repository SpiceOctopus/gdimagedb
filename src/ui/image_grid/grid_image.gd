extends TextureRect

class_name GridImage

signal double_click(media : DBMedia)
signal right_click(media : DBMedia)
signal click(grid_image : GridImage)
signal multi_select

var current_media : DBMedia
var selected : bool = false

func _ready() -> void:
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

func _exit_tree() -> void:
	if current_media != null:
		current_media.free()
	texture = null

func set_media(media : DBMedia) -> void:
	current_media = media
	texture = load("res://gfx/loading.png")

func load_thumbnail() -> void:
	texture = CacheManager.get_thumbnail(current_media)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT and not event.double_click:
		if event.shift_pressed:
			multi_select.emit(self)
		else:
			click.emit(self)
	elif event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
		double_click.emit(current_media)
	elif event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_RIGHT:
		right_click.emit(current_media)

func set_selected(is_selected : bool) -> void:
	selected = is_selected
	if(selected):
		set_material(load("res://ui/image_grid/outline_material.tres"))
	else:
		set_material(null)
