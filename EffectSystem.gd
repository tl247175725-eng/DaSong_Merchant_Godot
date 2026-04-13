extends Node

var game_manager: Node
var table_manager: Node
var hand_ui: Node
var deck_manager: Node

func setup(gm, tm, hu, dm):
	game_manager = gm
	table_manager = tm
	hand_ui = hu
	deck_manager = dm

func execute(effect_id: String):
	match effect_id:
		"NONE": pass
		"TEA_DRAW1": tea_draw1()
		"TEA_BREATH1": tea_breath1()
		"TEA_DRAW2_DISCARD1": tea_draw2_discard1()
		"TEA_BREATH2_WILDLINK": tea_breath2_wildlink()
		"TEA_DRAW3_BONUS500": tea_draw3_bonus500()
		"POR_DOUBLE_RISK100": por_double_risk100()
		"POR_MULTI_RISK200": por_multi_risk200()
		"POR_TRIPLE_DISCARD1": por_triple_discard1()
		"POR_CHAIN_MULTI15": por_chain_multi15()
		"SILK_BURN_SETTLE": silk_burn_settle()
		"SILK_WILD_NEXT": silk_wild_next()
		"SILK_SKIP_SETTLE": silk_skip_settle()
		"INC_BURN_BLOCK": inc_burn_block()
		"INC_BURN_SETTLE_BONUS": inc_burn_settle_bonus()
		"INC_BURN_RANDOM_SETTLE": inc_burn_random_settle()
		"SILK_CONVERT_BLOCK": silk_convert_block()
		"POR_DOUBLE_MULTI_BREATH": por_double_multi_breath()
		"TEA_CHAIN_BONUS": tea_chain_bonus()
		_:
			print("⚠️ 未实现效果：", effect_id)

# ===== 茶系 =====
func tea_draw1():
	game_manager._draw_card_to_hand_with_anim()
	game_manager._spawn_floating_number("抽1张牌", Color(0.11, 0.62, 0.46))

func tea_breath1():
	game_manager.current_breath = min(game_manager.current_breath + 1, game_manager.max_breath)
	game_manager._spawn_floating_number("气口+1", Color(0.11, 0.62, 0.46))
	game_manager._refresh_status()

func tea_draw2_discard1():
	game_manager._draw_card_to_hand_with_anim()
	game_manager._draw_card_to_hand_with_anim()
	game_manager._discard_random_hand_card()
	game_manager._spawn_floating_number("抽2张，丢1张", Color(0.11, 0.62, 0.46))

func tea_breath2_wildlink():
	game_manager.current_breath = min(game_manager.current_breath + 2, game_manager.max_breath)
	table_manager.next_card_wild_suit = true
	_convert_next_hand_card_to_suit(int(BaseCard.Suit.TEA))
	game_manager._spawn_floating_number("气口+2 下一张变为茶色普通牌", Color(0.11, 0.62, 0.46))
	game_manager._refresh_status()

func tea_draw3_bonus500():
	game_manager._draw_card_to_hand_with_anim()
	game_manager._draw_card_to_hand_with_anim()
	game_manager._draw_card_to_hand_with_anim()
	table_manager.total_chain_value += 500
	game_manager._spawn_floating_number("抽3张 +500贯", Color(0.11, 0.62, 0.46))

# ===== 瓷系 =====
func por_double_risk100():
	table_manager.last_card_value_multiplier = 2.0
	table_manager.next_non_por_penalty = 100
	game_manager._spawn_floating_number("本张×2 风险+100", Color(0.09, 0.37, 0.65))

func por_multi_risk200():
	table_manager.chain_multiplier += 0.5
	table_manager.break_penalty = 200
	game_manager._spawn_floating_number("倍率+0.5 断龙-200", Color(0.09, 0.37, 0.65))

func por_triple_discard1():
	table_manager.last_card_value_multiplier = 3.0
	game_manager._discard_random_hand_card()
	game_manager._spawn_floating_number("本张×3 丢1张手牌", Color(0.09, 0.37, 0.65))

func por_chain_multi15():
	table_manager.total_chain_value = int(table_manager.total_chain_value * 1.5)
	game_manager._spawn_floating_number("龙链×1.5！", Color(0.09, 0.37, 0.65))

