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
	card_node.global_position = start_pos
	cards_in_hand.append(card_node)
	if card_node.has_signal("drag_ended"):
		card_node.drag_ended.connect(_reposition_hand)
	_sort_hand()
	_reposition_hand()

func _sort_hand():
	cards_in_hand.sort_custom(func(a, b):
		if a.card_data == null or b.card_data == null:
			return false
		if a.card_data.suit != b.card_data.suit:
			return int(a.card_data.suit) < int(b.card_data.suit)
		return a.card_data.rank > b.card_data.rank
	)
	for i in range(cards_in_hand.size()):
		var card = cards_in_hand[i]
		move_child(card, i)
		card.z_index = i
		card.queue_redraw()  # 确保每次排序后边框重绘

func _reposition_hand():
	var screen_size = get_viewport_rect().size
	var card_count = cards_in_hand.size()
	if card_count == 0: return
	_sort_hand()

	# 尺寸：占据屏幕高度 22% [cite: 66]
	var target_h = screen_size.y * 0.22
	var scale_factor = target_h / original_card_height
	
	# 核心修复：直接使用数值 12 (Bottom Center) 彻底解决报错
	self.anchor_left = 0.0
	self.anchor_right = 0.0
	self.anchor_top = 0.0
	self.anchor_bottom = 0.0
	self.global_position = Vector2(screen_size.x / 2.0, screen_size.y - 20)

	var card_w = 380.0 * scale_factor
	var dynamic_spacing = card_w * 0.9
	var max_w = screen_size.x * 0.8
	
	if (card_count * dynamic_spacing) > max_w: # 蜘蛛纸牌挤压逻辑 [cite: 42]
		dynamic_spacing = max_w / card_count

	for i in range(card_count):
		var card = cards_in_hand[i]
		card.scale = Vector2(scale_factor, scale_factor)
		var offset_x = (i - (card_count - 1) / 2.0) * dynamic_spacing
		card.target_position = Vector2(offset_x, -target_h / 2.0)
func _mark_next_wild():
	if cards_in_hand.is_empty():
		return
	var target = cards_in_hand.back()
	target.set_wild_visual(true)

func _clear_wild_mark():
	for card in cards_in_hand:
		card.set_wild_visual(false)
