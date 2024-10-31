extends Window

var media : DBMedia : set=set_media

@onready var message = $MarginContainer/VBoxContainer/MessageLabel

func set_media(media_in : DBMedia) -> void:
	media = media_in
	message.text = "Delete %s?" % media.path

func _on_cancel_button_pressed():
	hide()

func _on_ok_button_pressed():
	var dir = DirAccess.open(DB.db_path.get_base_dir())
	dir.remove(media.thumb_path) # thumbnail
	dir.remove(media.path) # image
	DB.delete_image(media.id)
	CacheManager.image_mutex.lock()
	CacheManager.image_cache.erase(media.id) # Does not fail if entry does not exists. Just returns false.
	CacheManager.image_mutex.unlock()
	CacheManager.thumb_mutex.lock()
	CacheManager.thumb_cache.erase(media.id)
	CacheManager.thumb_mutex.unlock()
	GlobalData.notify_media_deleted(media.id)
	hide()

func _on_close_requested():
	hide()