# ===== 绸系 =====
func silk_burn_settle():
	for card in hand_ui.cards_in_hand:
		if card.card_data.is_settle_card():
			hand_ui.cards_in_hand.erase(card)
			card.queue_free()
			game_manager.current_breath = min(game_manager.current_breath + 1, game_manager.max_breath)
			game_manager._spawn_floating_number("销毁结算牌 气口+1", Color(0.45, 0.20, 0.65))
			game_manager._refresh_status()
			return
	game_manager._spawn_floating_number("手中无结算牌", Color(0.5, 0.5, 0.5))

func silk_wild_next():
	table_manager.next_card_wild_suit = true
	_convert_next_hand_card_to_suit(int(BaseCard.Suit.SILK))
	game_manager._spawn_floating_number("下一张变为绸色普通牌", Color(0.45, 0.20, 0.65))


func silk_skip_settle():
	table_manager.skip_next_settle = true
	game_manager._spawn_floating_number("跳过下一次结算惩罚", Color(0.45, 0.20, 0.65))

# ===== 香系 =====
func inc_burn_block():
	for card in table_manager.table_cards:
		if card.get_script() != null and "block_card" in card.get_script().resource_path:
			table_manager.table_cards.erase(card)
			card.queue_free()
			table_manager._reposition_all_cards()
			game_manager._spawn_floating_number("阻断牌已销毁！", Color(0.52, 0.31, 0.04))
			return
	game_manager._spawn_floating_number("龙链中无阻断牌", Color(0.5, 0.5, 0.5))

func inc_burn_settle_bonus():
	for card in hand_ui.cards_in_hand:
		if card.card_data.is_settle_card():
			var bonus = card.card_data.base_value * 2
			table_manager.total_chain_value += bonus
			hand_ui.cards_in_hand.erase(card)
			card.queue_free()
			game_manager._spawn_floating_number("+" + str(bonus) + "贯", Color(0.52, 0.31, 0.04))
			return

func inc_burn_random_settle():
	deck_manager.burn_random_settle()
	game_manager._spawn_floating_number("销毁牌库结算牌", Color(0.52, 0.31, 0.04))
	
func _convert_next_hand_card_to_suit(suit: int):
	if game_manager.hand_ui.cards_in_hand.is_empty():
		return
	var target = game_manager.hand_ui.cards_in_hand.back()
	if target == null or not is_instance_valid(target):
		return
	print("野性转化：", target.card_data.card_name, " 花色 ", target.card_data.suit, " -> ", suit)
	target.card_data.suit = suit
	target.card_data.card_type = BaseCard.CardType.NORMAL
	target.card_data.effect_id = "NONE"
	target.setup(target.card_data)
	# 强制手牌重新排序和渲染
	game_manager.hand_ui._sort_hand()
	game_manager.hand_ui._reposition_hand()
	print("转化完成，现在花色：", target.card_data.suit)
func silk_convert_block():
	for card in table_manager.table_cards:
		if card.get_script() != null and "block_card" in card.get_script().resource_path:
			# 把阻断牌从龙链移除，不做替换（简化版）
			table_manager.table_cards.erase(card)
			card.queue_free()
			table_manager._reposition_all_cards()
			game_manager._spawn_floating_number("阻断牌已转化！", Color(0.45, 0.20, 0.65))
			return
	game_manager._spawn_floating_number("龙链中无阻断牌", Color(0.5, 0.5, 0.5))

func por_double_multi_breath():
	table_manager.last_card_value_multiplier = 2.0
	table_manager.chain_multiplier *= 2.0
	game_manager.current_breath -= 1
	game_manager._spawn_floating_number("本张×2 倍率翻倍 气口-1", Color(0.09, 0.37, 0.65))
	game_manager._check_breath()
	game_manager._refresh_status()

func tea_chain_bonus():
	# 检查龙链末尾前两张是否都是茶
	var cards = table_manager.table_cards
	if cards.size() >= 2:
		var last = cards[cards.size() - 1]
		var prev = cards[cards.size() - 2]
		if last.get("card_data") != null and prev.get("card_data") != null:
			if last.card_data.suit == BaseCard.Suit.TEA and prev.card_data.suit == BaseCard.Suit.TEA:
				game_manager._draw_card_to_hand_with_anim()
				game_manager._draw_card_to_hand_with_anim()
				game_manager.current_breath = min(game_manager.current_breath + 1, game_manager.max_breath)
				game_manager._spawn_floating_number("茶系连击！抽2张 气口+1", Color(0.11, 0.62, 0.46))
				game_manager._refresh_status()
				return
	game_manager._spawn_floating_number("需连续两张茶牌", Color(0.5, 0.5, 0.5))
