extends FileDialog

var media

func _on_about_to_popup():
	current_file = media["path"].get_file()

func _on_confirmed():
	var dir = DirAccess.open(current_dir)
	dir.copy(DB.db_path_to_full_path(media["path"]), current_path)
