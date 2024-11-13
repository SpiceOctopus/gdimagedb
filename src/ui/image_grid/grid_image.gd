extends TextureRect

class_name GridImage

signal double_click(media : DBMedia)
signal right_click(media : DBMedia)
signal click(grid_image : GridImage)
signal multi_select

var current_media : DBMedia : 
	set(media):
		current_media = media
		texture = CacheManager.loading_placeholder

var selected : bool = false :
	set(is_selected):
		selected = is_selected
		if(selected):
			material = CacheManager.outline_material
		else:
			material = null

func _ready() -> void:
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture = CacheManager.get_thumbnail(current_media)
	custom_minimum_size = Vector2(Settings.grid_image_size, Settings.grid_image_size)

func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.is_pressed()):
		return
	
	match event.button_index:
		MOUSE_BUTTON_LEFT:
			if not event.double_click:
				if event.shift_pressed:
					multi_select.emit(self)
				else:
					click.emit(self)
			else:
				double_click.emit(current_media)
		MOUSE_BUTTON_RIGHT:
			right_click.emit(current_media)

func reload_thumbnail() -> void:
	texture = CacheManager.get_thumbnail(current_media)
