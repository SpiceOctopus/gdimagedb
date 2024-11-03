extends Window

var media : DBMedia :
	set(media_in):
		media = media_in
		$MarginContainer/VBoxContainer/IDContainer/IDValue.text = str(media.id)
		path_value.text = media.path

@onready var path_value = $MarginContainer/VBoxContainer/PathContainer/PathValue

func _on_id_copy_pressed() -> void:
	DisplayServer.clipboard_set(str(media.id))

func _on_path_copy_pressed() -> void:
	DisplayServer.clipboard_set(path_value.text)

func _on_regenerate_thumb_button_pressed() -> void:
	ImportUtil.create_thumbnail(media.path)

func _on_close_requested() -> void:
	hide()
