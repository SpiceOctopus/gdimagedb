extends PopupMenu

signal favorite_changed
signal tag_edit
signal properties
signal add_to_collection
signal export(image)
signal replace_file
signal delete(image)

var image = null : set = _set_image
var last_used_collection

func _ready():
	GlobalData.connect("last_used_collection_changed", update_last_used_collection)

func update_last_used_collection(collection):
	set_item_disabled(get_item_index(7), collection == null) # 7 = add item to last collection
	last_used_collection = collection
	set_item_text(get_item_index(7), "Add to " + collection["collection"])

# Use ID instead of text comparison.
# It's translation save and get_text() is confusing since it uses order instead of ID.
func _on_PopupMenu_id_pressed(id):
	if id == 5: # delete
		delete.emit(image)
	elif id == 2: # edit tags
		tag_edit.emit(DB.get_image(image["id"]))
	elif id == 0: # favorite
		self.set_item_checked(0, !self.is_item_checked(0))
		DB.set_fav(image["id"], int(self.is_item_checked(0)))
		favorite_changed.emit(image["id"], int(self.is_item_checked(0)))
	elif id == 3: # properties
		properties.emit(image)
	elif id == 6: # add to collection
		add_to_collection.emit(DB.get_image(image["id"]))
	elif id == 7: # add to last used collection
		var collection = DB.get_collection_by_name(last_used_collection["collection"])[0]
		if !DB.is_image_in_collection(image["id"], collection["id"]):
			DB.add_image_to_collection(collection["id"], image["id"])
			GlobalData.notify_tags_changed() # not technically correct but will cause the grid to refresh
			GlobalData.notify_db_collections_changed()
	elif id == 8: # replace file
		replace_file.emit(image)
	elif id == 9: # export
		export.emit(image)

func _set_image(img):
	image = img
	self.set_item_checked(0, bool(image["fav"]))
