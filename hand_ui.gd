extends Control # 核心修复：这里必须是 Control

@export var card_scene: PackedScene = preload("res://card_ui.tscn")
var cards_in_hand: Array = []
var original_card_height: float = 531.0 

func _ready():
	# 监听窗口缩放，确保手牌永远在底部居中 [cite: 66]
	get_tree().root.size_changed.connect(_reposition_hand)
	_reposition_hand()

func add_card_with_animation(card_node: Node2D, start_pos: Vector2):
	add_child(card_node)
	card_node.global_position = start_pos # 飞入起点：右侧牌堆
	cards_in_hand.append(card_node)
	
	if card_node.has_signal("drag_ended"):
		card_node.drag_ended.connect(_reposition_hand)
	_reposition_hand()

func _reposition_hand():
	var screen_size = get_viewport_rect().size
	var card_count = cards_in_hand.size()
	if card_count == 0: return

	# 尺寸：占据屏幕高度 22% [cite: 66]
	var target_h = screen_size.y * 0.22 
	var scale_factor = target_h / original_card_height
	
	# 核心修复：直接使用数值 12 (Bottom Center) 彻底解决报错
	self.anchor_left = 0.5
	self.anchor_right = 0.5
	self.anchor_top = 1.0
	self.anchor_bottom = 1.0
	self.position.y = screen_size.y - 20

	var card_w = 380.0 * scale_factor
	var dynamic_spacing = card_w * 0.9
	var max_w = screen_size.x * 0.8
	
	if (card_count * dynamic_spacing) > max_w: # 蜘蛛纸牌挤压逻辑 [cite: 42]
		dynamic_spacing = max_w / card_count

	for i in range(card_count):
		var card = cards_in_hand[i]
		card.scale = Vector2(scale_factor, scale_factor)
		var offset_x = (i - (card_count - 1) / 2.0) * dynamic_spacing
		card.target_position = Vector2(offset_x, 0)
