extends Node

var active_chain: Array[BaseCard] = []
var total_value: int = 0
var multiplier: float = 1.0
var breath: int = 3 # 气口上限

func try_play_card(card: BaseCard) -> bool:
	var last_card = active_chain.back() if not active_chain.is_empty() else null
	
	if card.can_link_to(last_card):
		active_chain.append(card)
		calculate_chain_value()
		return true
	else:
		consume_breath()
		return false

func calculate_chain_value():
	# 基础逻辑：价值累加 * (1 + 长度 * 0.1)
	var base_sum = 0
	for c in active_chain:
		base_sum += c.base_value
	
	total_value = base_sum * (1.0 + active_chain.size() * 0.1)
	print("当前成交额：", total_value, " 贯")

func consume_breath():
	breath -= 1
	if breath <= 0:
		print("气口耗尽！强行结算！")
		# 触发结算逻辑
