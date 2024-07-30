extends Control

var image : set = set_image

func set_image(img):
	image = img
	$MarginContainer/VBoxContainer/IDContainer/IDValue.text = str(image["id"])
	$MarginContainer/VBoxContainer/PathContainer/PathValue.text = DB.db_path_to_full_path(image["path"])

func _on_id_copy_pressed():
	DisplayServer.clipboard_set(str(image["id"]))

func _on_path_copy_pressed():
	DisplayServer.clipboard_set($MarginContainer/VBoxContainer/PathContainer/PathValue.text)

func _on_regenerate_thumb_button_pressed():
	ImportUtil.create_thumbnail(OS.get_executable_path().get_base_dir() + "/content/" + image["path"])
