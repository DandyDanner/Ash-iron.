extends Button
## Browse-only recipe tile. Crafting remains a separate deliberate action.
func _make_custom_tooltip(for_text: String) -> Object:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("17251f")
	style.border_color = Color("d4b372")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.custom_minimum_size.x = 300
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", Color("eee4cd"))
	label.add_theme_font_size_override("font_size", 15)
	label.text = for_text
	panel.add_child(label)
	return panel
