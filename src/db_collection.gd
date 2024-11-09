extends RefCounted

class_name DBCollection

var id : int = -1
var name : String = "" # called "collection" in the db, calling it name here to be more readable
var fav : bool = false # represented by int 0 or 1 in the db since sqlite does not support bool type
