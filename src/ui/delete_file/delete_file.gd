extends Window

var media : DBMedia : 
	set(media_in):
		media = media_in
		message.text = "Delete %s?" % media.path

@onready var message = $MarginContainer/VBoxContainer/MessageLabel

func _on_cancel_button_pressed() -> void:
	hide()

func _on_ok_button_pressed() -> void:
	var dir : DirAccess = DirAccess.open(DB.db_path.get_base_dir())
	dir.remove(media.thumb_path) # thumbnail
	dir.remove(media.path) # image
	DB.delete_image(media.id)
	CacheManager.remove_image(media.id)
	CacheManager.remove_thumbnail(media.id)
	GlobalData.notify_media_deleted(media.id)
	hide()

func _on_close_requested() -> void:
	hide()
