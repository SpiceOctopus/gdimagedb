extends Window

var image : set=set_image

@onready var message = $MarginContainer/VBoxContainer/MessageLabel

func set_image(img):
	message.text = "Delete %s?" % img["path"]
	image = img

func _on_cancel_button_pressed():
	hide()

func _on_ok_button_pressed():
	var dir = DirAccess.open(DB.db_path.get_base_dir())
	dir.remove(DB.db_path_to_full_thumb_path(image["path"])) # thumbnail
	dir.remove(DB.db_path_to_full_path(image["path"])) # image
	DB.delete_image(image["id"])
	CacheManager.image_mutex.lock()
	CacheManager.image_cache.erase(image["id"]) # Does not fail if entry does not exists. Just returns false.
	CacheManager.image_mutex.unlock()
	CacheManager.thumb_mutex.lock()
	CacheManager.thumb_cache.erase(image["id"])
	CacheManager.thumb_mutex.unlock()
	GlobalData.notify_media_deleted(image["id"])
	GlobalData.notify_db_images_changed()
	hide()

func _on_close_requested():
	hide()
