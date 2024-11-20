extends Control

signal play_pause
signal time_selected(time : float)

var dragging : bool = false

var time_total : float :
	set(time):
		time_total_label.text = get_time_string_from_seconds(time)
		progress_bar.max_value = floor(time)

var time_current : float : 
	set(time):
		time_current_label.text = get_time_string_from_seconds(time)
		if !dragging:
			progress_bar.value = floor(time)

@onready var progress_bar = $MarginContainer/Controls/Progress
@onready var time_total_label = $MarginContainer/Controls/TimeDisplay/TimeTotal
@onready var time_current_label = $MarginContainer/Controls/TimeDisplay/TimeCurrent

func _on_play_pause_pressed() -> void:
	play_pause.emit()

func _on_progress_drag_ended(_value_changed : bool) -> void:
	dragging = false
	time_selected.emit(progress_bar.value)

func _on_progress_drag_started() -> void:
	dragging = true

func get_time_string_from_seconds(seconds : float) -> String:
	var minutes : int = floor(seconds / 60)
	return "%02d:%02d" % [minutes, seconds - (minutes * 60)]
