extends Node

var hide_images_collections : bool : set=set_hide_images_collections, get=get_hide_images_collections
# Grid images have identical x & y fit, thus one number is enough.
var grid_image_size : int : set=set_grid_image_size, get=get_grid_image_size 

# Supported file types
# .gif gets special treatment by the media viewer and thumbnail creator.
# Loading gif as video through ffmpeg does not work. 
# Also tested, not working: .swf
var supported_image_files : Array[String] = ["jpg", "jpeg", "png", "webp", "bmp", "gif"]
var supported_video_files : Array[String] = ["ogv", "mp4", "webm", "mov", "avi"]

func get_grid_image_size() -> int:
	return DB.get_setting_grid_image_size()

func set_grid_image_size(value : int) -> void:
	DB.set_setting_grid_image_size(value)

func get_hide_images_collections() -> bool:
	return DB.get_setting_hide_collection_images()

func set_hide_images_collections(value : bool) -> void:
	DB.set_setting_hide_collection_images(value)
