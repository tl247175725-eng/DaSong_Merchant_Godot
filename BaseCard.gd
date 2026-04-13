extends Resource
class_name BaseCard

enum CardType { NORMAL, EFFECT, SETTLE }
enum Suit { TEA, PORCELAIN, SILK, INCENSE, NONE }

@export var card_id: String
@export var card_name: String
@export var suit: Suit = Suit.NONE
@export var rank: int = 1
@export var base_value: int = 10
@export var card_type: CardType = CardType.NORMAL
@export var effect_id: String = "NONE"
@export var description: String

# 接龙判定：任何牌都能接任何牌
func can_link_to(_last_card: BaseCard) -> bool:
	return true

# 是否是结算牌
func is_settle_card() -> bool:
	return card_type == CardType.SETTLE

# 是否同花色
func same_suit_as(other: BaseCard) -> bool:
	if other == null:
		return false
	return self.suit == other.suit

func get_quality() -> String:
	if rank <= 5:
		return "low"
	elif rank <= 10:
		return "mid"
	else:
		return "high"

func is_premium() -> bool:
	return rank > 10
