extends Node

@export var max_breath: int = 5
var current_breath: int
var total_money: int = 0  # 玩家累计赚到的钱
var block_scene: PackedScene = preload("res://block_card_ui.tscn")
var patience_exhausted_count: int = 0  # 耐心耗尽次数，影响强度权重
var floating_number_count: int = 0
var next_play_is_wild: bool = false

@onready var hand_ui = $HandUI
@onready var table_manager = $TableManager
@onready var deck_manager = $DeckManager
@onready var draw_pile_ui = $DrawPileUI
@onready var status_bar = $HUDLayer/StatusBar
@onready var patience_bar = $HUDLayer/PatienceBar
@onready var effect_system = $EffectSystem

func _ready():
	if hand_ui == null:
		push_error("错误：在主场景找不到 HandUI 节点！请检查路径。")
		return

	current_breath = max_breath
	effect_system.setup(self, table_manager, hand_ui, deck_manager)
	deck_manager.init_deck()
	for i in range(5):
		_draw_card_to_hand_with_anim()
	_refresh_status()

func _draw_card_to_hand_with_anim():
	var data = deck_manager.draw_one_card()
	if data:
		var new_card = hand_ui.card_scene.instantiate()
		new_card.setup(data)
		new_card.z_index = 0  # 加这行
		hand_ui.add_card_with_animation(new_card, draw_pile_ui.global_position)
		draw_pile_ui.update_pile_view(deck_manager.draw_pile.size())
		hand_ui._reposition_hand()

func try_play_card(card_node: Area2D) -> bool:
	var _card_data = card_node.card_data
	hand_ui.cards_in_hand.erase(card_node)
	# 打出牌后清除野性标记
	if next_play_is_wild:
		next_play_is_wild = false
		hand_ui._clear_wild_mark()
	var result = table_manager.add_card_to_table(card_node)

	if result.get("trigger_settle", false):
		var settle_data = result["settle_card_data"]
		_trigger_settle(settle_data)
		return true

	var cost = 0.5 if result["feedback_type"] == "positive" else 2.0
	var triggered = patience_bar.consume(cost)
	if triggered:
		_insert_block_card()

	# 跨花色消耗气口
	if result["feedback_type"] == "negative":
		current_breath -= 1
		_check_breath()
		if current_breath <= 0:
			return true

	# 同花色连击回气口
	if result["feedback_type"] == "recover_breath":
		current_breath = min(current_breath + 1, max_breath)
		_spawn_floating_number("同花色连击！气口+1", Color(0.2, 0.9, 0.3))

	# 普通反馈
	if result["feedback_type"] == "positive" or result["feedback_type"] == "recover_breath":
		var txt = "+" + str(result["card_value"]) + " 贯"
		if result["multiplier"] > 1.0:
			txt += "  ×" + ("%.1f" % result["multiplier"])
		_spawn_floating_number(txt, Color(0.2, 0.9, 0.3))
	elif result["feedback_type"] == "negative":
		_spawn_floating_number("跨花色  倍率×1.0", Color(0.95, 0.55, 0.1))

	# 极品牌消耗气口
	if card_node.card_data.rank > 10:
		current_breath -= 1
		_spawn_floating_number("极品耗气！气口-1", Color(0.95, 0.2, 0.2))
		_check_breath()
		if current_breath <= 0:
			return true

	# 执行效果牌
	if card_node.card_data.card_type == BaseCard.CardType.EFFECT:
		effect_system.execute(card_node.card_data.effect_id)

	# 补牌
	_draw_card_to_hand_with_anim()
	_refresh_status()
	return true

func _trigger_settle(settle_card: BaseCard):
	# 根据结算牌花色决定惩罚
	var settled_value = table_manager.settle_chain()

	match settle_card.suit:
		BaseCard.Suit.TEA:
			# 仙茶：结算金额×1.5，但气口-1
			settled_value = int(settled_value * 1.5)
			current_breath -= 1
			print("🍵 仙茶结算！获得 ", settled_value, " 贯，但气口-1（剩余：", current_breath, "）")
		BaseCard.Suit.PORCELAIN:
			# 秘色瓷瓶：结算金额×0.3，但下一条龙倍率×3（暂时只做扣钱）
			settled_value = int(settled_value * 0.3)
			print("🏺 秘色瓷瓶结算！瓷器碎裂，仅获得 ", settled_value, " 贯")
		BaseCard.Suit.SILK:
			# 凤羽锦：不打折，但手牌全丢重抽
			print("🧵 凤羽锦结算！获得 ", settled_value, " 贯，手牌全部重抽")
			_discard_and_redraw_hand()
		BaseCard.Suit.INCENSE:
			# 返魂香：金额×2，但牌库顶压入2张诅咒牌（暂时只做加钱）
			settled_value = int(settled_value * 2)
			print("🪔 返魂香结算！获得 ", settled_value, " 贯（但诅咒将至）")

	total_money += settled_value
	print("💰 本局总计：", total_money, " 贯")
	_spawn_floating_number("结算！+" + str(settled_value) + " 贯", Color(0.95, 0.2, 0.2))

	# 清场，重新开始龙链
	table_manager.clear_table()
	_draw_card_to_hand_with_anim()

