# DrawPileUI.gd
extends Control

@onready var back_sprites = $BackSprites

func update_pile_view(count: int):
	# 1. 尺寸对齐：获取和手牌一样的缩放比例
	var screen_h = get_viewport_rect().size.y
	# 我们在 hand_ui 里规定的高度是屏幕的 22%，原始高度是 531 [cite: 50, 262, 263]
	var target_scale = (screen_h * 0.22) / 531.0
	self.scale = Vector2(target_scale, target_scale)
	
	# 2. 视觉厚度：根据剩余张数显示重叠
	var children = back_sprites.get_children()
	for i in range(children.size()):
		var sprite = children[i]
		# 每 10 张牌多显示一层 
		sprite.visible = count > (i * 10)
		# 向上向左轻微偏移，制造 3D 堆叠感
		sprite.position = Vector2(-i * 4, -i * 4)
		# 颜色稍微调暗一点，区分层级
		sprite.modulate = Color(1.0 - i*0.05, 1.0 - i*0.05, 1.0 - i*0.05)
