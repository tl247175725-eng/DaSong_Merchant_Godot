extends Resource
class_name BaseCard

enum CardType { GOODS, MANEUVER }
enum Suit { TEA, PORCELAIN, SILK, INCENSE, NONE }

@export var card_id: String
@export var card_name: String
@export var type: CardType = CardType.GOODS
@export var suit: Suit = Suit.NONE
@export var rank: int = 1 # 1-13
@export var base_value: int = 10
@export var description: String
@export var icon: Texture2D

# 核心判定逻辑：这张牌能不能接在 last_card 后面？
func can_link_to(last_card: BaseCard) -> bool:
	if self.type == CardType.MANEUVER: return true # 功能牌万能接入
	if last_card == null: return true # 第一张牌随便放
	
	# 货物牌规则：同花色 或 点数相邻
	var suit_match = (self.suit == last_card.suit)
	var rank_match = abs(self.rank - last_card.rank) <= 1
	
	# 绸缎特殊加成：点数跨度为2
	if self.suit == Suit.SILK or last_card.suit == Suit.SILK:
		rank_match = abs(self.rank - last_card.rank) <= 2
		
	return suit_match or rank_match
