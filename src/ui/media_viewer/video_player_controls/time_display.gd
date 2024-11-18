extends HBoxContainer

var total : float :
	set(time):
		$TimeTotal.text = get_time_string_from_seconds(time)

var current : int : 
	set(time):
		$TimeCurrent.text = get_time_string_from_seconds(time)

func get_time_string_from_seconds(seconds : float) -> String:
	var minutes : int = floor(seconds / 60)
	return "%02d:%02d" % [minutes, seconds - (minutes * 60)]
