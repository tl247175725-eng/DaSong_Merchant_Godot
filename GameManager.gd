# GameManager.gd
extends Node

@export var max_breath: int = 3 # 气口上限 (生命值) [cite: 28]
var current_breath: int

@onready var hand_ui = $HandUI
@onready var table_manager = $TableManager
@onready var deck_manager = $DeckManager
@onready var draw_pile_ui = $DrawPileUI

func _ready():
	current_breath = max_breath
	deck_manager.init_deck()
	
	# 开局发牌：初始 5 张，带动画 [cite: 41, 42]
	for i in range(5):
		_draw_card_to_hand_with_anim()

# 核心补牌逻辑：从右侧牌堆飞入手牌
func _draw_card_to_hand_with_anim():
	var data = deck_manager.draw_one_card()
	if data:
		var new_card = hand_ui.card_scene.instantiate()
		new_card.setup(data)
		# 从右侧牌堆 global_position 飞入 [cite: 66]
		hand_ui.add_card_with_animation(new_card, draw_pile_ui.global_position)
		draw_pile_ui.update_pile_view(deck_manager.draw_pile.size())

func try_play_card(card_node: Area2D) -> bool:
	var card_data = card_node.card_data
	var last_card = table_manager.get_last_card_data()
	
	# 严格判定：同行当或品阶相邻 [cite: 16]
	if card_data.can_link_to(last_card):
		# ✅ 成功：上桌、从手牌移除、结算
		hand_ui.cards_in_hand.erase(card_node)
		table_manager.add_card_to_table(card_node)
		
		# 只有成功接龙才补一张牌，维持“打一补一” [cite: 6]
		_draw_card_to_hand_with_anim()
		return true
	else:
		# ❌ 失败：消耗气口，断龙重置 [cite: 28]
		_handle_break_chain(card_node)
		return false

func _handle_break_chain(card_node: Area2D):
	current_breath -= 1
	# 报错修复：确保调用了 TableManager 的 clear_table
	table_manager.clear_table()
	# 把这张牌作为新龙的头牌，不补牌（因为它本身就是从手牌里扣的）
	hand_ui.cards_in_hand.erase(card_node)
	table_manager.add_card_to_table(card_node)
