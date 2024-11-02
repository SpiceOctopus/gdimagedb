extends Node

var db_path : String = OS.get_executable_path().get_base_dir() + "/main.db"
var db = SQLite.new()
var query_result
var current_db_version = 3
var db_access_mutex = Mutex.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	db.path = db_path
	if FileAccess.file_exists(db.path):
		db.open_db()
		update_database()
	else:
		create_database() # also opens the new db

func query(cmd):
	query_result = []
	var retval = db.query(cmd)
	query_result = db.query_result
	return retval

func query_with_bindings(cmd, bindings):
	query_result = []
	var retval = db.query_with_bindings(cmd, bindings)
	query_result = db.query_result
	return retval

func execute_non_query(cmd : String, bindings : Array = []) -> void:
	db_access_mutex.lock()
	if bindings.size() > 0:
		db.query_with_bindings(cmd, bindings)
	else:
		db.query(cmd)
	db_access_mutex.unlock()

func create_database():
	var dir = DirAccess.open(OS.get_executable_path().get_base_dir())
	db.path = OS.get_executable_path().get_base_dir() + "/main"
	dir.make_dir_recursive(OS.get_executable_path().get_base_dir() + "/content/1")
	db.open_db()
	query("CREATE TABLE images ( id INTEGER PRIMARY KEY, path TEXT NOT NULL UNIQUE, date TEXT NOT NULL, fav INTEGER NOT NULL DEFAULT 0, hash TEXT NOT NULL );")
	query("CREATE TABLE tags ( id INTEGER PRIMARY KEY, tag TEXT NOT NULL UNIQUE );")
	query("CREATE TABLE tags_images ( tag_id INTEGER, image_id INTEGER, PRIMARY KEY (tag_id, image_id), FOREIGN KEY (tag_id) REFERENCES tags (id), FOREIGN KEY (image_id) REFERENCES images (id));")
	query("CREATE TABLE siblings ( id INTEGER NOT NULL, sibling INTEGER NOT NULL );")
	query("CREATE TABLE metadata (version INTEGER NOT NULL);")
	query("INSERT INTO metadata (version) VALUES ('3');") # update this for db changes
	query("CREATE TABLE settings ( grid_image_size INTEGER NOT NULL, stretch_mode INTEGER NOT NULL, hide_images_collections INTEGER NOT NULL DEFAULT 0 );")
	query("INSERT INTO settings (grid_image_size, stretch_mode, hide_images_collections) VALUES ('152', 0, 0);")
	query("CREATE TABLE collections ( id INTEGER PRIMARY KEY, collection TEXT NOT NULL UNIQUE, fav INTEGER NOT NULL DEFAULT 0 );")
	query("CREATE TABLE collections_images ( collection_id INTEGER, image_id INTEGER, position INTEGER NOT NULL, PRIMARY KEY (collection_id, image_id), FOREIGN KEY (collection_id) REFERENCES collections (id), FOREIGN KEY (image_id) REFERENCES images (id) );")
	query("CREATE TABLE tags_collections ( tag_id INTEGER, collection_id INTEGER, PRIMARY KEY (tag_id, collection_id), FOREIGN KEY (tag_id) REFERENCES tags (id), FOREIGN KEY (collection_id) REFERENCES collections (id));")

func update_database():
	db_access_mutex.lock()
	# add metadata table. Some old dev dbs don't have it. Good test right now (05.06.23)
	query("SELECT name FROM sqlite_master WHERE type='table' AND name='metadata';")
	if query_result.size() == 0:
		query("CREATE TABLE metadata (version INTEGER NOT NULL);")
		query("INSERT INTO metadata (version) VALUES ('1');")
	query("SELECT name FROM sqlite_master WHERE type='table' AND name='settings';")
	if query_result.size() == 0:
		query("CREATE TABLE settings ( grid_image_size INTEGER NOT NULL );")
		query("INSERT INTO settings (grid_image_size) VALUES ('152');")
	
	# here we start the real incremental updates
	query("SELECT version FROM metadata")
	var version = query_result[0]["version"]
	
	while version < current_db_version:
		if version == 1:
			query("ALTER TABLE settings ADD stretch_mode INTEGER NOT NULL default '0'")
			query("UPDATE metadata SET version='2'")
		elif query_result[0]["version"] == 2:
			query("CREATE TABLE collections ( id INTEGER PRIMARY KEY, collection TEXT NOT NULL UNIQUE, fav INTEGER NOT NULL DEFAULT 0 );")
			query("CREATE TABLE collections_images ( collection_id INTEGER, image_id INTEGER, position INTEGER NOT NULL, PRIMARY KEY (collection_id, image_id), FOREIGN KEY (collection_id) REFERENCES collections (id), FOREIGN KEY (image_id) REFERENCES images (id) );")
			query("CREATE TABLE tags_collections ( tag_id INTEGER, collection_id INTEGER, PRIMARY KEY (tag_id, collection_id), FOREIGN KEY (tag_id) REFERENCES tags (id), FOREIGN KEY (collection_id) REFERENCES collections (id));")
			query("ALTER TABLE images DROP COLUMN position")
			query("ALTER TABLE settings ADD hide_images_collections INTEGER NOT NULL DEFAULT 0")
			query("UPDATE metadata SET version='3'")
		query("SELECT version FROM metadata")
		version = query_result[0]["version"]
	db_access_mutex.unlock()

