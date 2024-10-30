extends Window

var media_set : Array[DBMedia]
var current_media : int = 0

@onready var preview = $MarginContainer/GridContainer2/Preview
@onready var sidebar = $MarginContainer/GridContainer2/VBoxContainer/SideBar

func set_current(id):
	preview.media_set = media_set
	
	for media in media_set:
		if media.id == id:
			current_media = media_set.find(media)
			preview.current_image = current_media
	
	preview.set_display(media_set[current_media])
	sidebar.media_id = media_set[current_media].id
	sidebar._on_display_changed() # updates both tag lists

func _input(event):
	if !event is InputEventKey:
		return
	if Input.is_action_just_pressed("ui_right"):
		current_media += 1
		if current_media > media_set.size() - 1:
			current_media = 0
		preview.set_next_image()
		sidebar.media_id = media_set[current_media].id
		sidebar._on_display_changed() # updates both tag lists
		sidebar.focus()
	elif Input.is_action_just_pressed("ui_left"):
		if current_media == 0:
			current_media = media_set.size() - 1
		else:
			current_media -= 1
		preview.set_previous_image()
		sidebar.media_id = media_set[current_media].id
		sidebar._on_display_changed() # updates both tag lists
		sidebar.focus()

func _on_close_requested():
	preview.stop_video()
	hide()

func _on_about_to_popup() -> void:
	sidebar.focus()
	sidebar.clear_filter_text()
