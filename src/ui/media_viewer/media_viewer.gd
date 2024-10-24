extends Control

signal closing

enum MODE {Picture, Video, gif}

@export var hotkeys_active: bool = true
@export var loop_video: bool = true
@export var zoom_factor: float = 0.1

var images 
var current_image : int = 0
var current_mode = MODE.Picture
var video_size
var video_playing : bool = false
var dragging : bool = false
var drag_offset
var zoom_min_size : Vector2 = Vector2(10, 10)
var zoom_min_scale : Vector2 = Vector2(0.05, 0.05)
var preload_next_id : int = -1
var preload_previous_id : int = -1

@onready var input_workaround = $VBoxContainer/InputWorkaround
@onready var top_menu = $VBoxContainer/MediaViewerTopMenu
@onready var video_player_controls = $VideoPlayerControls
@onready var video_time_update_timer = $VideoTimeUpdate
@onready var gif_display = $GIFDisplay
@onready var loading_label = $LoadingLabel

func _ready():
	if images != null && images.size() > 0:
		set_display(images[current_image])
		if images.size() > 1:
			var preload_id = current_image + 1
			if preload_id > images.size() - 1:
				preload_id = 0
			if !CacheManager.image_cache.has(images[preload_id]["id"]) && (get_mode_for_file(images[preload_id]["path"]) == MODE.Picture):
				preload_next_id = WorkerThreadPool.add_task(Callable(self, "preload_image").bind(images[preload_id]))
		if images.size() > 2:
			var preload_id = current_image - 1
			if preload_id < 0:
				preload_id = images.size() - 1
			if !CacheManager.image_cache.has(images[preload_id]["id"]) && (get_mode_for_file(images[preload_id]["path"]) == MODE.Picture):
				preload_previous_id = WorkerThreadPool.add_task(Callable(self, "preload_image").bind(images[preload_id]))

func _input(event):
	if !hotkeys_active:
		return
	
	if Input.is_action_just_pressed("ui_right"):
		set_next_image()
	elif Input.is_action_just_pressed("ui_left"):
		set_previous_image()
	elif Input.is_action_pressed("ui_cancel"):
		closing.emit()
		queue_free()
	elif Input.is_action_pressed("video_play_pause"):
		if current_mode == MODE.Video && $VideoStreamPlayer.is_playing():
			$VideoStreamPlayer.paused = !$VideoStreamPlayer.paused
			if $VideoStreamPlayer.paused:
				video_time_update_timer.stop()
			else:
				video_time_update_timer.start()
		elif current_mode == MODE.Video && !$VideoStreamPlayer.is_playing():
			$VideoStreamPlayer.play()
			video_time_update_timer.start()
	elif Input.is_action_just_released("menu_bar_toggle"):
		top_menu.visible = !top_menu.visible
	elif Input.is_action_pressed("scroll_up"):
		if current_mode == MODE.Picture:
			var offset = $ImageDisplay.position - get_global_mouse_position()
			$ImageDisplay.position = $ImageDisplay.position + (offset * zoom_factor)
			$ImageDisplay.size = $ImageDisplay.size * (1 + zoom_factor)
		elif current_mode == MODE.gif:
			var offset = gif_display.position - get_global_mouse_position()
			gif_display.position = gif_display.position + (offset * zoom_factor)
			gif_display.scale = gif_display.scale * (1 + zoom_factor)
	elif Input.is_action_pressed("scroll_down"):
		if current_mode == MODE.Picture:
			var offset = $ImageDisplay.position - get_global_mouse_position()
			$ImageDisplay.position = $ImageDisplay.position - (offset * zoom_factor)
			$ImageDisplay.size = $ImageDisplay.size * (1 - zoom_factor)
			if $ImageDisplay.size < zoom_min_size:
				$ImageDisplay.size = zoom_min_size
		elif current_mode == MODE.gif:
			var offset = gif_display.position - get_global_mouse_position()
			gif_display.position = gif_display.position - (offset * zoom_factor)
			gif_display.scale = gif_display.scale * (1 - zoom_factor)
			if gif_display.scale < zoom_min_scale:
				gif_display.scale = zoom_min_scale
	
	if event is InputEventMouseButton and (event.button_index == MOUSE_BUTTON_LEFT):
		if not dragging and event.pressed and input_workaround.get_rect().has_point(event.position):
			dragging = true
			if current_mode == MODE.Picture:
				drag_offset = $ImageDisplay.position - get_global_mouse_position()
			elif current_mode == MODE.gif:
				drag_offset = gif_display.position - get_global_mouse_position()
		if dragging and not event.pressed:
			dragging = false

func _process(_delta):
	if dragging:
		if current_mode == MODE.Picture:
			$ImageDisplay.position = get_global_mouse_position() + drag_offset
		elif current_mode == MODE.gif:
			gif_display.position = get_global_mouse_position() + drag_offset

func _on_video_timer_tick():
	video_player_controls.set_time_current($VideoStreamPlayer.stream_position)

