extends PopupMenu

signal edit
signal delete

var collection : DBCollection :
	set(collection_in):
		collection = collection_in
		set_item_checked(0, collection.fav)

func _on_id_pressed(id : int) -> void:
	if id == 2:
		edit.emit()
	elif id == 1:
		if not collection.fav:
			DB.set_collection_favorite(collection.id, true)
			collection.fav = true
		else:
			DB.set_collection_favorite(collection.id, false)
			collection.fav = false
	elif id == 3:
		delete.emit()