func db_path_to_full_path(path):
	return path.insert(0, OS.get_executable_path().get_base_dir() + "/content/")

func get_all_media() -> Array[DBMedia]:
	db_access_mutex.lock()
	query("SELECT * FROM images")
	var retval : Array[DBMedia] = []
	for entry in query_result:
		var media = DBMedia.new()
		media.id = entry["id"]
		media.path = entry["path"]
		media.favorite = entry["fav"]
		retval.append(media)
	db_access_mutex.unlock()
	return retval

func get_all_tags() -> Array[DBTag]:
	db_access_mutex.lock()
	query("SELECT * FROM tags")
	
	var retval : Array[DBTag] = []
	for entry in query_result:
		var tag = DBTag.new()
		tag.id = entry["id"]
		tag.tag = entry["tag"]
		retval.append(tag)
	
	db_access_mutex.unlock()
	return retval

func get_all_tag_counts() -> Dictionary:
	db_access_mutex.lock()
	query("SELECT tag_id, count(tag_id) FROM tags_images GROUP BY tag_id")
	var counts : Dictionary = {}
	for result in query_result: # each result is a dictionary with a tag_id and count(tag_id) key value pair
		counts[result["tag_id"]] = result["count(tag_id)"]
	db_access_mutex.unlock()
	return counts

func get_tags_for_image(id : int) -> Array[DBTag]:
	db_access_mutex.lock()
	query_with_bindings("SELECT tags.id, tags.tag FROM tags_images JOIN tags ON tags_images.tag_id = tags.id WHERE image_id = ?", [id])
	
	var retval : Array[DBTag] = []
	for entry in query_result:
		var tag = DBTag.new()
		tag.id = entry["id"]
		tag.tag = entry["tag"]
		retval.append(tag)
	
	db_access_mutex.unlock()
	return retval

# tag is the tag in string form, not the id!
func is_tag_in_db(tag : String) -> bool:
	db_access_mutex.lock()
	query_with_bindings("SELECT * FROM tags WHERE tag=?", [tag])
	var retval = (query_result.size() > 0)
	db_access_mutex.unlock()
	return retval

# tag is the tag in string form, not the id!
func add_tag_to_db(tag : String) -> void:
	execute_non_query("INSERT INTO tags (tag) VALUES (?)", [tag])

func add_tag_to_image(tag_id : int, image_id : int) -> void:
	execute_non_query("INSERT INTO tags_images (tag_id, image_id) VALUES (?, ?)", [tag_id, image_id])

func remove_tag_from_image(tag_id : int, image_id : int) -> void:
	execute_non_query("DELETE FROM tags_images WHERE tag_id=? AND image_id=?", [tag_id, image_id])

func delete_image(image_id : int) -> void:
	db_access_mutex.lock()
	query_with_bindings("SELECT collection_id FROM collections_images WHERE image_id=?", [image_id])
	if query_result.size() > 0:
		for collection in query_result:
			remove_image_from_collection(image_id, collection["collection_id"])
			var images = DB.get_all_images_in_collection(collection["collection_id"])
			images.sort_custom(compare_by_position)
			var counter = 0
			for img in images:
				set_position_in_collection(img["id"], collection["collection_id"], counter)
				counter += 1
	query_with_bindings("DELETE FROM images WHERE id=?", [image_id])
	query_with_bindings("DELETE FROM tags_images WHERE image_id=?", [image_id])
	query_with_bindings("DELETE FROM collections_images WHERE image_id=?", [image_id])
	db_access_mutex.unlock()

func compare_by_position(a, b):
	return a["position"] < b["position"]

