extends Control

@onready var card_container = $CardContainer
@onready var red_rope = $RedRope
@onready var hint_box = $HintBox

var table_cards: Array = []
var next_card_value_zero: bool = false  # 冷眼旁观效果标记

# 叠牌布局参数
const CARD_PEEK_WIDTH = 50
const CARD_FULL_SCALE = 0.5

# 龙链计算相关
var chain_multiplier: float = 1.0
var consecutive_same_suit: int = 0
var last_suit: int = -1
var total_chain_value: int = 0
# 结算牌状态：记录当前龙尾是否是待触发的结算牌
var pending_settle_card: Node2D = null

var next_card_wild_suit: bool = false   # 下一张视为同花色
var skip_next_settle: bool = false      # 跳过下一张结算惩罚
var break_penalty: int = 0             # 断龙惩罚
var next_non_por_penalty: int = 0      # 下一张非瓷牌惩罚
var last_card_value_multiplier: float = 1.0  # 上一张牌价值倍率

func _ready():
	self.global_position = Vector2.ZERO
	get_tree().root.size_changed.connect(_reposition_hint_box)
	_reposition_hint_box()

func _reposition_hint_box():
	if hint_box:
		var vp = get_viewport_rect().size
		var card_w = 380.0 * CARD_FULL_SCALE
		var card_h = 531.0 * CARD_FULL_SCALE
		hint_box.size = Vector2(card_w, card_h)
		hint_box.position = Vector2(vp.x / 2.0 - card_w / 2.0, vp.y / 2.0 - card_h / 2.0)
		hint_box.visible = true

var _pending_press_card: Node2D = null  # 本帧收到信号的最高z_index牌

func _process(_delta):
	if _pending_press_card != null and is_instance_valid(_pending_press_card):
		_pending_press_card._expand_card()
	_pending_press_card = null

func _on_table_card_pressed(card: Node2D):
	if _pending_press_card == null or card.z_index > _pending_press_card.z_index:
		_pending_press_card = card

func get_last_card_data() -> BaseCard:
	return table_cards.back().card_data if not table_cards.is_empty() else null

func add_card_to_table(card_node: Node2D) -> Dictionary:
	if hint_box and hint_box.visible:
		hint_box.visible = false

	card_node.reparent(card_container)

	var card_data: BaseCard = card_node.card_data
	var result = _calculate_chain(card_data)

	# 检查上一张是否是待结算牌
	var triggered_settle = false
	if pending_settle_card != null and is_instance_valid(pending_settle_card):
		# 下一张牌打上来了，触发结算
		result["trigger_settle"] = true
		result["settle_card_data"] = pending_settle_card.card_data
		pending_settle_card = null
		triggered_settle = true
	else:
		result["trigger_settle"] = false

	# 如果这张牌本身是结算牌，设为待结算状态
	if card_data.is_settle_card() and not triggered_settle:
		pending_settle_card = card_node
		card_node.shake_enabled = true

	table_cards.append(card_node)
	_reposition_all_cards()

	return result

func _reposition_all_cards():
	var screen_center = get_viewport_rect().size / 2.0
	var total = table_cards.size()
	if total == 0:
		return

	var full_card_w = 380.0 * CARD_FULL_SCALE
	var stack_total_w = (total - 1) * CARD_PEEK_WIDTH + full_card_w
	var start_x = screen_center.x - stack_total_w / 2.0
	var stack_y = screen_center.y - (531.0 * CARD_FULL_SCALE / 2.0)

	for i in range(total):
		var card = table_cards[i]
		if not is_instance_valid(card):
			continue
		var target_gp = Vector2(start_x + i * CARD_PEEK_WIDTH, stack_y)

		# 直接设置全局坐标，不用lerp也不用tween回调
		card.global_position = target_gp
		card.scale = Vector2(CARD_FULL_SCALE, CARD_FULL_SCALE)
		card.target_position = card.position
		card.z_index = i
		if card.has_method("_start_breathe"):
			card._start_breathe(card.card_data)
		# 连接点击信号（避免重复连接）
		if card.has_signal("table_card_pressed"):
			if not card.table_card_pressed.is_connected(_on_table_card_pressed):
				card.table_card_pressed.connect(_on_table_card_pressed)

	for i in range(total):
		var card = table_cards[i]
		if not is_instance_valid(card):
			continue
		var target_gp = Vector2(start_x + i * CARD_PEEK_WIDTH, stack_y)
		card.target_position = card_container.to_local(target_gp) if card_container.has_method("to_local") else target_gp
		card.global_position = target_gp
		card.scale = Vector2(CARD_FULL_SCALE, CARD_FULL_SCALE)
		card.target_position = card.position
		card.z_index = i

	# 最后一张完整显示，其他只露一条
		if card.has_method("_start_breathe"):
			var is_last = (i == total - 1)
			card.peek_width = -1.0 if is_last else float(CARD_PEEK_WIDTH)
			card._start_breathe(card.card_data)
		if card.has_signal("table_card_pressed"):
			if not card.table_card_pressed.is_connected(_on_table_card_pressed):
				card.table_card_pressed.connect(_on_table_card_pressed)
func _calculate_chain(card_data: BaseCard) -> Dictionary:
	var card_suit = int(card_data.suit)

	# 下一张视为同花色效果
	if next_card_wild_suit:
		card_suit = last_suit if last_suit != -1 else card_suit
		next_card_wild_suit = false

	var is_same_suit = (card_suit == last_suit and last_suit != -1)
	var feedback_type = "neutral"

	if last_suit == -1:
		consecutive_same_suit = 1
		chain_multiplier = 1.0
		feedback_type = "positive"
	elif is_same_suit:
		consecutive_same_suit += 1
		chain_multiplier += 0.2
		if consecutive_same_suit % 3 == 0:
			feedback_type = "recover_breath"
		else:
			feedback_type = "positive"
	else:
		consecutive_same_suit = 1
		chain_multiplier = 1.0
		feedback_type = "negative"

	last_suit = card_suit

	var card_value = int(card_data.base_value * chain_multiplier)
	total_chain_value += card_value

	return {
		"card_value": card_value,
		"base_value": card_data.base_value,
		"multiplier": chain_multiplier,
		"total": total_chain_value,
		"same_suit_count": consecutive_same_suit,
		"feedback_type": feedback_type,
		"is_settle": card_data.is_settle_card()
	}

func settle_chain() -> int:
	var settled_value = total_chain_value
	print("龙链结算！总价值：", settled_value, " 贯，共 ", table_cards.size(), " 张牌")
	return settled_value

func reset_chain():
	chain_multiplier = 1.0
	consecutive_same_suit = 0
	last_suit = -1
	total_chain_value = 0

func clear_table():
	for card in table_cards:
		if is_instance_valid(card):
			card.queue_free()
	table_cards.clear()
	if hint_box:
		hint_box.visible = true
	if red_rope:
		red_rope.clear_points()
	reset_chain()
	
func add_block_card_to_table(block_node: Node2D):
	card_container.add_child(block_node)
	table_cards.append(block_node)
	block_node.is_on_table = true
	_reposition_all_cards()
