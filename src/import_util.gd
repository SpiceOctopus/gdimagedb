extends Node

func import_image(imagePath: String) -> Error:
	if !imagePath.get_extension() in (Settings.supported_image_files + Settings.supported_video_files):
		return ERR_FILE_UNRECOGNIZED
	
	var file_hash = FileAccess.get_sha256(imagePath)
	if DB.is_hash_in_db(file_hash):
		return ERR_ALREADY_EXISTS

	var imageFolder : String = OS.get_executable_path().get_base_dir() + "/content"
	var folderCountStr : String = str(count_sub_directories(imageFolder))
	var currentImageFolder : String = imageFolder + "/" + folderCountStr

	# create new subfolder as needed
	var files : DirAccess = DirAccess.open(currentImageFolder)
	if files.get_files().size() >= 2048:
		var newSubDir : DirAccess = DirAccess.open(imageFolder)
		newSubDir.make_dir(imageFolder + "/" + str(count_sub_directories(imageFolder) + 1))

	# update target folder
	currentImageFolder = imageFolder + "/" + folderCountStr

	var targetFileName = UUID.v4() + "." + imagePath.get_extension()
	var targetPath = currentImageFolder + "/" + targetFileName
	var dir = DirAccess.open(OS.get_executable_path().get_base_dir())
	
	dir.copy(imagePath, targetPath)
	create_thumbnail(targetPath)
	
	var query_format = "INSERT INTO images (path, date, hash) VALUES ('%s', '%s', '%s')"
	DB.query(query_format % [folderCountStr + "/" + targetFileName, "%s" % Time.get_datetime_dict_from_system(), file_hash])
	return OK

func replace_file(db_file_to_replace : DBMedia, replacement_path : String) -> Error:
	if !replacement_path.get_extension() in (Settings.supported_image_files + Settings.supported_video_files):
		return ERR_FILE_UNRECOGNIZED
	
	var file_hash = FileAccess.get_sha256(replacement_path)
	if DB.is_hash_in_db(file_hash):
		return ERR_ALREADY_EXISTS

	var target_path : String = db_file_to_replace.path
	var dir : DirAccess = DirAccess.open(OS.get_executable_path().get_base_dir())
	dir.remove(target_path) # remove original file
	target_path = target_path.rsplit(".", false, 1)[0] + "." + replacement_path.get_extension()
	dir.copy(replacement_path, target_path)
	create_thumbnail(target_path)
	
	var db_path_new = db_file_to_replace.relative_path.split(".")[0]
	db_path_new = db_path_new + "." + target_path.get_extension()
	
	var query = "UPDATE images SET path=?, date=?, hash=? WHERE ID=?"
	DB.query_with_bindings(query, [db_path_new, "%s" % Time.get_datetime_dict_from_system(), file_hash, db_file_to_replace["id"]])
	return OK

func count_sub_directories(folder: String) -> int:
	var dir = DirAccess.open(folder)
	return dir.get_directories().size()

func create_thumbnail(path: String) -> void:
	if path.get_extension() == "gif":
		var frames : SpriteFrames = GifManager.sprite_frames_from_file(path)
		var image : Image = frames.get_frame_texture("gif", 0).get_image()
		resize_thumbnail(image)
		image.save_png(path.replace("." + path.get_extension(), "_thumb." + path.get_extension()).replace(path.get_extension(),"png"))
	elif path.get_extension() in Settings.supported_image_files:
		var pic : Image = Image.new()
		if pic.load(path) != OK:
			return # there is no error handling for this right now, todo: add error handling
		var image = ImageTexture.create_from_image(pic).get_image()
		resize_thumbnail(image)
		image.save_png(path.replace("." + path.get_extension(), "_thumb." + path.get_extension()).replace(path.get_extension(),"png"))
	elif path.get_extension() in Settings.supported_video_files:
		var player = VideoStreamPlayer.new()
		player.volume = 0.0
		player.stream = load(path)
		add_child(player)
		# skipping / setting position in video is currently not supported
		player.play() 
		await get_tree().create_timer(1).timeout
		var texture = player.get_video_texture().get_image()
		if texture != null:
			resize_thumbnail(texture)
			texture.save_png(path.replace("." + path.get_extension(), "_thumb." + path.get_extension()).replace(path.get_extension(),"png"))
		player.stop()
		player.queue_free()

func resize_thumbnail(image : Image) -> void:
	var sizeX : int = image.get_size().x
	var sizeY : int = image.get_size().y
	
	if sizeX > sizeY:
		var factor : float = sizeX / 150.0
		sizeY = int(float(sizeY) / factor)
		sizeX = 150
	else:
		var factor : float = sizeY / 150.0
		sizeX = int(float(sizeX) / factor)
		sizeY = 150
	
	image.resize(sizeX, sizeY)
