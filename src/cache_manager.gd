extends Node

var thumb_mutex = Mutex.new()
var image_mutex = Mutex.new()

var thumb_cache = {}
var image_cache = {}

func add_thumbnail(id, texture):
	thumb_mutex.lock()
	thumb_cache[id] = texture
	thumb_mutex.unlock()
