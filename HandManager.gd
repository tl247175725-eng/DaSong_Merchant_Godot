extends Node
class_name HandManager

var hand_cards: Array[BaseCard] = []

# 添加卡牌并触发自动排序
func add_card(card: BaseCard):
	hand_cards.append(card)
	sort_hand()
	update_ui()

# CEO 要求的自动排序逻辑
func sort_hand():
	hand_cards.sort_custom(func(a, b):
		# 1. 优先按类型排（手腕牌在前）
		if a.type != b.type:
			return a.type < b.type
		# 2. 同类型按行当（花色）排
		if a.suit != b.suit:
			return a.suit < b.suit
		# 3. 同行当按品阶（点数）排
		return a.rank < b.rank
	)

func update_ui():
	# 这里后续连接你的 UI 渲染逻辑，让卡牌在屏幕上飞到正确位置
	print("手牌已自动理货：", hand_cards.map(func(c): return c.card_name))
