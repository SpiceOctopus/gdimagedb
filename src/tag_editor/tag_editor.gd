extends Control

var image : set = set_image
var all_tags
var all_tag_counts
var tags_on_image

@onready var all_tags_list = $MarginContainer/GridContainer2/LeftSideControls/AllTagsList
@onready var text_input = $MarginContainer/GridContainer2/LeftSideControls/TextInput/FilterAllTags
@onready var preview = $MarginContainer/GridContainer2/PreviewAndAssigned/Preview
@onready var assigned_tags_list = $MarginContainer/GridContainer2/PreviewAndAssigned/TagsOnImage
@onready var button_tag_image = $MarginContainer/GridContainer2/LeftSideControls/Buttons/ButtonTagImage
@onready var button_untag_image = $MarginContainer/GridContainer2/LeftSideControls/Buttons/ButtonUntagImage
@onready var add_tag_window = $AddTagDialog
@onready var delete_tag_window = $DeleteTagDialog

func _ready():
	GlobalData.connect("db_tags_changed", _on_db_tags_changed)
	text_input.grab_focus()

func _input(event):
	if (event.is_action_pressed("ui_up") || event.is_action_pressed("ui_down")) && text_input.has_focus():
		_on_FilterAllTags_gui_input(event)
		get_viewport().set_input_as_handled()

func set_image(img):
	image = img
	all_tags = DB.get_all_tags()
	all_tag_counts = DB.get_all_tag_counts()
	for tag in all_tags:
		if all_tag_counts.has(tag["id"]):
			tag["count"] = all_tag_counts[tag["id"]]
		else:
			tag["count"] = 0
	all_tags.sort_custom(sort_by_count)
	tags_on_image = DB.get_tags_for_image(image["id"])
	$MarginContainer/GridContainer2/PreviewAndAssigned/Preview.set_display(image)
	set_all_tags_list()
	set_assigned_tags_list()
	button_tag_image.disabled = (all_tags_list.get_item_count() <= 0)
	button_untag_image.disabled = (assigned_tags_list.get_item_count() <= 0)

func sort_by_count(a, b):
	if a["count"] > b["count"]:
		return true
	return false

func _on_FilterAllTags_text_changed(_new_text):
	set_all_tags_list()
	if all_tags_list.get_item_count() > 0:
		all_tags_list.select(0)

func _on_ButtonAddTag_pressed():
	add_tag_window.popup_centered()

func _on_ButtonDeleteTag_pressed():
	delete_tag_window.popup_centered()

func set_all_tags_list():
	all_tags_list.clear()
	
	if text_input.text == "":
		for tag in all_tags:
			var addTag = true
			for tagImg in tags_on_image:
				if tag["tag"] == tagImg["tag"]:
					addTag = false
			if(addTag):
				all_tags_list.add_item(tag["tag"])
		
		if all_tags_list.get_item_count() > 0:
			all_tags_list.select(0)
		return
	
	for tag in all_tags:
		if text_input.text.to_lower() in tag["tag"].to_lower():
			var add_tag = true
			for tagImg in tags_on_image:
				if tag["tag"] == tagImg["tag"]:
					add_tag = false
			if add_tag:
				all_tags_list.add_item(tag["tag"])
	
	if all_tags_list.get_item_count() > 0:
		all_tags_list.select(0)
	
	button_tag_image.disabled = (all_tags_list.get_item_count() <= 0)

func set_assigned_tags_list():
	assigned_tags_list.clear()
	for tag in tags_on_image:
		assigned_tags_list.add_item(tag["tag"])
	if assigned_tags_list.get_item_count() > 0:
		assigned_tags_list.select(0)

func _on_ButtonTagImage_button_up():
	if not all_tags_list.is_anything_selected():
		return
	
	DB.add_tag_to_image(DB.get_tag_id(all_tags_list.get_item_text(all_tags_list.get_selected_items()[0])), image["id"])
	tags_on_image = DB.get_tags_for_image(image["id"])
	set_assigned_tags_list()
	set_all_tags_list()
	assigned_tags_list.select(0)
	button_tag_image.disabled = (all_tags_list.get_item_count() <= 0)
	button_untag_image.disabled = (assigned_tags_list.get_item_count() <= 0)

func _on_ButtonUntagImage_button_up():
	if not assigned_tags_list.is_anything_selected():
		return
	
	DB.remove_tag_from_image(DB.get_tag_id(assigned_tags_list.get_item_text(assigned_tags_list.get_selected_items()[0])), image["id"])
	tags_on_image = DB.get_tags_for_image(image["id"])
	set_assigned_tags_list()
	set_all_tags_list()
	if assigned_tags_list.get_item_count() > 0:
		assigned_tags_list.select(0)
	button_tag_image.disabled = (all_tags_list.get_item_count() <= 0)
	button_untag_image.disabled = (assigned_tags_list.get_item_count() <= 0)

func _on_FilterAllTags_gui_input(event):
	if event.is_action_pressed("ui_accept"):
		if all_tags_list.get_item_count() <= 0:
			return
		DB.add_tag_to_image(DB.get_tag_by_name(all_tags_list.get_item_text(all_tags_list.get_selected_items()[0]))["id"], image["id"])
		text_input.text = ""
		tags_on_image = DB.get_tags_for_image(image["id"])
		set_assigned_tags_list()
		set_all_tags_list()
		button_tag_image.disabled = (all_tags_list.get_item_count() <= 0)
		button_untag_image.disabled = (assigned_tags_list.get_item_count() <= 0)
	elif event.is_action_pressed("ui_up"):
		if all_tags_list.get_selected_items()[0] > 0:
			all_tags_list.select(all_tags_list.get_selected_items()[0] - 1)
	elif event.is_action_pressed("ui_down"):
		if all_tags_list.get_item_count() > 1 && (all_tags_list.get_selected_items()[0] < (all_tags_list.get_item_count() - 1)):
			all_tags_list.select(all_tags_list.get_selected_items()[0] + 1)

func _on_db_tags_changed():
	all_tags = DB.get_all_tags()
	set_all_tags_list()
