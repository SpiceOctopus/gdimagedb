extends Node

var thumb_mutex : Mutex = Mutex.new()
var image_mutex : Mutex = Mutex.new()

var thumb_cache : Dictionary = {}
var image_cache : Dictionary = {}

var dir : DirAccess = DirAccess.open(OS.get_executable_path().get_base_dir())
var db_media : Array[DBMedia] = []
var load_thread_id : int = -1
var cache_preload_complete : bool = false

func _ready():
	db_media = DB.get_all_media()
	load_thread_id = WorkerThreadPool.add_group_task(loader, db_media.size())

func loader(i : int) -> void:
	var tmp = ImageTexture.create_from_image(Image.load_from_file(db_media[i].thumb_path))
	thumb_mutex.lock()
	thumb_cache[db_media[i].id] = tmp
	thumb_mutex.unlock()

func ensure_cache_preload():
	if cache_preload_complete:
		return
	WorkerThreadPool.wait_for_group_task_completion(load_thread_id)
	cache_preload_complete = true

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
			var tmp = ImageTexture.create_from_image(Image.load_from_file(media.thumb_path))
			thumb_mutex.lock()
			thumb_cache[media.id] = tmp
			thumb_mutex.unlock()
			return thumb_cache[media.id]
		elif media.path.get_extension() in Settings.supported_video_files:
			return load("res://gfx/video_placeholder.png")
	return null

func get_image(media : DBMedia) -> ImageTexture:
	if media == null:
		return null
	
	if image_cache.has(media.id):
		return image_cache[media.id]
	else:
		if dir.file_exists(media.path):
			var tmp = ImageTexture.create_from_image(Image.load_from_file(media.path))
			image_mutex.lock()
			image_cache[media.id] = tmp
			image_mutex.unlock()
			return image_cache[media.id]
		elif media.path.get_extension() in Settings.supported_video_files:
			return load("res://gfx/video_placeholder.png")
	return null

func remove_image(id : int) -> void:
	image_mutex.lock()
	image_cache.erase(id) # Does not fail if entry does not exists. Just returns false.
	image_mutex.unlock()

func remove_thumbnail(id : int) -> void:
	thumb_mutex.lock()
	thumb_cache.erase(id)
	thumb_mutex.unlock()