func set_next_image():
	if preload_next_id > 0:
		WorkerThreadPool.wait_for_task_completion(preload_next_id)
		preload_next_id = -1
		
	current_image += 1
	if current_image > images.size() - 1:
		current_image = 0
	set_display(images[current_image])
	
	var preload_id = current_image + 1
	if preload_id > images.size() - 1:
		preload_id = 0
	if !CacheManager.image_cache.has(images[preload_id]["id"]) && (get_mode_for_file(images[preload_id]["path"]) == MODE.Picture):
		preload_next_id = WorkerThreadPool.add_task(Callable(self, "preload_image").bind(images[preload_id]))

func set_previous_image():
	if preload_previous_id > 0:
		WorkerThreadPool.wait_for_task_completion(preload_previous_id)
		preload_previous_id = -1
		
	if current_image == 0:
		current_image = images.size() - 1
	else:
		current_image -= 1
	set_display(images[current_image])
	
	var preload_id = current_image - 1
	if preload_id < 0:
		preload_id = images.size() - 1
	if !CacheManager.image_cache.has(images[preload_id]["id"]) && (get_mode_for_file(images[preload_id]["path"]) == MODE.Picture):
		preload_next_id = WorkerThreadPool.add_task(Callable(self, "preload_image").bind(images[preload_id]))

func set_video_display_rect():
	if !current_mode == MODE.Video:
		return
	
	if video_size.x <= size.x && video_size.y <= size.y: # center, no stretch
		$VideoStreamPlayer.expand = false
		$VideoStreamPlayer.size = video_size
		$VideoStreamPlayer.position.x = (size.x / 2) - (video_size.x / 2)
		$VideoStreamPlayer.position.y = (size.y / 2) - (video_size.y / 2)
	else: # center, stretch, keep aspect ratio
		$VideoStreamPlayer.expand = true
		if video_size.x > video_size.y: # wide screen
			var ratio = video_size.x / video_size.y
			$VideoStreamPlayer.position = Vector2(0, (size.y / 2) - ((size.x / ratio) / 2))
			$VideoStreamPlayer.size = Vector2(size.x, size.x / ratio)
			fit_oversized_display_into_window($VideoStreamPlayer, ratio)
		else: # portrait
			var ratio = video_size.y / video_size.x
			$VideoStreamPlayer.size = Vector2(size.y / ratio, size.y)
			$VideoStreamPlayer.position = Vector2((size.x / 2) - ($VideoStreamPlayer.size.x / 2), 0)
			fit_oversized_display_into_window($VideoStreamPlayer, ratio)

func set_image_display_rect():
	if !current_mode == MODE.Picture:
		return
	if !$ImageDisplay.texture: # null check since the function can be called when the window opens with no image set
		return
	
	var image_size = $ImageDisplay.texture.get_size()
	
	if (image_size.x <= size.x && image_size.y <= size.y && (DB.get_setting_media_viewer_stretch_mode() != 1)) || (DB.get_setting_media_viewer_stretch_mode() == 2): # center, no stretch
		$ImageDisplay.size = image_size
		$ImageDisplay.position.x = (size.x / 2) - (image_size.x / 2)
		$ImageDisplay.position.y = (size.y / 2) - (image_size.y / 2)
	else: # center, stretch, keep aspect ratio
		if image_size.x > image_size.y: # wide screen
			var ratio = image_size.x / image_size.y
			$ImageDisplay.position = Vector2(0, (size.y / 2) - ((size.x / ratio) / 2))
			$ImageDisplay.size = Vector2(size.x, size.x / ratio)
			fit_oversized_display_into_window($ImageDisplay, ratio)
		else: # portrait
			var ratio = image_size.y / image_size.x
			$ImageDisplay.size = Vector2(size.y / ratio, size.y)
			$ImageDisplay.position = Vector2((size.x / 2) - ($ImageDisplay.size.x / 2), 0)
			fit_oversized_display_into_window($ImageDisplay, ratio)

func set_gif_display_rect():
	if current_mode != MODE.gif:
		return
	
	# positioning
	gif_display.position = size / 2 # center is always correct for a node2d
	
	# scaling
	var gif_size : Vector2 = gif_display.sprite_frames.get_frame_texture("gif", 0).get_size()
	if gif_size.x > size.x || gif_size.y > size.y: #needs scaling
		var scale_factor_y = (gif_size.y - size.y) / gif_size.y
		var scale_factor_x = (gif_size.x - size.x) / gif_size.x
		if scale_factor_x > scale_factor_y:
			gif_display.scale = Vector2(1 - scale_factor_x, 1 - scale_factor_x)
		else:
			gif_display.scale = Vector2(1 - scale_factor_y, 1 - scale_factor_y)
	else:
		gif_display.scale = Vector2(1, 1)

