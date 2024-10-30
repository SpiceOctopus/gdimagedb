extends FileDialog

var media : DBMedia

func _on_about_to_popup():
	current_file = media.path.get_file()

func _on_confirmed():
	var dir = DirAccess.open(current_dir)
	dir.copy(media.path, current_path)
