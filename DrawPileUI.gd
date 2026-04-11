extends Control

@onready var back_sprites = $BackSprites

func _ready():
	reposition_pile()
	get_tree().root.size_changed.connect(reposition_pile)

func reposition_pile():
	var screen_size = get_viewport_rect().size
	# 尺寸对齐：确保牌堆和手里的牌看起来一致 [cite: 66]
	var scale_factor = (screen_size.y * 0.22) / 531.0
	self.scale = Vector2(scale_factor, scale_factor)
	
	# 强制锁定：屏幕右下角数值 13
	self.set_anchors_and_offsets_preset(13)
	var margin = 40.0
	var pile_w = 380.0 * scale_factor
	var pile_h = 531.0 * scale_factor
	self.global_position = Vector2(screen_size.x - pile_w - margin, screen_size.y - pile_h - margin)

func update_pile_view(count: int):
	reposition_pile()
	var layers = back_sprites.get_child_count()
	for i in range(layers):
		var sprite = back_sprites.get_child(i)
		sprite.visible = count > (i * 10) # 模拟货库厚度 [cite: 42]
		sprite.position = Vector2(-i * 8, -i * 8) 
		sprite.modulate = Color(1.0 - i*0.1, 1.0 - i*0.1, 1.0 - i*0.1)
