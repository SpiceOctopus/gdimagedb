extends Node

var thumb_mutex : Mutex = Mutex.new()
var image_mutex : Mutex = Mutex.new()

var thumb_cache : Dictionary = {}
var image_cache : Dictionary = {}

func add_thumbnail(id : int, texture) -> void:
	if not is_instance_valid(self):
		print("ded")
	thumb_mutex.lock()
	thumb_cache[id] = texture
	thumb_mutex.unlock()

func clear_thumb_cache() -> void:
	if not is_instance_valid(self):
		print("ded")
	thumb_mutex.lock()
	thumb_cache.clear()
	thumb_mutex.unlock()
