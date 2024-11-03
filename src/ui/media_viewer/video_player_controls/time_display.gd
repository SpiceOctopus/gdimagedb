extends HBoxContainer

var total : float :
	set(time):
		$TimeTotal.text = get_time_string_from_seconds(time)

var current : int : 
	set(time):
		$TimeCurrent.text = get_time_string_from_seconds(time)

func get_time_string_from_seconds(seconds : float) -> String:
	var minutes : int = floor(seconds / 60)
	return str(minutes) + ":" + str(floor((seconds - (minutes * 60))))