func set_display(file):
	video_time_update_timer.stop()
	current_mode = get_mode_for_file(file["path"])
	set_mode(current_mode)
	
	if current_mode == MODE.Picture:
		$ImageDisplay.hide()
		loading_label.show()
		WorkerThreadPool.add_task(Callable(self, "async_load_display").bind(file))
	elif current_mode == MODE.Video:
		loading_label.show()
		$VideoStreamPlayer.stream = null # Solves a hard crash.
		$VideoStreamPlayer.stream = load(DB.db_path_to_full_path(file["path"]))
		video_player_controls.set_time_total($VideoStreamPlayer.get_stream_length())
		video_player_controls.set_time_current(0)
		$VideoStreamPlayer.play()
		video_time_update_timer.start()
		video_playing = true
		video_size = Vector2($VideoStreamPlayer.get_video_texture().get_width(), $VideoStreamPlayer.get_video_texture().get_height())
		loading_label.hide()
		_on_MediaViewer_resized()
	elif current_mode == MODE.gif:
		loading_label.show()
		gif_display.sprite_frames = GifManager.sprite_frames_from_file(DB.db_path_to_full_path(file["path"]))
		loading_label.hide()
		gif_display.play("gif")
		_on_MediaViewer_resized()

func async_load_display(file):
	if CacheManager.image_cache.has(file["id"]):
			call_deferred("set_image_internal", CacheManager.image_cache[file["id"]])
	else:
		var texture = ImageUtil.TextureFromFile(DB.db_path_to_full_path(file["path"]))
		call_deferred("set_image_internal", texture)
		CacheManager.image_mutex.lock()
		CacheManager.image_cache[file["id"]] = texture
		CacheManager.image_mutex.unlock()

func preload_image(file):
	var texture = ImageUtil.TextureFromFile(DB.db_path_to_full_path(file["path"]))
	CacheManager.image_mutex.lock()
	CacheManager.image_cache[file["id"]] = texture
	CacheManager.image_mutex.unlock()

func set_image_internal(img):
	loading_label.hide()
	$ImageDisplay.texture = img
	$ImageDisplay.show()
	_on_MediaViewer_resized()

func set_mode(mode):
	if mode == MODE.Picture:
		$ImageDisplay.show()
		$VideoStreamPlayer.hide()
		$VideoStreamPlayer.stop()
		video_player_controls.hide()
		gif_display.hide()
		video_playing = false
	elif mode == MODE.Video:
		$VideoStreamPlayer.stop()
		$ImageDisplay.hide()
		gif_display.hide()
		$VideoStreamPlayer.show()
		video_player_controls.show()
	elif mode == MODE.gif:
		$ImageDisplay.hide()
		$VideoStreamPlayer.stop()
		$VideoStreamPlayer.hide()
		video_playing = false
		video_player_controls.hide()
		gif_display.show()

func get_mode_for_file(path):
	if path.get_extension() == "gif":
		return MODE.gif
	elif path.get_extension() in Settings.supported_image_files:
		return MODE.Picture
	elif path.get_extension() in Settings.supported_video_files:
		return MODE.Video

func _on_MediaViewer_resized():
	set_image_display_rect()
	set_video_display_rect()
	set_gif_display_rect()

func _on_video_stream_player_finished():
	if loop_video:
		$VideoStreamPlayer.play()
	else:
		video_playing = false
		video_time_update_timer.stop()

func _on_video_player_controls_play_pause():
	if video_playing:
		$VideoStreamPlayer.paused = true
		video_playing = false
		video_time_update_timer.stop()
	else:
		$VideoStreamPlayer.paused = false
		video_playing = true
		video_time_update_timer.start()

func _on_media_viewer_top_menu_fit_to_window():
	if current_mode == MODE.Picture:
		var image_size = $ImageDisplay.texture.get_size()
		if image_size.x > image_size.y: #landscape
			var ratio = image_size.x / image_size.y
			$ImageDisplay.size.x = size.x
			$ImageDisplay.size.y = size.x * ratio
			$ImageDisplay.position = Vector2(0, (size.y / 2) - ($ImageDisplay.size.y / 2))
			fit_oversized_display_into_window($ImageDisplay, ratio)
		else: # portrait
			var ratio = image_size.y / image_size.x
			$ImageDisplay.size.y = size.y
			$ImageDisplay.size.x = size.y * ratio
			$ImageDisplay.position = Vector2((size.x / 2) - ($ImageDisplay.size.x / 2), 0)
			fit_oversized_display_into_window($ImageDisplay, ratio)

func fit_oversized_display_into_window(display, ratio):
	if display.size.y > size.y:
		display.position.y = 0
		display.size.y = size.y
		display.size.x = size.y * ratio
		display.position.x = (size.x / 2) - (display.size.x / 2)
	if display.size.x > size.x:
		display.position.x = 0
		display.size.x = size.x
		display.size.y = size.x * ratio
		display.position.y = (size.y / 2) - (display.size.y / 2)

func _on_media_viewer_top_menu_original_size():
	if not hotkeys_active:
		return
	
	$ImageDisplay.size = $ImageDisplay.texture.get_size()
	$ImageDisplay.position = Vector2((size.x / 2) - ($ImageDisplay.size.x / 2), (size.y / 2) - ($ImageDisplay.size.y / 2))

func _on_media_viewer_top_menu_stretch_mode_changed():
	if current_mode == MODE.Picture:
		set_image_display_rect()
	else:
		set_video_display_rect()

func _on_video_player_controls_time_selected(time):
	$VideoStreamPlayer.stream_position = time

func stop_video():
	$VideoStreamPlayer.stop()