func _discard_and_redraw_hand():
	# 丢弃所有手牌重抽5张
	for card in hand_ui.cards_in_hand:
		if is_instance_valid(card):
			card.queue_free()
	hand_ui.cards_in_hand.clear()
	for i in range(5):
		_draw_card_to_hand_with_anim()

func _spawn_floating_number(text: String, color: Color):
	var last_card = table_manager.table_cards.back() if not table_manager.table_cards.is_empty() else null
	var base_pos = Vector2(get_viewport().size.x / 2.0, get_viewport().size.y / 2.0 - 100)
	if last_card and is_instance_valid(last_card):
		base_pos = last_card.global_position + Vector2(50, 0)

	# 每个浮动数字垂直错开50像素
	var offset_y = floating_number_count * -55
	var spawn_pos = base_pos + Vector2(0, offset_y)

	var label = Label.new()
	label.set_script(load("res://FloatingNumber.gd"))
	$HUDLayer.add_child(label)
	label.spawn(text, color, spawn_pos)

	floating_number_count += 1
	# 1秒后计数减1（和浮动数字存活时间一致）
	await get_tree().create_timer(1.0).timeout
	floating_number_count -= 1

func _insert_block_card():
	patience_exhausted_count += 1
	var block_data = _pick_block_card()
	_apply_block_effect(block_data)

	# 生成阻断牌节点插入龙链
	var block_node = block_scene.instantiate()
	block_node.setup(block_data)
	table_manager.add_block_card_to_table(block_node)

	# 浮动提示
	_spawn_floating_number("客户出手！" + block_data.card_name, Color(0.95, 0.2, 0.2))
	_refresh_status()

func _pick_block_card() -> BlockCard:
	# 根据耐心耗尽次数决定可选强度池
	var pool = []
	if patience_exhausted_count <= 1:
		pool = ["BLOCK_ZERO_NEXT", "BLOCK_MINUS_MULTI", "BLOCK_DISCARD_HAND"]
	elif patience_exhausted_count <= 2:
		pool = ["BLOCK_MINUS_MULTI", "BLOCK_DISCARD_HAND", "BLOCK_RESET_MULTI", "BLOCK_MINUS_BREATH"]
	else:
		pool = ["BLOCK_RESET_MULTI", "BLOCK_MINUS_BREATH", "BLOCK_DISCARD_HAND",
			"BLOCK_MINUS_MULTI", "BLOCK_ZERO_NEXT", "BLOCK_RESET_BREATH"]

	var effect_id = pool[randi() % pool.size()]
	return _make_block_card(effect_id)

func _make_block_card(effect_id: String) -> BlockCard:
	var data = BlockCard.new()
	data.effect_id = effect_id
	match effect_id:
		"BLOCK_ZERO_NEXT":
			data.card_name = "冷眼旁观"
			data.intensity = BlockCard.Intensity.LOW
		"BLOCK_MINUS_MULTI":
			data.card_name = "挑三拣四"
			data.intensity = BlockCard.Intensity.MID
		"BLOCK_DISCARD_HAND":
			data.card_name = "左推右挡"
			data.intensity = BlockCard.Intensity.MID
		"BLOCK_RESET_MULTI":
			data.card_name = "嫌贫爱富"
			data.intensity = BlockCard.Intensity.HIGH
		"BLOCK_MINUS_BREATH":
			data.card_name = "横加刁难"
			data.intensity = BlockCard.Intensity.HIGH
		"BLOCK_RESET_BREATH":
			data.card_name = "百般挑剔"
			data.intensity = BlockCard.Intensity.EXTREME
	return data

func _apply_block_effect(data: BlockCard):
	match data.effect_id:
		"BLOCK_RESET_MULTI":
			table_manager.chain_multiplier = 1.0
			table_manager.consecutive_same_suit = 0
		"BLOCK_MINUS_MULTI":
			table_manager.chain_multiplier = max(1.0, table_manager.chain_multiplier - 0.5)
		"BLOCK_MINUS_BREATH":
			current_breath -= 1
		"BLOCK_DISCARD_HAND":
			_discard_random_hand_card()
		"BLOCK_ZERO_NEXT":
			table_manager.next_card_value_zero = true
		"BLOCK_RESET_BREATH":
			table_manager.chain_multiplier = 1.0
			table_manager.consecutive_same_suit = 0
			current_breath -= 1
	_check_breath()

