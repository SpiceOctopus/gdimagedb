extends Node

signal thumb_cache_loading_complete

var thumb_mutex : Mutex = Mutex.new()
var image_mutex : Mutex = Mutex.new()

var all_media : Array[DBMedia] = []

var thumb_cache : Dictionary = {}
var image_cache : Dictionary = {}

var thumb_cache_loaded : bool = false
var thumb_cache_loader_id : int = -1
var thumb_cache_wait_id : int = -1

func _ready() -> void:
	thumb_cache_loading_complete.connect(merge_wait_thread)
	all_media = DB.get_all_media()
	thumb_cache_loader_id = WorkerThreadPool.add_group_task(async_preload, all_media.size())
	thumb_cache_wait_id = WorkerThreadPool.add_task(await_thumb_cache_load)

func add_thumbnail(id : int, texture) -> void:
	thumb_mutex.lock()
	thumb_cache[id] = texture
	thumb_mutex.unlock()

func clear_thumb_cache() -> void:
	thumb_mutex.lock()
	thumb_cache.clear()
	thumb_mutex.unlock()

func async_preload(i) -> void:
	var dir : DirAccess = DirAccess.open(OS.get_executable_path().get_base_dir())
	if dir.file_exists(all_media[i].thumb_path):
		var tmp = ImageUtil.TextureFromFile(all_media[i].thumb_path)
		thumb_mutex.lock()
		thumb_cache[all_media[i].id] = tmp
		thumb_mutex.unlock()

func await_thumb_cache_load() -> void:
	while not thumb_cache_loaded:
		await get_tree().create_timer(0.25).timeout
		if WorkerThreadPool.get_group_processed_element_count(thumb_cache_loader_id) >= all_media.size():
			thumb_cache_loaded = true
			WorkerThreadPool.wait_for_group_task_completion(thumb_cache_loader_id)
			thumb_cache_loading_complete.emit()

func merge_wait_thread() -> void:
	WorkerThreadPool.wait_for_task_completion(thumb_cache_wait_id)

func reload_thumbcache() -> void:
	all_media = DB.get_all_media()
	thumb_cache_loader_id = WorkerThreadPool.add_group_task(async_preload, all_media.size())
	WorkerThreadPool.wait_for_group_task_completion(thumb_cache_loader_id)

# returns array of media that had its thumbnails loaded
func load_missing_thumbnails() -> Array[DBMedia]:
	var dir : DirAccess = DirAccess.open(OS.get_executable_path().get_base_dir())
	var retval : Array[DBMedia] = []
	for media in DB.get_all_media():
		if media.id not in thumb_cache.keys():
			if dir.file_exists(media.thumb_path):
				var tmp = ImageUtil.TextureFromFile(media.thumb_path)
				thumb_mutex.lock()
				thumb_cache[media.id] = tmp
				thumb_mutex.unlock()
				retval.append(media)
	return retval
