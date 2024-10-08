extends Control

signal play_pause
signal time_selected(time)

var dragging : bool = false

@onready var time_display = $MarginContainer/HBoxContainer/TimeDisplay
@onready var progress_bar = $MarginContainer/HBoxContainer/Progress

func _on_play_pause_pressed():
	play_pause.emit()

func set_time_total(time):
	time_display.total = time
	progress_bar.max_value = floor(time)

func set_time_current(time):
	time_display.current = time
	if !dragging:
		progress_bar.value = floor(time)

func _on_progress_drag_ended(_value_changed):
	dragging = false
	time_selected.emit(progress_bar.value)

func _on_progress_drag_started():
	dragging = true
