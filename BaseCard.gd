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
	if self.type == CardType.MANEUVER: return true 
	if last_card == null: return true 
	
	var suit_match = (self.suit == last_card.suit)
	var rank_match = abs(self.rank - last_card.rank) <= 1
	
	if self.suit == Suit.SILK or last_card.suit == Suit.SILK:
		rank_match = abs(self.rank - last_card.rank) <= 2
		
	return suit_match or rank_match # 确保这一行是完整的
