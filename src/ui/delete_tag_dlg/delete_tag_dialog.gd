extends Window

var images_for_tag
var previews

@onready var filter_edit = $MarginContainer/HBoxContainer/VBoxContainer2/FilterEdit
@onready var tag_list = $MarginContainer/HBoxContainer/VBoxContainer2/TagList
@onready var tags = DB.get_all_tags()
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

func _ready():
	previews = [preview1, preview2, preview3, preview4, preview5, preview6, preview7, preview8, preview9]
	reset_window()

func _on_DeleteButton_pressed():
	var id
	for tag in tags:
		if tag["tag"] == tag_list.get_item_text((tag_list.get_selected_items()[0])):
			id = tag["id"]
			break
	
	DB.delete_tag(id)
	
	for included_tag in GlobalData.included_tags:
		if included_tag["id"] == id:
			GlobalData.included_tags.erase(included_tag)
	for excluded_tag in GlobalData.excluded_tags:
		if excluded_tag["id"] == id:
			GlobalData.excluded_tags.erase(excluded_tag)
	filter_edit.text = ""
	
	GlobalData.notify_db_tags_changed()
	GlobalData.notify_tags_changed()
	update_tag_list()

func _on_filter_edit_text_changed(_new_text : String):
	update_tag_list()

func update_tag_list():
	tag_list.clear()
	if filter_edit.text == "":
		for tag in tags:
			tag_list.add_item(tag["tag"])
	else:
		for tag in tags:
			if filter_edit.text.to_lower() in tag["tag"].to_lower():
				tag_list.add_item(tag["tag"])
	if tag_list.item_count > 0:
		tag_list.select(0)
		_on_tag_list_item_selected(0)

func _on_tag_list_item_selected(index):
	var images = DB.get_images_for_tags([DB.get_tag_by_name(tag_list.get_item_text(index))])
	
	var counter = 0
	for image in images:
		set_thumb(image, previews[counter])
		counter += 1
		if counter > 8:
			break
	
	if counter < 8: # fill in placeholders
		for i in (9 - counter):
			previews[counter + i].texture = empty_preview

func set_thumb(image, preview : TextureRect):
	if CacheManager.thumb_cache.has(image["id"]):
		preview.texture = CacheManager.thumb_cache[image["id"]]
	else:
		preview.texture = ImageUtil.TextureFromFile(DB.db_path_to_full_thumb_path(image["path"]))

func reset_window():
	filter_edit.text = ""
	filter_edit.grab_focus()
	update_tag_list()

func _on_close_requested():
	hide()

func _on_about_to_popup():
	reset_window()
