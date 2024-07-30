extends Node

var thumb_mutex = Mutex.new()
var image_mutex = Mutex.new()

var thumb_cache = {}
var image_cache = {}
