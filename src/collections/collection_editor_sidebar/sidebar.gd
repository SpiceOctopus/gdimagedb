extends Control

var collection : set = set_collection
var collection_tags
var all_tags

@onready var all_tags_list = $MarginContainer/MainContainer/AllTagsList
@onready var assigned_tags_list = $MarginContainer/MainContainer/AssignedTagsList
@onready var filter_edit = $MarginContainer/MainContainer/TagFilterContainer/FilterEdit
@onready var apply_name_button = $MarginContainer/MainContainer/NameContainer/ApplyNameButton
@onready var assign_tag_button = $MarginContainer/MainContainer/TagButtons/AssignButton
@onready var remove_tag_button = $MarginContainer/MainContainer/TagButtons/RemoveButton
@onready var name_edit = $MarginContainer/MainContainer/NameContainer/NameEdit
@onready var add_tag = $AddTagDialog
@onready var delete_tag = $DeleteTagDialog

func _ready():
	GlobalData.connect("db_tags_changed",Callable(self,"_on_db_tags_changed"))

func set_collection(collection_in):
	collection = collection_in
	_on_filter_edit_text_changed("") # set up all tags list
	name_edit.text = collection["collection"]
	refresh_assigned_tags()

func _on_filter_edit_text_changed(new_text):
	all_tags_list.clear()
	all_tags = DB.get_all_tags()
	var assigned_tags = DB.get_tags_for_collection(collection["id"])
	
	if new_text.is_empty():
		for tag in all_tags:
			if !(tag in assigned_tags):
				all_tags_list.add_item(tag["tag"])
	else:
		for tag in all_tags:
			if new_text.to_lower() in tag["tag"].to_lower() && !(tag in assigned_tags):
				all_tags_list.add_item(tag["tag"])
	
	if all_tags_list.item_count > 0:
		all_tags_list.select(0)
		assign_tag_button.disabled = false
	else:
		assign_tag_button.disabled = true

func refresh_assigned_tags():
	assigned_tags_list.clear()
	collection_tags = DB.get_tags_for_collection(collection["id"])
	
	for tag in collection_tags:
		assigned_tags_list.add_item(tag["tag"])
	
	if assigned_tags_list.item_count > 0:
		assigned_tags_list.select(0)
		remove_tag_button.disabled = false
	else:
		remove_tag_button.disabled = true

func _on_name_edit_text_changed(new_text):
	apply_name_button.disabled = new_text.is_empty()

func _on_apply_name_button_pressed():
	DB.set_collection_name(collection["id"], name_edit.text)

func _on_new_tag_button_pressed():
	add_tag.popup_centered()

func _on_delete_tag_button_pressed():
	delete_tag.popup_centered()

func _on_db_tags_changed():
	_on_filter_edit_text_changed(filter_edit.text)
	refresh_assigned_tags()

func _on_assign_button_pressed():
	var tag = DB.get_tag_by_name(all_tags_list.get_item_text(all_tags_list.get_selected_items()[0]))
	DB.add_tag_to_collection(tag["id"], collection["id"])
	_on_db_tags_changed()

func _on_remove_button_pressed():
	var tag = DB.get_tag_by_name(assigned_tags_list.get_item_text(assigned_tags_list.get_selected_items()[0]))
	DB.remove_tag_from_collection(tag["id"], collection["id"])
	_on_db_tags_changed()

func _on_filter_edit_text_submitted(_new_text):
	_on_assign_button_pressed()
	filter_edit.text = ""
	_on_filter_edit_text_changed("")

func _on_name_edit_text_submitted(new_text):
	if !new_text.is_empty():
		_on_apply_name_button_pressed()

func _on_filter_edit_gui_input(event):
	if event.is_action_pressed("ui_up"):
		if all_tags_list.get_selected_items()[0] > 0:
			all_tags_list.select(all_tags_list.get_selected_items()[0] - 1)
	elif event.is_action_pressed("ui_down"):
		if all_tags_list.get_item_count() > 1 && (all_tags_list.get_selected_items()[0] < (all_tags_list.get_item_count() - 1)):
			all_tags_list.select(all_tags_list.get_selected_items()[0] + 1)
