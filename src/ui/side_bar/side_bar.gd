extends Control

var tag_item_instance = load("res://ui/side_bar/tag_item.tscn").instantiate()

var selection_offset : int = 0
var visible_tags_count : int = 0
var last_filter : String = ""
var all_tags

@onready var input_box = $MarginContainer/VBoxContainer/Filter
@onready var selected_tags_list = $MarginContainer/VBoxContainer/Panel2/ScrollContainer2/SelectedTags
@onready var tag_preview_list = $MarginContainer/TagPreviewList
@onready var all_tags_list = $MarginContainer/VBoxContainer/Panel/ScrollContainer/AllTags

func _ready():
	rebuild_tag_lists()
	GlobalData.connect("display_mode_changed", _on_display_changed)
	GlobalData.connect("db_tags_changed", _on_db_tags_changed)

func rebuild_tag_lists():
	all_tags = DB.get_all_tags()
	
	# reset and fill all_tags list
	for item in all_tags_list.get_children():
		item.queue_free()
	for tag in all_tags:
		var item = tag_item_instance.duplicate()
		item.tag = tag
		item.connect("add", _on_tag_item_add)
		item.connect("remove", _on_tag_item_remove)
		all_tags_list.add_child(item)
	
	# reset and fill selected_tags list
	for item in selected_tags_list.get_children():
		item.queue_free()
	for tag in all_tags:
		var item = tag_item_instance.duplicate()
		item.tag = tag
		item.connect("x", _on_tag_item_x)
		selected_tags_list.add_child(item)
		item.set_button_visibility(false, false, true)
	
	# set correct state
	update_all_tags_list()
	update_selected_tags_list()

# optional parameter allows direct call from filter linedit signal
func update_all_tags_list(_from_text_changed = ""):
	var filter = input_box.text
	if filter != last_filter:
		last_filter = filter
		selection_offset = 0
	var selection_offset_temp = selection_offset
	visible_tags_count = 0
	if filter.begins_with("-"): # prefix not relevant for filtering
		filter = filter.trim_prefix("-")
	
	for item in all_tags_list.get_children():
		item.reset()
		item.visible = !(item.tag in GlobalData.included_tags || item.tag in GlobalData.excluded_tags)
		if !item.visible:
			continue # item is in a selection, no more filters apply
		
		item.visible = filter in item.tag["tag"].to_lower()
		
		if filter == "":
			item.visible = true
	
	for item in all_tags_list.get_children():
		if item.visible:
			visible_tags_count = visible_tags_count +1
	
	# select first visible item
	for item in all_tags_list.get_children():
		if item.visible:
			if selection_offset_temp <= 0:
				item.selected = true
				return
			else:
				selection_offset_temp = selection_offset_temp - 1

func update_selected_tags_list():
	for item in selected_tags_list.get_children():
		item.reset()
		item.visible = (item.tag in GlobalData.included_tags || item.tag in GlobalData.excluded_tags)

func _on_display_changed():
	update_all_tags_list()
	update_selected_tags_list()

func _on_LineEdit_gui_input(event):
	if event.is_action_pressed("ui_up"):
		selection_offset = selection_offset - 1
		if selection_offset < 0:
			selection_offset = 0
		update_all_tags_list()
	elif event.is_action_pressed("ui_down"):
		selection_offset = selection_offset + 1
		if selection_offset > visible_tags_count - 1:
			selection_offset = visible_tags_count - 1
		update_all_tags_list()

func _on_tag_preview_list_gui_input(event):
	if event.is_action_pressed("ui_accept"):
		_on_LineEdit_gui_input(event)

func _on_tag_item_add(tag):
	GlobalData.included_tags.append(tag)
	update_selected_tags_list()
	update_all_tags_list()
	GlobalData.notify_tags_changed()

func _on_tag_item_remove(tag):
	GlobalData.excluded_tags.append(tag)
	update_selected_tags_list()
	update_all_tags_list()
	GlobalData.notify_tags_changed()

func _on_tag_item_x(tag):
	for included_tag in GlobalData.included_tags:
		if included_tag["id"] == tag["id"]:
			GlobalData.included_tags.erase(included_tag)
	for excluded_tag in GlobalData.excluded_tags:
		if excluded_tag["id"] == tag["id"]:
			GlobalData.excluded_tags.erase(excluded_tag)
	update_selected_tags_list()
	update_all_tags_list()
	GlobalData.notify_tags_changed()

func _on_filter_text_submitted(new_text):
	var remove = new_text.begins_with("-")
	
	var tag
	for item in all_tags_list.get_children():
		if item.selected:
			tag = item.tag
	
	if tag == null:
		return
	
	if remove:
		_on_tag_item_remove(tag)
	else:
		_on_tag_item_add(tag)
	
	selection_offset = 0
	input_box.text = ""
	update_all_tags_list()

func _on_db_tags_changed():
	rebuild_tag_lists()
