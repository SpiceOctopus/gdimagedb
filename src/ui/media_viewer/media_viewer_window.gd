extends Window

var media_set : Array[DBMedia] :
	set(media_set):
		$MediaViewer.media_set = media_set

var current_image : int = 0 :
	set(id):
		$MediaViewer.current_image = id

func _on_close_requested() -> void:
	queue_free()
