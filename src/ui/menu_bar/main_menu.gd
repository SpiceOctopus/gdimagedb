extends Control

signal refresh_grid
signal switch_grids

@onready var settings_menu = $MarginContainer/HBoxContainer2/HBoxContainer/SettingsMenu
@onready var btn_switch_grids = $MarginContainer/HBoxContainer2/HBoxContainer2/SwitchGridsButton
@onready var tags_menu = $MarginContainer/HBoxContainer2/HBoxContainer/TagsMenu
@onready var favorites_checkbox = $MarginContainer/HBoxContainer2/HBoxContainer/FavoritesCheckBox
@onready var untagged_checkbox = $MarginContainer/HBoxContainer2/HBoxContainer/UntaggedCheckBox
@onready var add_tag_window = $AddTagDialog
@onready var delete_tag_window = $DeleteTagDialog
@onready var grid_image_size = $GridImageSizeCtrl
@onready var help = $Help

func _ready():
	settings_menu.get_popup().connect("id_pressed",Callable(self,"_on_settings_menu_selection"))
	settings_menu.get_popup().set_item_checked(1, Settings.hide_images_collections)
	tags_menu.get_popup().connect("id_pressed",Callable(self,"_on_tags_menu_selection"))
	GlobalData.connect("display_mode_changed", _on_display_mode_changed)
	GlobalData.connect("tags_changed", _on_tags_changed)
	GlobalData.connect("help", _on_help_button_pressed)

func _on_tags_changed():
	untagged_checkbox.disabled = (GlobalData.included_tags.size() > 0 || GlobalData.excluded_tags.size() > 0)
	if GlobalData.show_untagged && untagged_checkbox.disabled: # avoid resetting the grid unnecessarily
		untagged_checkbox.button_pressed = false
		GlobalData.show_untagged = false

func _on_display_mode_changed():
	if GlobalData.current_display_mode == GlobalData.DisplayMode.Images:
		favorites_checkbox.button_pressed = GlobalData.show_favorites
		untagged_checkbox.button_pressed = GlobalData.show_untagged
		btn_switch_grids.text = "Collections"
	elif GlobalData.current_display_mode == GlobalData.DisplayMode.Collections:
		favorites_checkbox.button_pressed = GlobalData.show_favorites
		untagged_checkbox.button_pressed = GlobalData.show_untagged
		btn_switch_grids.text = "Images"
	untagged_checkbox.disabled = (GlobalData.included_tags.size() > 0 || GlobalData.excluded_tags.size() > 0)

func _on_settings_menu_selection(id):
	if id == 0: # Grid Image Size Setting
		grid_image_size.popup_centered()
	elif id == 2: # hide images in collections
		Settings.hide_images_collections = !Settings.hide_images_collections
		settings_menu.get_popup().set_item_checked(1, Settings.hide_images_collections)
		refresh_grid.emit()

func _on_tags_menu_selection(id):
	if id == 0: # add tag
		add_tag_window.popup_centered()
	elif id == 1: # delete tag
		delete_tag_window.popup_centered()

func _on_untagged_check_box_toggled(button_pressed):
	if GlobalData.current_display_mode == GlobalData.DisplayMode.Images:
		GlobalData.show_untagged = button_pressed
	elif GlobalData.current_display_mode == GlobalData.DisplayMode.Collections:
		GlobalData.show_untagged = button_pressed

func _on_FavoritesCheckBox_toggled(button_pressed):
	GlobalData.show_favorites = button_pressed

func _on_RefreshButton_pressed():
	refresh_grid.emit()

func _on_btn_switch_grids_pressed():
	switch_grids.emit()

func _on_help_button_pressed():
	help.popup_centered()

func _on_grid_image_size_ctrl_refresh_grid():
	_on_RefreshButton_pressed()
