extends Node

signal display_mode_changed
signal favorites_changed
signal untagged_changed
signal tags_changed
signal db_images_changed
signal db_tags_changed
signal help
signal last_used_collection_changed

enum DisplayMode {Images, Collections}

var current_display_mode : DisplayMode : set=set_current_display_mode

var show_favorites : bool : set=set_show_favorites, get=get_show_favorites
var show_untagged : bool : set=set_show_untagged, get=get_show_untagged
var included_tags : set=set_included_tags, get=get_included_tags
var excluded_tags : set=set_excluded_tags, get=get_excluded_tags
var last_used_collection : set=set_last_used_collection

var internal_current_display_mode : DisplayMode = DisplayMode.Images
var internal_show_favorites_images : bool = false
var internal_show_favorites_collections : bool = false
var internal_show_untagged_images : bool = false
var internal_show_untagged_collections : bool = false
var internal_included_tags_images = []
var internal_included_tags_collections = []
var internal_excluded_tags_images = []
var internal_excluded_tags_collections = []

func set_show_favorites(fav : bool):
	if current_display_mode == DisplayMode.Images:
		internal_show_favorites_images = fav
	elif current_display_mode == DisplayMode.Collections:
		internal_show_favorites_collections = fav
	emit_signal("favorites_changed")

func get_show_favorites():
	if current_display_mode == DisplayMode.Images:
		return internal_show_favorites_images
	elif current_display_mode == DisplayMode.Collections:
		return internal_show_favorites_collections

func set_show_untagged(untagged : bool):
	if current_display_mode == DisplayMode.Images:
		internal_show_untagged_images = untagged
	elif current_display_mode == DisplayMode.Collections:
		internal_show_untagged_collections = untagged
	emit_signal("untagged_changed")

func get_show_untagged():
	if current_display_mode == DisplayMode.Images:
		return internal_show_untagged_images
	elif current_display_mode == DisplayMode.Collections:
		return internal_show_untagged_collections

func set_current_display_mode(mode : DisplayMode):
	current_display_mode = mode
	emit_signal("display_mode_changed")

func set_included_tags(tags):
	if current_display_mode == DisplayMode.Images:
		internal_included_tags_images = tags
	elif current_display_mode == DisplayMode.Collections:
		internal_included_tags_collections = tags

func set_excluded_tags(tags):
	if current_display_mode == DisplayMode.Images:
		internal_excluded_tags_images = tags
	elif current_display_mode == DisplayMode.Collections:
		internal_excluded_tags_collections = tags

func get_included_tags():
	if current_display_mode == DisplayMode.Images:
		return internal_included_tags_images
	elif current_display_mode == DisplayMode.Collections:
		return internal_included_tags_collections

func get_excluded_tags():
	if current_display_mode == DisplayMode.Images:
		return internal_excluded_tags_images
	elif current_display_mode == DisplayMode.Collections:
		return internal_excluded_tags_collections

func set_last_used_collection(collection):
	last_used_collection = collection
	emit_signal("last_used_collection_changed", last_used_collection)

func notify_tags_changed():
	emit_signal("tags_changed")

func notify_db_images_changed():
	emit_signal("db_images_changed")

func notify_help_called():
	emit_signal("help")

func notify_db_tags_changed():
	emit_signal("db_tags_changed")
