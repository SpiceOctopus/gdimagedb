extends Control

signal delete
signal move_left
signal move_right

var load_thread = Thread.new()
var image
var collection

@onready var display = $VBoxContainer/TextureRect
@onready var order_label = $VBoxContainer/HBoxContainer/OrderLabel
@onready var button_left = $VBoxContainer/HBoxContainer/MoveLeftButton
@onready var button_right = $VBoxContainer/HBoxContainer/MoveRightButton

func _ready():
	if CacheManager.thumb_cache.has(image["id"]):
		display.texture = CacheManager.thumb_cache[image["id"]]
	else:
		load_thread.start(Callable(self,"async_load"))
	display.custom_minimum_size = Vector2(Settings.grid_image_size, Settings.grid_image_size)
	custom_minimum_size = Vector2(Settings.grid_image_size, display.custom_minimum_size.y + $VBoxContainer/HBoxContainer.custom_minimum_size.y)
	update_order()

func async_load():
	var thumb_path = DB.db_path_to_full_thumb_path(image["path"])
	var dir = DirAccess.open(OS.get_executable_path().get_base_dir())
	if dir.file_exists(thumb_path):
		var tmp = ImageUtil.TextureFromFile(thumb_path)
		display.texture = tmp
		CacheManager.thumb_mutex.lock()
		CacheManager.thumb_cache[image["id"]] = tmp
		CacheManager.thumb_mutex.unlock()
	elif image["path"].get_extension() in Settings.supported_video_files:
		display.texture = load("res://gfx/video_placeholder.png")

func _on_btn_move_left_pressed():
	move_left.emit(image)

func _on_btn_move_right_pressed():
	move_right.emit(image)

func update_order():
	var order = DB.get_position_in_collection(image["id"], collection["id"])
	order_label.text = str(order)
	
	button_left.disabled = false
	button_right.disabled = false
	
	if order <= 0: # first one
		button_left.disabled = true
	
	if order >= (DB.get_collection_count(collection["id"]) - 1): # last one
		button_right.disabled = true

func _on_delete_button_pressed():
	delete.emit(image)
