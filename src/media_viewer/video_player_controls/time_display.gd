extends HBoxContainer

var total : set=set_time_total
var current : set=set_time_current

func set_time_total(time):
	$TimeTotal.text = get_time_string_from_seconds(time)

func set_time_current(time):
	$TimeCurrent.text = get_time_string_from_seconds(time)

func get_time_string_from_seconds(seconds):
	var minutes = floor(seconds / 60)
	return str(minutes) + ":" + str(floor((seconds - (minutes * 60))))
