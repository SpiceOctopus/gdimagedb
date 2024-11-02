extends Node

var thumb_mutex : Mutex = Mutex.new()
var image_mutex : Mutex = Mutex.new()

var thumb_cache : Dictionary = {}
var image_cache : Dictionary = {}

var thumb_cache_loader_id : int = -1

var dir : DirAccess = DirAccess.open(OS.get_executable_path().get_base_dir())

func clear_thumb_cache() -> void:
	thumb_mutex.lock()
	thumb_cache.clear()
	thumb_mutex.unlock()

func get_thumbnail(media : DBMedia) -> ImageTexture:
	if media == null:
		return null
	
	if thumb_cache.has(media.id):
		return thumb_cache[media.id]
	else:
		if dir.file_exists(media.thumb_path):
			var tmp = ImageUtil.TextureFromFile(media.thumb_path)
			thumb_mutex.lock()
			thumb_cache[media.id] = tmp
			thumb_mutex.unlock()
			return tmp
		elif media.path.get_extension() in Settings.supported_video_files:
			return load("res://gfx/video_placeholder.png")
	return null
