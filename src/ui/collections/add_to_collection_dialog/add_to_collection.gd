extends Window

var all_collections : Array[DBCollection]
var image_id : int:
	set(val):
		image_id = val
		all_collections = DB.get_all_collections()
		rebuild_list()
		edit_filter.grab_focus()

@onready var collections_list = $MarginContainer/VBoxContainer/CollectionsList
@onready var edit_filter = $MarginContainer/VBoxContainer/FilterEdit
@onready var btn_add = $MarginContainer/VBoxContainer/AddButton

func _on_btn_add_pressed() -> void:
	var collection : DBCollection = DB.get_collection_by_name(collections_list.get_item_text(collections_list.get_selected_items()[0]))
	if !DB.is_image_in_collection(image_id, collection.id):
		DB.add_image_to_collection(collection.id, image_id)
		GlobalData.last_used_collection = collection
		GlobalData.notify_db_collections_changed()
		hide()
	else:
		$AlreadyInCollectionError.popup_centered()

func _on_edit_filter_text_changed(_new_text : String) -> void:
	rebuild_list()

func rebuild_list() -> void:
	collections_list.clear()
	
	var counter : int = 0
	if edit_filter.text.is_empty():
		for collection : DBCollection in all_collections:
			collections_list.add_item(collection.name)
			counter += 1
	else:
		for collection : DBCollection in all_collections:
			if edit_filter.text.to_lower() in collection.name.to_lower():
				collections_list.add_item(collection.name)
				counter += 1
	
	if counter > 0:
		collections_list.select(0)
	
	btn_add.disabled = (counter <= 0)

func _on_close_requested() -> void:
	hide()
