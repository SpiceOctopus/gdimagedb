extends FileDialog

var media : DBMedia

func _on_about_to_popup() -> void:
	current_file = media.path.get_file()

func _on_confirmed() -> void:
	var dir = DirAccess.open(current_dir)
	dir.copy(media.path, current_path)
