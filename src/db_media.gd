extends Object

class_name DBMedia

var id : int = -1
var path : String = "" : set=set_path # Full path to the file in the OS file system.
var relative_path : String = "" # Relative path starting at the content directory.
var thumb_path : String = "" # Full path to the thumbnail file in the OS file system.
var favorite : int = 0 # Integer to represent the DB. SQLite does not have a bool type.
var position : int = -1 # Only relevant for collection sorting.

# Takes the relative path provided by the database and sets both path and 
# thumb_path as absolute paths in the OS file system.
func set_path(relative_path_from_db : String) -> void:
	relative_path = relative_path_from_db
	path = relative_path_from_db.insert(0, OS.get_executable_path().get_base_dir() + "/content/")
	var temp_thumb_path = path.insert(path.find(path.get_extension()) - 1, "_thumb")
	thumb_path = temp_thumb_path.replace(temp_thumb_path.get_extension(), "png")
	if(OS.get_name() == "Linux"): # Windows does not care about mixed slashes, Linux does.
		thumb_path = thumb_path.replace("\\", "/") 
