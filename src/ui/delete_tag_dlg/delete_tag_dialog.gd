extends Window

var previews : Array[TextureRect]

@onready var tags : Array[DBTag] = DB.get_all_tags()
@onready var filter_edit = $MarginContainer/HBoxContainer/VBoxContainer2/FilterEdit
@onready var tag_list = $MarginContainer/HBoxContainer/VBoxContainer2/TagList
@onready var preview1 = $MarginContainer/HBoxContainer/VBoxContainer/TopContainer/Preview1
@onready var preview2 = $MarginContainer/HBoxContainer/VBoxContainer/TopContainer/Preview2
@onready var preview3 = $MarginContainer/HBoxContainer/VBoxContainer/TopContainer/Preview3
@onready var preview4 = $MarginContainer/HBoxContainer/VBoxContainer/MiddleContainer/Preview4
@onready var preview5 = $MarginContainer/HBoxContainer/VBoxContainer/MiddleContainer/Preview5
@onready var preview6 = $MarginContainer/HBoxContainer/VBoxContainer/MiddleContainer/Preview6
@onready var preview7 = $MarginContainer/HBoxContainer/VBoxContainer/BottomContainer/Preview7
@onready var preview8 = $MarginContainer/HBoxContainer/VBoxContainer/BottomContainer/Preview8
@onready var preview9 = $MarginContainer/HBoxContainer/VBoxContainer/BottomContainer/Preview9
@onready var empty_preview = load("res://gfx/dark_background.png")

func _ready() -> void:
	previews = [preview1, preview2, preview3, preview4, preview5, preview6, preview7, preview8, preview9]

func _on_DeleteButton_pressed() -> void:
	var id : int
	for tag : DBTag in tags:
		if tag.tag == tag_list.get_item_text((tag_list.get_selected_items()[0])):
			id = tag.id
			break
	
	DB.delete_tag(id)
	
	for included_tag : DBTag in GlobalData.included_tags:
		if included_tag.id == id:
			GlobalData.included_tags.erase(included_tag)
	for excluded_tag : DBTag in GlobalData.excluded_tags:
		if excluded_tag.id == id:
			GlobalData.excluded_tags.erase(excluded_tag)
	filter_edit.text = ""
	
	GlobalData.notify_db_tags_changed()
	GlobalData.notify_tags_changed()
	tags = DB.get_all_tags()
	update_tag_list()

func _on_filter_edit_text_changed(_new_text : String) -> void:
	update_tag_list()

func update_tag_list() -> void:
	tag_list.clear()
	if filter_edit.text == "":
		for tag : DBTag in tags:
			tag_list.add_item(tag.tag)
	else:
		for tag : DBTag in tags:
			if filter_edit.text.to_lower() in tag.tag.to_lower():
				tag_list.add_item(tag.tag)
	if tag_list.item_count > 0:
		tag_list.select(0)
		_on_tag_list_item_selected(0)

func _on_tag_list_item_selected(index : int) -> void:
	var counter : int = 0
	for media : DBMedia in DB.get_images_for_tags([DB.get_tag_by_name(tag_list.get_item_text(index))]):
		previews[counter].texture = CacheManager.get_thumbnail(media)
		counter += 1
		if counter > 8:
			break
	
	if counter < 8: # fill in placeholders
		for i in (9 - counter):
			previews[counter + i].texture = empty_preview

func reset_window() -> void:
	filter_edit.text = ""
	tags = DB.get_all_tags()
	filter_edit.grab_focus()
	update_tag_list()

func _on_close_requested() -> void:
	hide()

func _on_about_to_popup() -> void:
	reset_window()
