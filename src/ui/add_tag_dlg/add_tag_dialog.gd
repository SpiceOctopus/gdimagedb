extends Window

var tags

@onready var new_tag_input = $MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer/NewTagInput
@onready var add_tag_button = $MarginContainer/VBoxContainer/AddTagButton
@onready var similar_tags_list = $MarginContainer/VBoxContainer/SimilarTagsList
@onready var input = $MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer/NewTagInput

func _on_AddTagButton_pressed():
	if new_tag_input.text != "":
		if not DB.is_tag_in_db(new_tag_input.text):
			DB.add_tag_to_db(new_tag_input.text)
			tags = DB.get_all_tags()
			_on_NewTagInput_text_changed(new_tag_input.text) # make newly added tag show up in similar list
			new_tag_input.text = ""
			add_tag_button.disabled = true
			GlobalData.notify_db_tags_changed()
	else:
		add_tag_button.disabled = true

func _on_NewTagInput_text_changed(new_text):
	add_tag_button.disabled = (new_text == "")
	similar_tags_list.clear()
	
	for tag in tags:
		if tag["tag"].similarity(new_tag_input.text) > 0.27:
			similar_tags_list.add_item(tag["tag"])
		if tag["tag"] == new_tag_input.text:
			add_tag_button.disabled = true

func _on_new_tag_input_text_submitted(_new_text):
	_on_AddTagButton_pressed()

func _on_about_to_popup():
	tags = DB.get_all_tags()
	input.text = ""
	input.grab_focus()

func _on_close_requested():
	hide()
