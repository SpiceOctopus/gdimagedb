extends Window

var collections : Array

@onready var txt_name = $MarginContainer/VBoxContainer/NameEdit
@onready var btn_accept = $MarginContainer/VBoxContainer/AcceptButton
@onready var duplicate_label = $MarginContainer/VBoxContainer/HBoxContainer/duplicate_name_warning_label

func _on_btn_accept_pressed():
	if !txt_name.text.is_empty():
		DB.create_new_collection(txt_name.text)
		GlobalData.notify_db_collections_changed()
		hide()

func _on_txt_name_text_changed(new_text):
	btn_accept.disabled = new_text.is_empty() || collections.has(new_text)
	duplicate_label.visible = collections.has(new_text)

func _on_txt_name_text_submitted(_new_text):
	_on_btn_accept_pressed()

func _on_close_requested():
	hide()

func _on_about_to_popup():
	collections = DB.get_all_collection_names()
	txt_name.text = ""
	btn_accept.disabled = true