func delete_tag(id : int) -> void:
	db_access_mutex.lock()
	query_with_bindings("DELETE FROM tags WHERE id=?", [id])
	query_with_bindings("DELETE FROM tags_images WHERE tag_id=?", [id])
	query_with_bindings("DELETE FROM tags_collections WHERE tag_id=?", [id])
	db_access_mutex.unlock()

func get_tag_by_name(tag_name : String) -> DBTag:
	db_access_mutex.lock()
	query_with_bindings("SELECT * FROM tags WHERE tag=?", [tag_name])
	var tag = DBTag.new()
	tag.id = query_result[0]["id"]
	tag.tag = query_result[0]["tag"]
	db_access_mutex.unlock()
	return tag

# status = int 0 or 1
func set_fav(id : int, status : int) -> void:
	execute_non_query("UPDATE images set fav=? WHERE ID=?", [status, id])

func is_hash_in_db(file_hash : String) -> bool:
	db_access_mutex.lock()
	
	query("SELECT hash FROM images")
	
	for result in query_result:
		if result["hash"] == file_hash:
			db_access_mutex.unlock()
			return true
	
	db_access_mutex.unlock()
	return false

# currently using typed arrays as optional parameters does not seem to work? 31.10.2024
func get_images_for_tags(includedTags : Array = [], excludedTags : Array = []) -> Array[DBMedia]:
	db_access_mutex.lock()
	var result : Array[DBMedia] = []
	var ids_to_exclude : Array[int] = []
	
	if excludedTags.size() > 0:
		var cmd = "SELECT DISTINCT images.id FROM images JOIN tags_images ON tags_images.image_id = images.id JOIN tags ON tags_images.tag_id = tags.id WHERE"
		for tag in excludedTags:
			cmd += " tags.id = '%s' OR" % tag.id
		cmd = cmd.trim_suffix("OR")
		query(cmd)
		for entry : Dictionary in query_result:
			ids_to_exclude.append(entry["id"])
	
	if includedTags.size() > 0:
		var tagString : String = ""
		var tagCount : int = 0
		for tag in includedTags:
			tagString += " %s," % tag["id"]
			tagCount += 1
		tagString = tagString.trim_suffix(",") # remove the last colon
		query("SELECT * FROM images AS img JOIN tags_images AS tgimg ON tgimg.image_id = img.id AND tgimg.tag_id IN( %s ) " % tagString + "GROUP BY img.id HAVING COUNT(img.id) = %s" % tagCount)
		for media in query_result:
			if media["id"] in ids_to_exclude:
				continue
			var temp = DBMedia.new()
			temp.id = media["id"]
			temp.path = media["path"]
			temp.favorite = media["fav"]
			result.append(temp)
	else:
		for media : DBMedia in get_all_media():
			if media.id not in ids_to_exclude:
				result.append(media)
		
	db_access_mutex.unlock()
	return result

func get_collections_for_tags(includedTags : Array[DBTag], excludedTags : Array[DBTag]):
	db_access_mutex.lock()
	var result
	
	if includedTags.size() > 0:
		var tagString = ""
		var tagCount = 0
		for tag in includedTags:
			tagString += " %s," % tag.id
			tagCount += 1
		tagString = tagString.trim_suffix(",") # remove the last colon
		query("SELECT * FROM collections AS collection JOIN tags_collections AS tgcoll ON tgcoll.collection_id = collection.id AND tgcoll.tag_id IN( %s ) GROUP BY collection.id HAVING COUNT(collection.id) = %s" % [tagString, tagCount])
		result = query_result.duplicate()
	else:
		result = get_all_collections()
		
	if excludedTags.size() > 0:
		var cmd = "SELECT DISTINCT collections.id FROM collections JOIN tags_collections ON tags_collections.collection_id = collections.id JOIN tags ON tags_collections.tag_id = tags.id WHERE"
		for tag in excludedTags:
			cmd += " tags.id = '%s' OR" % tag.id
		cmd = cmd.trim_suffix("OR")
		query(cmd)
		var tmp = query_result.duplicate()
		for image in result.duplicate():
			for tmpimage in tmp:
				if image["id"] == tmpimage["id"]:
					result.erase(image)
	db_access_mutex.unlock()
	return result

# feature not implemented (03.10.2024)
func get_siblings(id):
	query("SELECT * FROM siblings WHERE id='%s' " % id + "OD sibling='%s'" % id)
	print(query_result)

func update_position(id : int, position : int) -> void:
	execute_non_query("UPDATE images set position=? WHERE id=?", [position, id])

