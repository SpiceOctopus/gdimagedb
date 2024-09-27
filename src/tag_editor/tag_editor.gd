extends Control

var image : set = set_image

@onready var preview = $MarginContainer/GridContainer2/PreviewAndAssigned/Preview
@onready var add_tag_window = $AddTagDialog
@onready var delete_tag_window = $DeleteTagDialog
@onready var sidebar = $MarginContainer/GridContainer2/VBoxContainer/SideBar

func _ready():
	sidebar.focus()

func set_image(img):
	image = img
	preview.set_display(image)
	sidebar.media_id = image["id"]
	sidebar.rebuild_tag_lists()

func _on_ButtonAddTag_pressed():
	add_tag_window.popup_centered()

func _on_ButtonDeleteTag_pressed():
	delete_tag_window.popup_centered()
