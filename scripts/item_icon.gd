extends Control
var item_id := ""

func _draw() -> void:
	var center := size / 2.0
	match item_id:
		"bench":
			for x in [-17.0, 17.0]:
				draw_line(center + Vector2(x, 0), center + Vector2(x - 3, 22), Color("987348"), 6, true)
			draw_line(center + Vector2(-19, 14), center + Vector2(17, 14), Color("795b3e"), 4, true)
			draw_colored_polygon(PackedVector2Array([center + Vector2(-27, -9), center + Vector2(14, -18), center + Vector2(27, -5), center + Vector2(-16, 5)]), Color("d0ac73"))
			draw_line(center + Vector2(-16, 5), center + Vector2(27, -5), Color("987348"), 5, true)
			for i in range(2):
				draw_line(center + Vector2(-23 + i * 4, -5 + i * 4), center + Vector2(18 + i * 4, -14 + i * 4), Color("ae8958"), 1.5, true)
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
		"chest":
			draw_rect(Rect2(center + Vector2(-24, -6), Vector2(48, 26)), Color("8b6a44"))
			draw_rect(Rect2(center + Vector2(-25, -17), Vector2(50, 12)), Color("9a7750"))
			for x in [-14.0, 14.0]:
				draw_rect(Rect2(center + Vector2(x - 3, -17), Vector2(6, 37)), Color("4a4640"))
			draw_rect(Rect2(center + Vector2(-4, -8), Vector2(8, 9)), Color("c9b47a"))

		"iron_ore":
			draw_colored_polygon(PackedVector2Array([center + Vector2(-24, 8), center + Vector2(-16, -12), center + Vector2(2, -20), center + Vector2(20, -8), center + Vector2(23, 12), center + Vector2(-2, 20)]), Color("5b524c"))
			draw_colored_polygon(PackedVector2Array([center + Vector2(-16, -12), center + Vector2(2, -20), center + Vector2(20, -8), center + Vector2(0, -1)]), Color("6e645c"))
			for spot in [Vector2(-10, 4), Vector2(6, 8), Vector2(11, -6), Vector2(-3, -9)]:
				draw_circle(center + spot, 4, Color("b8652d"))
				draw_circle(center + spot + Vector2(-1, -1), 1.6, Color("e08a4a"))
		"iron_ingot":
			draw_colored_polygon(PackedVector2Array([center + Vector2(-26, 4), center + Vector2(-18, -10), center + Vector2(22, -10), center + Vector2(26, 4)]), Color("8f9aa3"))
			draw_colored_polygon(PackedVector2Array([center + Vector2(-26, 4), center + Vector2(26, 4), center + Vector2(26, 14), center + Vector2(-26, 14)]), Color("5f6b75"))
			draw_line(center + Vector2(-14, -6), center + Vector2(14, -6), Color("c9d2d8"), 2, true)
		"furnace":
			draw_rect(Rect2(center + Vector2(-24, -4), Vector2(48, 28)), Color("6d6f68"))
			draw_rect(Rect2(center + Vector2(-26, 22), Vector2(52, 6)), Color("4d4b45"))
			draw_rect(Rect2(center + Vector2(-24, -8), Vector2(48, 4)), Color("4d4b45"))
			draw_rect(Rect2(center + Vector2(-8, -26), Vector2(14, 18)), Color("5d5f59"))
			draw_rect(Rect2(center + Vector2(-9, 4), Vector2(18, 14)), Color("1e1a17"))
			draw_circle(center + Vector2(0, 13), 5, Color("f0a24c"))
		"boar_hide":
			draw_colored_polygon(PackedVector2Array([center + Vector2(-24, -20), center + Vector2(-8, -16), center + Vector2(10, -22), center + Vector2(23, -13), center + Vector2(16, 4), center + Vector2(22, 23), center + Vector2(0, 17), center + Vector2(-21, 25), center + Vector2(-16, 2)]), Color("9b6744"))
			draw_line(center + Vector2(-3, -14), center + Vector2(3, 15), Color("cfb786"), 3, true)
		"stone_spear":
			draw_line(center + Vector2(-16, 25), center + Vector2(10, -17), Color("b8915d"), 4, true)
			draw_colored_polygon(PackedVector2Array([center + Vector2(19, -28), center + Vector2(2, -19), center + Vector2(7, -10), center + Vector2(16, -14)]), Color("a9b6a0"))
			draw_line(center + Vector2(3, -10), center + Vector2(9, -6), Color("ccb689"), 4, true)
			draw_line(center + Vector2(-9, 10), center + Vector2(-3, 0), Color("465b4b"), 6, true)
		"stone_pickaxe":
			draw_line(center + Vector2(-10, 23), center + Vector2(6, -17), Color("b8915d"), 6, true)
			draw_colored_polygon(PackedVector2Array([center + Vector2(-27, -3), center + Vector2(-17, -20), center + Vector2(-4, -26), center + Vector2(11, -25), center + Vector2(25, -10), center + Vector2(20, -6), center + Vector2(6, -16), center + Vector2(-8, -17)]), Color("8c9c90"))
			draw_line(center + Vector2(0, -24), center + Vector2(2, -14), Color("c4ac7b"), 3, true)
			draw_line(center + Vector2(6, -24), center + Vector2(8, -14), Color("c4ac7b"), 3, true)
		"torch":
			draw_line(center + Vector2(-6, 23), center + Vector2(1, -5), Color("b8915d"), 7, true)
			draw_colored_polygon(PackedVector2Array([center + Vector2(-12, -5), center + Vector2(-5, -20), center + Vector2(1, -29), center + Vector2(7, -15), center + Vector2(13, -5), center + Vector2(1, 4)]), Color("efa34c"))
			draw_circle(center + Vector2(0, -4), 5, Color("ffe7a8"))

		"bow":
			var curve := PackedVector2Array([center + Vector2(9, -26), center + Vector2(-10, -17), center + Vector2(-18, 0), center + Vector2(-10, 17), center + Vector2(9, 26)])
			draw_polyline(curve, Color("c29a62"), 5, true)
			draw_line(center + Vector2(9, -26), center + Vector2(9, 26), Color("e2d6b4"), 1.5, true)
			draw_line(center + Vector2(-2, 0), center + Vector2(23, 0), Color("cad4ca"), 2, true)
		"arrow":
			for x in [-8, 8]:
				draw_line(center + Vector2(x - 9, 23), center + Vector2(x + 6, -20), Color("c9b081"), 3, true)
				draw_colored_polygon(PackedVector2Array([center + Vector2(x + 1, -15), center + Vector2(x + 9, -26), center + Vector2(x + 12, -12)]), Color("a4b9b2"))
				draw_line(center + Vector2(x - 11, 13), center + Vector2(x - 4, 21), Color("e6e1c9"), 5, true)
