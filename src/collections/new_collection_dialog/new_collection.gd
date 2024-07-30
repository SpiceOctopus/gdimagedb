extends Control

signal create_new

@onready var txt_name = $MarginContainer/VBoxContainer/NameEdit
@onready var btn_accept = $MarginContainer/VBoxContainer/AcceptButton

func _on_btn_accept_pressed():
	if !txt_name.text.is_empty():
		DB.create_new_collection(txt_name.text)
		emit_signal("create_new")

func _on_txt_name_text_changed(new_text):
	btn_accept.disabled = new_text.is_empty()

func _on_txt_name_text_submitted(_new_text):
	_on_btn_accept_pressed()
