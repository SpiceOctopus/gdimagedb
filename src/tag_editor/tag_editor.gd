extends Window

var media
var current_media : int = 0

@onready var preview = $MarginContainer/GridContainer2/Preview
@onready var sidebar = $MarginContainer/GridContainer2/VBoxContainer/SideBar

func _ready():
	sidebar.focus()

func set_current(id):
	preview.images = media
	
	for image in media:
		if image["id"] == id:
			current_media = media.find(image)
			preview.current_image = current_media
	
	preview.set_display(media[current_media])
	sidebar.media_id = media[current_media]["id"]
	sidebar._on_display_changed() # updates both tag lists

func _input(event):
	if !event is InputEventKey:
		return
	if Input.is_action_just_pressed("ui_right"):
		current_media += 1
		if current_media > media.size() - 1:
			current_media = 0
		preview.set_next_image()
		sidebar.media_id = media[current_media]["id"]
		sidebar._on_display_changed() # updates both tag lists
	elif Input.is_action_just_pressed("ui_left"):
		if current_media == 0:
			current_media = media.size() - 1
		else:
			current_media -= 1
		preview.set_previous_image()
		sidebar.media_id = media[current_media]["id"]
		sidebar._on_display_changed() # updates both tag lists

func _on_close_requested():
	hide()
