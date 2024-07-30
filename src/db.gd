extends Node

var db_path : String = OS.get_executable_path().get_base_dir() + "/main.db"
var db = SQLite.new()
var query_result
var current_db_version = 3

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

func db_path_to_full_path(path):
	return path.insert(0, OS.get_executable_path().get_base_dir() + "/content/")

func db_path_to_full_thumb_path(path):
	var thumb_path = db_path_to_full_path(path)
	thumb_path = thumb_path.insert(thumb_path.find(thumb_path.get_extension()) - 1, "_thumb")
	thumb_path = thumb_path.replace(thumb_path.get_extension(), "png")
	if(OS.get_name() == "Linux"):
		thumb_path = thumb_path.replace("\\", "/")
	return thumb_path

func get_all_images():
	query("SELECT * FROM images")
	return query_result

func get_all_images_relative_paths():
	query("SELECT * FROM images")
	return query_result

func get_all_tags():
	query("SELECT * FROM tags")
	return query_result

func get_all_tag_counts():
	query("SELECT tag_id, count(tag_id) FROM tags_images GROUP BY tag_id")
	var counts : Dictionary = {}
	for result in query_result: # each result is a dictionary with a tag_id and count(tag_id) key value pair
		counts[result["tag_id"]] = result["count(tag_id)"]
	return counts

func get_image(id):
	query_with_bindings("SELECT * FROM images WHERE id=?", [id])
	return query_result[0]

func get_tags_for_image(id):
	query_with_bindings("SELECT tags.id, tags.tag FROM tags_images JOIN tags ON tags_images.tag_id = tags.id WHERE image_id = ?", [id])
	return query_result

# tag is the tag in string form, not the id!
func is_tag_in_db(tag):
	query_with_bindings("SELECT * FROM tags WHERE tag=?", [tag])
	return (query_result.size() > 0)

# tag is the tag in string form, not the id!
func add_tag_to_db(tag):
	query_with_bindings("INSERT INTO tags (tag) VALUES (?)", [tag])

func get_tag_id(tag):
	query_with_bindings("SELECT id FROM tags WHERE tag=?", [tag])
	return query_result[0]["id"]

func add_tag_to_image(tag_id, image_id):
	query_with_bindings("INSERT INTO tags_images (tag_id, image_id) VALUES (?, ?)", [tag_id, image_id])

func remove_tag_from_image(tag_id, image_id):
	query_with_bindings("DELETE FROM tags_images WHERE tag_id=? AND image_id=?", [tag_id, image_id])

func delete_image(image_id):
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

func compare_by_position(a, b):
	return a["position"] < b["position"]

func delete_tag(id):
	query_with_bindings("DELETE FROM tags WHERE id=?", [id])
	query_with_bindings("DELETE FROM tags_images WHERE tag_id=?", [id])
	query_with_bindings("DELETE FROM tags_collections WHERE tag_id=?", [id])

func get_tag_by_name(tag_name):
	query_with_bindings("SELECT * FROM tags WHERE tag=?", [tag_name])
	return DB.query_result[0]

# status = int 0 or 1
func set_fav(id, status):
	query_with_bindings("UPDATE images set fav=? WHERE ID=?", [status, id])

func is_hash_in_db(file_hash : String) -> bool:
	query("SELECT hash FROM images")
	for result in query_result:
		if result["hash"] == file_hash:
			return true
	return false

