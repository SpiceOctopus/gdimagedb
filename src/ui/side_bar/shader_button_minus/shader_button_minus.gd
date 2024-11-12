extends Panel

signal pressed

func _on_mouse_entered() -> void:
	material = CacheManager.shader_minus_red

func _on_mouse_exited() -> void:
	material = CacheManager.shader_minus_normal

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if (event.button_index == 1) && !event.pressed:
			pressed.emit()
