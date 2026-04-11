# DrawPileUI.gd
extends Control

@onready var back_sprites = $BackSprites

func update_pile_view(count: int):
	# 1. 强制对齐比例：读取屏幕高度计算 22% 的缩放
	var screen_h = get_viewport_rect().size.y
	# 531 是原始高度，这里确保牌堆和手里的牌看起来一样大
	var target_scale = (screen_h * 0.22) / 531.0
	self.scale = Vector2(target_scale, target_scale)
	
	# 2. 厚度模拟：偏移层叠
	var layers = back_sprites.get_child_count()
	for i in range(layers):
		var sprite = back_sprites.get_child(i)
		sprite.visible = count > (i * 10)
		# 制造视觉厚度：偏移 (-5, -5) 产生堆叠效果
		sprite.position = Vector2(-i * 5, -i * 5)
		# 调暗底层，模拟阴影
		sprite.modulate = Color(1.0 - i * 0.05, 1.0 - i * 0.05, 1.0 - i * 0.05)