# Both tag parameters represent a full tag row as retrieved from the db (array of dicts).
func get_images_for_tags(includedTags = [], excludedTags = []):
	var result
	
	if includedTags.size() > 0:
		var tagString = ""
		var tagCount = 0
		for tag in includedTags:
			tagString += " %s," % tag["id"]
			tagCount += 1
		tagString = tagString.trim_suffix(",") # remove the last colon
		query("SELECT * FROM images AS img JOIN tags_images AS tgimg ON tgimg.image_id = img.id AND tgimg.tag_id IN( %s ) " % tagString + "GROUP BY img.id HAVING COUNT(img.id) = %s" % tagCount)
		result = query_result
	else:
		result = get_all_images_relative_paths()
		
	if excludedTags.size() > 0:
		var cmd = "SELECT DISTINCT images.id FROM images JOIN tags_images ON tags_images.image_id = images.id JOIN tags ON tags_images.tag_id = tags.id WHERE"
		for tag in excludedTags:
			cmd += " tags.id = '%s' OR" % tag["id"]
		cmd = cmd.trim_suffix("OR")
		query(cmd)
		var tmp = query_result
		for image in result.duplicate():
			for tmpimage in tmp:
				if image["id"] == tmpimage["id"]:
					result.erase(image)
	return result

func get_collections_for_tags(includedTags, excludedTags):
	var result
	
	if includedTags.size() > 0:
		var tagString = ""
		var tagCount = 0
		for tag in includedTags:
			tagString += " %s," % tag["id"]
			tagCount += 1
		tagString = tagString.trim_suffix(",") # remove the last colon
		query("SELECT * FROM collections AS collection JOIN tags_collections AS tgcoll ON tgcoll.collection_id = collection.id AND tgcoll.tag_id IN( %s ) GROUP BY collection.id HAVING COUNT(collection.id) = %s" % [tagString, tagCount])
		result = query_result
	else:
		result = get_all_collections()
		
	if excludedTags.size() > 0:
		var cmd = "SELECT DISTINCT collections.id FROM collections JOIN tags_collections ON tags_collections.collection_id = collections.id JOIN tags ON tags_collections.tag_id = tags.id WHERE"
		for tag in excludedTags:
			cmd += " tags.id = '%s' OR" % tag["id"]
		cmd = cmd.trim_suffix("OR")
		query(cmd)
		var tmp = query_result
		for image in result.duplicate():
			for tmpimage in tmp:
				if image["id"] == tmpimage["id"]:
					result.erase(image)
	return result

func get_siblings(id):
	query("SELECT * FROM siblings WHERE id='%s' " % id + "OD sibling='%s'" % id)
	print(query_result)

func update_position(id, position):
	query_with_bindings("UPDATE images set position=? WHERE id=?", [position, id])

func get_ids_images_without_tags():
	query("SELECT id FROM images t1 LEFT JOIN tags_images t2 ON t2.image_id = t1.id WHERE t2.image_id IS NULL")
	return query_result

func count_images_in_db():
	query("SELECT COUNT(id) FROM images")
	return query_result[0]["COUNT(id)"]

func get_setting_grid_image_size():
	query("SELECT grid_image_size FROM settings")
	return query_result[0]["grid_image_size"]

func set_setting_grid_image_size(value : int):
	query_with_bindings("UPDATE settings SET grid_image_size=?", [value])

# 0 = dynamic
# 1 = always fit to window
# 2 = always 100%
func get_setting_media_viewer_stretch_mode():
	query("SELECT stretch_mode FROM settings")
	return query_result[0]["stretch_mode"]

func set_setting_media_viewer_stretch_mode(value : int):
	query_with_bindings("UPDATE settings SET stretch_mode=?", [value])

func get_setting_hide_collection_images():
	query("SELECT hide_images_collections FROM settings")
	return query_result[0]["hide_images_collections"]

func set_setting_hide_collection_images(value : int):
	query_with_bindings("UPDATE settings SET hide_images_collections=?", [value])

func create_new_collection(collection_name : String):
	query_with_bindings("INSERT INTO collections (collection) VALUES (?)", [collection_name])

func get_all_collections():
	query("SELECT * FROM collections")
	return query_result

func get_collection_by_name(collection_name : String):
	query_with_bindings("SELECT * FROM collections WHERE collection=?", [collection_name])
	return query_result

