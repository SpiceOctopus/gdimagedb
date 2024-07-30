extends Node

class_name Maintenance

static func rebuild_hashes():
	print("Rebuilding hashes...")
	for file in DB.get_all_images():
		DB.query("UPDATE images SET hash='%s' WHERE id=" % ImportUtil.hash_file(file["path"]) + "%s" % file["id"])