func _check_breath():
	_refresh_status()
	if current_breath <= 0:
		_game_over()

func _game_over():
	print("💀 气口耗尽！游戏结束！总计：", total_money, " 贯")
	_spawn_floating_number("气口耗尽！游戏结束！", Color(0.95, 0.2, 0.2))
	# 暂时禁止继续出牌
	get_tree().paused = true

func _discard_random_hand_card():
	if hand_ui.cards_in_hand.is_empty():
		return
	var idx = randi() % hand_ui.cards_in_hand.size()
	var card = hand_ui.cards_in_hand[idx]
	hand_ui.cards_in_hand.erase(card)
	card.queue_free()

func _execute_effect(data: BaseCard):
	match data.effect_id:
		"TEA_DRAW1":
			_draw_card_to_hand_with_anim()
		"TEA_BREATH1":
			current_breath = min(current_breath + 1, max_breath)
			_spawn_floating_number("气口+1", Color(0.2, 0.9, 0.3))
		"TEA_DRAW2_DISCARD1":
			_draw_card_to_hand_with_anim()
			_draw_card_to_hand_with_anim()
			_discard_random_hand_card()
		"TEA_BREATH2_WILDLINK":
			current_breath = min(current_breath + 2, max_breath)
			table_manager.next_card_wild_suit = true
			_spawn_floating_number("气口+2", Color(0.2, 0.9, 0.3))
		"TEA_DRAW3_BONUS500":
			_draw_card_to_hand_with_anim()
			_draw_card_to_hand_with_anim()
			_draw_card_to_hand_with_anim()
			table_manager.total_chain_value += 500
			_spawn_floating_number("+500 贯", Color(0.2, 0.9, 0.3))
		"POR_DOUBLE_RISK100":
			table_manager.last_card_value_multiplier = 2.0
			table_manager.next_non_por_penalty = 100
		"POR_MULTI_RISK200":
			table_manager.chain_multiplier += 0.5
			table_manager.break_penalty = 200
		"POR_TRIPLE_DISCARD1":
			table_manager.last_card_value_multiplier = 3.0
			_discard_random_hand_card()
		"POR_CHAIN_MULTI15":
			table_manager.total_chain_value = int(table_manager.total_chain_value * 1.5)
			_spawn_floating_number("龙链×1.5！", Color(0.2, 0.9, 0.3))
		"SILK_BURN_SETTLE":
			_burn_settle_from_hand()
		"SILK_WILD_NEXT":
			table_manager.next_card_wild_suit = true
			_spawn_floating_number("下一张视为同花色", Color(0.45, 0.20, 0.65))
		"SILK_SKIP_SETTLE":
			table_manager.skip_next_settle = true
		"INC_BURN_BLOCK":
			_burn_block_from_chain()
		"INC_BURN_SETTLE_BONUS":
			_burn_settle_bonus()
		"INC_BURN_RANDOM_SETTLE":
			deck_manager.burn_random_settle()

func _burn_settle_from_hand():
	for card in hand_ui.cards_in_hand:
		if card.card_data.is_settle_card():
			hand_ui.cards_in_hand.erase(card)
			card.queue_free()
			current_breath = min(current_breath + 1, max_breath)
			_spawn_floating_number("销毁结算牌！气口+1", Color(0.52, 0.31, 0.04))
			return

func _burn_block_from_chain():
	for card in table_manager.table_cards:
		if card is Area2D and card.get_script() and card.get_script().resource_path.contains("block_card"):
			table_manager.table_cards.erase(card)
			card.queue_free()
			_spawn_floating_number("阻断牌已销毁！", Color(0.52, 0.31, 0.04))
			table_manager._reposition_all_cards()
			return

func _burn_settle_bonus():
	for card in hand_ui.cards_in_hand:
		if card.card_data.is_settle_card():
			var bonus = card.card_data.base_value * 2
			table_manager.total_chain_value += bonus
			hand_ui.cards_in_hand.erase(card)
			card.queue_free()
			_spawn_floating_number("+" + str(bonus) + " 贯", Color(0.52, 0.31, 0.04))
			return
func _refresh_status():
	if status_bar:
		status_bar.update_display(
			current_breath,
			max_breath,
			table_manager.chain_multiplier,
			table_manager.total_chain_value,
			total_money
		)

func _handle_break_chain(card_node: Area2D):
	current_breath -= 1
	print("💨 气口消耗！剩余气口：", current_breath)
	table_manager.clear_table()
	hand_ui.cards_in_hand.erase(card_node)
	table_manager.add_card_to_table(card_node)