func add_image_to_collection(collection_id, image_id):
	query_with_bindings("SELECT * from collections_images WHERE collection_id=?", [collection_id])
	query_with_bindings("INSERT INTO collections_images (collection_id, image_id, position) VALUES (?, ?, ?)", [collection_id, image_id, query_result.size()])

func get_all_images_in_collection(collection_id):
	query_with_bindings("SELECT * FROM collections_images JOIN images ON images.id=collections_images.image_id WHERE collection_id=?", [collection_id])
	return query_result

func get_position_in_collection(image_id, collection_id):
	query_with_bindings("SELECT position FROM collections_images WHERE image_id=? AND collection_id=?", [image_id, collection_id])
	return query_result[0]["position"]

func set_position_in_collection(image_id, collection_id, position):
	query("UPDATE collections_images SET position='%s' WHERE image_id='%s' AND collection_id='%s'" % [position, image_id, collection_id])

func get_collection_count(collection_id):
	query_with_bindings("SELECT COUNT(*) FROM collections_images WHERE collection_id=?", [collection_id])
	return query_result[0]["COUNT(*)"]

func get_collection_image_by_position(collection_id, position):
	query_with_bindings("SELECT * FROM collections_images WHERE collection_id=? AND position=?", [collection_id, position])
	query_with_bindings("SELECT * FROM images WHERE id=?", [query_result[0]["image_id"]])
	return query_result[0]

func swap_positions_in_collection(image1, image2, collection):
	var image_1_pos = get_position_in_collection(image1["id"], collection["id"])
	var image_2_pos = get_position_in_collection(image2["id"], collection["id"])
	set_position_in_collection(image1["id"], collection["id"], image_2_pos)
	set_position_in_collection(image2["id"], collection["id"], image_1_pos)

func set_collection_name(id, collection_name):
	query_with_bindings("UPDATE collections SET collection=? WHERE id=?", [collection_name, id])

# for fetching the title image
func get_first_image_in_collection(collection_id):
	query_with_bindings("SELECT * FROM collections_images WHERE collection_id=? AND position='0'", [collection_id])
	if query_result.size() > 1 || query_result.size() <= 0:
		return {}
	else:
		query_with_bindings("SELECT * FROM images WHERE id=?", [query_result[0]["image_id"]])
		return query_result[0]

func set_collection_favorite(collection_id, fav):
	query_with_bindings("UPDATE collections SET fav=? WHERE id=?", [fav, collection_id])

func delete_collection(collection_id):
	query_with_bindings("DELETE FROM collections WHERE id=?", [collection_id])
	query_with_bindings("DELETE FROM collections_images WHERE collection_id=?", [collection_id])
	query_with_bindings("DELETE FROM tags_collections WHERE collection_id=?", [collection_id])

func get_tags_for_collection(id):
	query_with_bindings("SELECT tags.id, tags.tag FROM tags_collections JOIN tags ON tags_collections.tag_id = tags.id WHERE collection_id = ?", [id])
	return query_result

func add_tag_to_collection(tag_id, collection_id):
	query_with_bindings("INSERT INTO tags_collections (tag_id, collection_id) VALUES (?, ?)", [tag_id, collection_id])

func remove_tag_from_collection(tag_id, collection_id):
	query_with_bindings("DELETE FROM tags_collections WHERE tag_id=? AND collection_id=?", [tag_id, collection_id])

func remove_image_from_collection(image_id, collection_id):
	query_with_bindings("DELETE FROM collections_images WHERE image_id=? and collection_id=?", [image_id, collection_id])

func get_all_image_ids_in_collections():
	query("SELECT DISTINCT image_id FROM collections_images")
	var retval = []
	for id in query_result:
		retval.append(id["image_id"])
	return retval

func is_image_in_collection(image_id, collection_id):
	query_with_bindings("SELECT * FROM collections_images WHERE image_id=? AND collection_id=?", [image_id, collection_id])
	return query_result.size() > 0
