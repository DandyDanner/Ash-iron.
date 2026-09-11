extends Control
var item_id := ""

func _draw() -> void:
	var center := size / 2.0
	match item_id:
		"stick":
			draw_line(center + Vector2(-20, 14), center + Vector2(18, -14), Color("bd965e"), 7, true)
			draw_line(center + Vector2(-9, 18), center + Vector2(24, -7), Color("8e7148"), 5, true)
			draw_line(center + Vector2(2, -2), center + Vector2(0, -17), Color("bd965e"), 4, true)
		"stone":
			draw_colored_polygon(PackedVector2Array([center + Vector2(-25, 9), center + Vector2(-18, -12), center + Vector2(1, -20), center + Vector2(19, -6), center + Vector2(24, 14), center + Vector2(-4, 20)]), Color("9ba89d"))
			draw_colored_polygon(PackedVector2Array([center + Vector2(-18, -12), center + Vector2(1, -20), center + Vector2(19, -6), center + Vector2(-1, 0)]), Color("bcc6b6"))
		"wood":
			for i in range(3):
				draw_line(center + Vector2(-21, -12 + i * 12), center + Vector2(17, -12 + i * 12), Color("a57849"), 10, true)
				draw_circle(center + Vector2(19, -12 + i * 12), 5, Color("d6b77f"))
			draw_line(center + Vector2(-3, -19), center + Vector2(-3, 19), Color("cfbd8d"), 4, true)
		"stone_axe":
			draw_line(center + Vector2(-9, 24), center + Vector2(8, -22), Color("b8915d"), 6, true)
			draw_colored_polygon(PackedVector2Array([center + Vector2(-18, -21), center + Vector2(14, -18), center + Vector2(10, -1), center + Vector2(-22, -7)]), Color("9dab9e"))
			draw_line(center + Vector2(3, -19), center + Vector2(8, -2), Color("ceba87"), 4, true)