# Using a Dictionary is much faster than array in this case.
func get_ids_images_without_tags() -> Dictionary:
	db_access_mutex.lock()
	query("SELECT id FROM images t1 LEFT JOIN tags_images t2 ON t2.image_id = t1.id WHERE t2.image_id IS NULL")
	var retval : Dictionary = {}
	for result in query_result:
		retval[result["id"]] = false
	db_access_mutex.unlock()
	return retval

func get_ids_collections_without_tags() -> Array[int]:
	db_access_mutex.lock()
	query("SELECT id FROM collections t1 LEFT JOIN tags_collections t2 ON t2.collection_id = t1.id WHERE t2.collection_id IS NULL")
	var retval : Array[int] = []
	for entry in query_result:
		retval.append(entry["id"])
	db_access_mutex.unlock()
	return retval

func count_images_in_db() -> int:
	db_access_mutex.lock()
	query("SELECT COUNT(id) FROM images")
	var retval = query_result.duplicate()[0]["COUNT(id)"]
	db_access_mutex.unlock()
	return retval

func get_setting_grid_image_size() -> int:
	db_access_mutex.lock()
	var retval = db.select_rows("settings", "", ["grid_image_size"])[0]["grid_image_size"]
	db_access_mutex.unlock()
	return retval

func set_setting_grid_image_size(value : int) -> void:
	db_access_mutex.lock()
	query_with_bindings("UPDATE settings SET grid_image_size=?", [value])
	db_access_mutex.unlock()

# 0 = dynamic
# 1 = always fit to window
# 2 = always 100%
func get_setting_media_viewer_stretch_mode() -> int:
	db_access_mutex.lock()
	query("SELECT stretch_mode FROM settings")
	var retval = query_result.duplicate()[0]["stretch_mode"]
	db_access_mutex.unlock()
	return retval

func set_setting_media_viewer_stretch_mode(value : int) -> void:
	db_access_mutex.lock()
	query_with_bindings("UPDATE settings SET stretch_mode=?", [value])
	db_access_mutex.unlock()

func get_setting_hide_collection_images() -> bool:
	db_access_mutex.lock()
	var retval : bool = bool(db.select_rows("settings", "", ["hide_images_collections"])[0]["hide_images_collections"])
	db_access_mutex.unlock()
	return retval

func set_setting_hide_collection_images(value : bool) -> void:
	db_access_mutex.lock()
	query_with_bindings("UPDATE settings SET hide_images_collections=?", [int(value)])
	db_access_mutex.unlock()

func create_new_collection(collection_name : String) -> void:
	db_access_mutex.lock()
	query_with_bindings("INSERT INTO collections (collection) VALUES (?)", [collection_name])
	db_access_mutex.unlock()

func get_all_collections():
	db_access_mutex.lock()
	query("SELECT * FROM collections")
	var retval = query_result.duplicate()
	db_access_mutex.unlock()
	return retval

func get_all_collection_names() -> Array[String]:
	db_access_mutex.lock()
	query("SELECT collection FROM collections")
	var collection_names : Array[String] = []
	for entry in query_result:
		collection_names.append(entry["collection"])
	db_access_mutex.unlock()
	return collection_names

func get_collection_by_name(collection_name : String):
	db_access_mutex.lock()
	query_with_bindings("SELECT * FROM collections WHERE collection=?", [collection_name])
	var retval = query_result.duplicate()
	db_access_mutex.unlock()
	return retval

func add_image_to_collection(collection_id : int, image_id : int) -> void:
	db_access_mutex.lock()
	query_with_bindings("SELECT * from collections_images WHERE collection_id=?", [collection_id])
	query_with_bindings("INSERT INTO collections_images (collection_id, image_id, position) VALUES (?, ?, ?)", [collection_id, image_id, query_result.size()])
	db_access_mutex.unlock()

func get_all_images_in_collection(collection_id : int) -> Array[DBMedia]:
	db_access_mutex.lock()
	query_with_bindings("SELECT * FROM collections_images JOIN images ON images.id=collections_images.image_id WHERE collection_id=?", [collection_id])
	var retval : Array[DBMedia] = []
	for media in query_result:
		var temp = DBMedia.new()
		temp.id = media["id"]
		temp.path = media["path"]
		temp.favorite = media["fav"]
		temp.position = media["position"]
		retval.append(temp)
	db_access_mutex.unlock()
	return retval

func get_position_in_collection(image_id, collection_id):
	db_access_mutex.lock()
	query_with_bindings("SELECT position FROM collections_images WHERE image_id=? AND collection_id=?", [image_id, collection_id])
	var retval = query_result.duplicate()[0]["position"]
	db_access_mutex.unlock()
	return retval

