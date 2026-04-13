extends Label

# 浮动数字：从指定位置向上飘，然后淡出消失

func spawn(display_text: String, color: Color, world_pos: Vector2):
	self.text = display_text
	self.position = world_pos
	add_theme_font_size_override("font_size", 48)
	add_theme_color_override("font_color", color)
	modulate.a = 1.0

	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "position", world_pos + Vector2(0, -150), 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(queue_free)
