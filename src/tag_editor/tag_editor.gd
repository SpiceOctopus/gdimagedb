extends Control

var image : set = set_image

@onready var preview = $MarginContainer/GridContainer2/Preview
@onready var sidebar = $MarginContainer/GridContainer2/VBoxContainer/SideBar

func _ready():
	sidebar.focus()

func set_image(img):
	image = img
	preview.set_display(image)
	sidebar.media_id = image["id"]
	sidebar.rebuild_tag_lists()
