# DrawPileUI.gd
extends Control

@onready var back_sprites = $BackSprites # 内含几个重叠的卡背图片

func update_pile_view(count: int):
	# 每 10 张牌显示一个视觉层
	for i in range(back_sprites.get_child_count()):
		back_sprites.get_child(i).visible = count > (i * 10)
