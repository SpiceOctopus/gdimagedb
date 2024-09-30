extends Control

enum MODE {Grid, TagEditor, CollectionEditor}

@export var mode : MODE = MODE.Grid
@export var show_add_delete_buttons : bool = false

var tag_item_instance = load("res://ui/side_bar/tag_item.tscn").instantiate()

var selection_offset : int = 0
var visible_tags_count : int = 0
var last_filter : String = ""
var all_tags
var media_id : set=set_media_id
var assigned_tags : Array = []

@onready var input_box = $MarginContainer/VBoxContainer/Filter
@onready var selected_tags_list = $MarginContainer/VBoxContainer/Panel2/ScrollContainer2/SelectedTags
@onready var tag_preview_list = $MarginContainer/TagPreviewList
@onready var all_tags_list = $MarginContainer/VBoxContainer/Panel/ScrollContainer/AllTags
@onready var tag_buttons = $MarginContainer/VBoxContainer/TagButtons

func _ready():
	rebuild_tag_lists()
	GlobalData.connect("display_mode_changed", _on_display_changed)
	GlobalData.connect("db_tags_changed", _on_db_tags_changed)
	tag_buttons.visible = show_add_delete_buttons

func rebuild_tag_lists():
	all_tags = DB.get_all_tags()
	
	for item in all_tags_list.get_children():
		item.queue_free()
	
	for item in selected_tags_list.get_children():
		item.queue_free()

	WorkerThreadPool.add_task(async_build_tag_items_all)
	WorkerThreadPool.add_task(async_build_tag_items_selected)

func async_build_tag_items_all():
	for tag in all_tags:
		var item = tag_item_instance.duplicate()
		item.tag = tag
		item.connect("add", _on_tag_item_add)
		item.connect("remove", _on_tag_item_remove)
		if mode == MODE.TagEditor || mode == MODE.CollectionEditor:
			item.add_visible = true
			item.remove_visible = false
			item.x_visible = false
			item.color_mode = false
		if mode == MODE.Grid:
			item.visible = !(item.tag in GlobalData.included_tags || item.tag in GlobalData.excluded_tags)
		elif mode == MODE.TagEditor || mode == MODE.CollectionEditor:
			item.visible = !item.tag in assigned_tags
		
		if is_instance_valid(all_tags_list):
			all_tags_list.call_deferred("add_child", item)

func async_build_tag_items_selected():
	for tag in all_tags:
		var item = tag_item_instance.duplicate()
		item.tag = tag
		item.connect("x", _on_tag_item_x)
		item.add_visible = false
		item.remove_visible = false
		item.x_visible = true
		if mode == MODE.Grid:
			item.visible = (item.tag in GlobalData.included_tags || item.tag in GlobalData.excluded_tags)
		elif mode == MODE.TagEditor || mode == MODE.CollectionEditor:
			item.color_mode = false
			item.visible = item.tag in assigned_tags
		
		if is_instance_valid(selected_tags_list):
			selected_tags_list.call_deferred("add_child", item)

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
		if mode == MODE.Grid:
			item.visible = !(item.tag in GlobalData.included_tags || item.tag in GlobalData.excluded_tags)
		elif mode == MODE.TagEditor || mode == MODE.CollectionEditor:
			item.visible = !item.tag in assigned_tags
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
		if mode == MODE.Grid:
			item.visible = (item.tag in GlobalData.included_tags || item.tag in GlobalData.excluded_tags)
		elif mode == MODE.TagEditor || mode == MODE.CollectionEditor:
			item.visible = item.tag in assigned_tags

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
	if mode == MODE.Grid:
		GlobalData.included_tags.append(tag)
	elif mode == MODE.TagEditor:
		DB.add_tag_to_image(tag["id"], media_id)
		assigned_tags = DB.get_tags_for_image(media_id)
	elif mode == MODE.CollectionEditor:
		DB.add_tag_to_collection(tag["id"], media_id)
		assigned_tags = DB.get_tags_for_collection(media_id)
	update_selected_tags_list()
	update_all_tags_list()
	if mode == MODE.Grid:
		GlobalData.notify_tags_changed()

func _on_tag_item_remove(tag):
	GlobalData.excluded_tags.append(tag)
	update_selected_tags_list()
	update_all_tags_list()
	GlobalData.notify_tags_changed()

func _on_tag_item_x(tag):
	if mode == MODE.Grid:
		for included_tag in GlobalData.included_tags:
			if included_tag["id"] == tag["id"]:
				GlobalData.included_tags.erase(included_tag)
		for excluded_tag in GlobalData.excluded_tags:
			if excluded_tag["id"] == tag["id"]:
				GlobalData.excluded_tags.erase(excluded_tag)
	elif mode == MODE.TagEditor:
		DB.remove_tag_from_image(tag["id"], media_id)
		assigned_tags = DB.get_tags_for_image(media_id)
	elif mode == MODE.CollectionEditor:
		DB.remove_tag_from_collection(tag["id"], media_id)
		assigned_tags = DB.get_tags_for_collection(media_id)
	update_selected_tags_list()
	update_all_tags_list()
	if mode == MODE.Grid:
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

func focus():
	input_box.grab_focus()

func set_media_id(id):
	media_id = id
	if mode == MODE.Grid || mode == MODE.TagEditor:
		assigned_tags = DB.get_tags_for_image(id)
	else:
		assigned_tags = DB.get_tags_for_collection(id)
