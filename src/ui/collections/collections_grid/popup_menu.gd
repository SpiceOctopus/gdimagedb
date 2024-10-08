extends PopupMenu

signal edit
signal delete

var collection : get=get_collection, set=set_collection
var collection_internal

func _on_id_pressed(id):
	if id == 0:
		edit.emit()
	elif id == 1:
		if collection["fav"] == 0:
			DB.set_collection_favorite(collection["id"], 1)
			collection["fav"] = 1
		else:
			DB.set_collection_favorite(collection["id"], 0)
			collection["fav"] = 0
	elif id == 3:
		delete.emit()

func set_collection(collection_in):
	collection_internal = collection_in
	set_item_checked(1, bool(collection["fav"]))

func get_collection():
	return collection_internal
