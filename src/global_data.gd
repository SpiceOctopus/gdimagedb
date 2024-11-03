extends Node

signal display_mode_changed
signal favorites_changed
signal untagged_changed
signal tags_changed
signal db_tags_changed
signal db_collections_changed
signal media_deleted
signal collection_deleted
signal help
signal last_used_collection_changed(collection : DBCollection)

enum DisplayMode {IMAGES, COLLECTIONS}

var current_display_mode : DisplayMode : 
	set(mode):
		current_display_mode = mode
		display_mode_changed.emit()

var show_favorites : bool : set=set_show_favorites, get=get_show_favorites
var show_untagged : bool : set=set_show_untagged, get=get_show_untagged
var included_tags : Array[DBTag] : set=set_included_tags, get=get_included_tags
var excluded_tags : Array[DBTag] : set=set_excluded_tags, get=get_excluded_tags
var last_used_collection : DBCollection : set=set_last_used_collection

var internal_current_display_mode : DisplayMode = DisplayMode.IMAGES
var internal_show_favorites_images : bool = false
var internal_show_favorites_collections : bool = false
var internal_show_untagged_images : bool = false
var internal_show_untagged_collections : bool = false
var internal_included_tags_images : Array[DBTag] = []
var internal_included_tags_collections : Array[DBTag] = []
var internal_excluded_tags_images : Array[DBTag] = []
var internal_excluded_tags_collections : Array[DBTag] = []

func set_show_favorites(fav : bool) -> void:
	if current_display_mode == DisplayMode.IMAGES:
		internal_show_favorites_images = fav
	elif current_display_mode == DisplayMode.COLLECTIONS:
		internal_show_favorites_collections = fav
	favorites_changed.emit()

func get_show_favorites() -> bool:
	if current_display_mode == DisplayMode.IMAGES:
		return internal_show_favorites_images
	elif current_display_mode == DisplayMode.COLLECTIONS:
		return internal_show_favorites_collections
	else:
		return false

func set_show_untagged(untagged : bool) -> void:
	if current_display_mode == DisplayMode.IMAGES:
		internal_show_untagged_images = untagged
	elif current_display_mode == DisplayMode.COLLECTIONS:
		internal_show_untagged_collections = untagged
	untagged_changed.emit()

func get_show_untagged():
	if current_display_mode == DisplayMode.IMAGES:
		return internal_show_untagged_images
	elif current_display_mode == DisplayMode.COLLECTIONS:
		return internal_show_untagged_collections

func set_included_tags(tags : Array[DBTag]) -> void:
	if current_display_mode == DisplayMode.IMAGES:
		internal_included_tags_images = tags
	elif current_display_mode == DisplayMode.COLLECTIONS:
		internal_included_tags_collections = tags

func set_excluded_tags(tags) -> void:
	if current_display_mode == DisplayMode.IMAGES:
		internal_excluded_tags_images = tags
	elif current_display_mode == DisplayMode.COLLECTIONS:
		internal_excluded_tags_collections = tags

func get_included_tags() -> Array[DBTag]:
	if current_display_mode == DisplayMode.IMAGES:
		return internal_included_tags_images
	elif current_display_mode == DisplayMode.COLLECTIONS:
		return internal_included_tags_collections
	else:
		return []

func get_excluded_tags():
	if current_display_mode == DisplayMode.IMAGES:
		return internal_excluded_tags_images
	elif current_display_mode == DisplayMode.COLLECTIONS:
		return internal_excluded_tags_collections

func set_last_used_collection(collection : DBCollection) -> void:
	last_used_collection = collection
	last_used_collection_changed.emit(last_used_collection)

func notify_tags_changed() -> void:
	tags_changed.emit()

func notify_help_called() -> void:
	help.emit()

func notify_db_tags_changed() -> void:
	db_tags_changed.emit()

func notify_media_deleted(id) -> void:
	media_deleted.emit(id)

func notify_db_collections_changed() -> void:
	db_collections_changed.emit()

func notify_collection_deleted(id : int) -> void:
	collection_deleted.emit(id)