func set_position_in_collection(image_id : int, collection_id : int, position : int) -> void:
	db_access_mutex.lock()
	query("UPDATE collections_images SET position='%s' WHERE image_id='%s' AND collection_id='%s'" % [position, image_id, collection_id])
	db_access_mutex.unlock()

func get_collection_count(collection_id):
	db_access_mutex.lock()
	query_with_bindings("SELECT COUNT(*) FROM collections_images WHERE collection_id=?", [collection_id])
	var retval = query_result.duplicate()[0]["COUNT(*)"]
	db_access_mutex.unlock()
	return retval

func get_collection_image_by_position(collection_id, position):
	db_access_mutex.lock()
	query_with_bindings("SELECT * FROM collections_images WHERE collection_id=? AND position=?", [collection_id, position])
	query_with_bindings("SELECT * FROM images WHERE id=?", [query_result[0]["image_id"]])
	var retval = query_result.duplicate()[0]
	db_access_mutex.unlock()
	return retval

func swap_positions_in_collection(image1 : DBMedia, image2, collection):
	var image_1_pos = get_position_in_collection(image1.id, collection["id"])
	var image_2_pos = get_position_in_collection(image2["id"], collection["id"])
	set_position_in_collection(image1.id, collection["id"], image_2_pos)
	set_position_in_collection(image2["id"], collection["id"], image_1_pos)

func set_collection_name(id : int, collection_name : String) -> void:
	execute_non_query("UPDATE collections SET collection=? WHERE id=?", [collection_name, id])

# for fetching the title images
func get_first_image_in_collection(collection_id : int) -> DBMedia:
	db_access_mutex.lock()
	query_with_bindings("SELECT * FROM collections_images WHERE collection_id=? AND position='0'", [collection_id])
	if query_result.size() > 1 || query_result.size() <= 0:
		db_access_mutex.unlock()
		return null
	else:
		query_with_bindings("SELECT * FROM images WHERE id=?", [query_result[0]["image_id"]])
		var retval = DBMedia.new()
		retval.id = query_result[0]["id"]
		retval.path = query_result[0]["path"]
		retval.favorite = query_result[0]["fav"]
		db_access_mutex.unlock()
		return retval

func set_collection_favorite(collection_id : int, fav : bool) -> void:
	execute_non_query("UPDATE collections SET fav=? WHERE id=?", [int(fav), collection_id])

func delete_collection(collection_id : int) -> void:
	db_access_mutex.lock()
	query_with_bindings("DELETE FROM collections WHERE id=?", [collection_id])
	query_with_bindings("DELETE FROM collections_images WHERE collection_id=?", [collection_id])
	query_with_bindings("DELETE FROM tags_collections WHERE collection_id=?", [collection_id])
	db_access_mutex.unlock()

func get_tags_for_collection(id : int) -> Array[DBTag]:
	db_access_mutex.lock()
	query_with_bindings("SELECT tags.id, tags.tag FROM tags_collections JOIN tags ON tags_collections.tag_id = tags.id WHERE collection_id = ?", [id])
	
	var retval : Array[DBTag] = []
	for entry in query_result:
		var tag = DBTag.new()
		tag.id = entry["id"]
		tag.tag = entry["tag"]
		retval.append(tag)
	
	db_access_mutex.unlock()
	return retval

func add_tag_to_collection(tag_id, collection_id):
	execute_non_query("INSERT INTO tags_collections (tag_id, collection_id) VALUES (?, ?)", [tag_id, collection_id])

func remove_tag_from_collection(tag_id, collection_id):
	execute_non_query("DELETE FROM tags_collections WHERE tag_id=? AND collection_id=?", [tag_id, collection_id])

func remove_image_from_collection(image_id : int, collection_id : int) -> void:
	execute_non_query("DELETE FROM collections_images WHERE image_id=? and collection_id=?", [image_id, collection_id])

# Using a Dictionary is much faster than array in this case.
func get_all_image_ids_in_collections() -> Dictionary:
	db_access_mutex.lock()
	query("SELECT DISTINCT image_id FROM collections_images")
	var retval : Dictionary = {}
	for id in query_result:
		retval[id["image_id"]] = false
	db_access_mutex.unlock()
	return retval

func is_image_in_collection(image_id, collection_id):
	db_access_mutex.lock()
	query_with_bindings("SELECT * FROM collections_images WHERE image_id=? AND collection_id=?", [image_id, collection_id])
	var retval = (query_result.size() > 0)
	db_access_mutex.unlock()
	return retval
