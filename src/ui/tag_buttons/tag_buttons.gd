extends Control

@onready var add_tag_dlg = $AddTagDialog
@onready var delete_tag_dlg = $DeleteTagDialog

func _on_add_tag_button_pressed():
	add_tag_dlg.popup_centered()

func _on_delete_tag_button_pressed():
	delete_tag_dlg.popup_centered()