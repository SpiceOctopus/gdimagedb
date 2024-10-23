extends Panel

signal pressed

func _on_mouse_entered() -> void:
	material = load("res://ui/side_bar/shader_button_plus/shader_button_plus_green.tres")

func _on_mouse_exited() -> void:
	material = load("res://ui/side_bar/shader_button_plus/shader_button_plus.tres")

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if (event.button_index == 1) && !event.pressed:
			pressed.emit()
