@onready var hand_ui = get_node_or_null("HandUI") 
@onready var table_manager = $TableManager
@onready var deck_manager = $DeckManager
@onready var draw_pile_ui = $DrawPileUI

func _ready():
	if hand_ui == null:
		# 如果报错，请去编辑器看 HandUI 的名字是不是真的叫 HandUI
		push_error("错误：在主场景找不到 HandUI 节点！请检查路径。")
		return
	
	current_breath = max_breath
	deck_manager.init_deck()
	for i in range(5):
		_draw_card_to_hand_with_anim()

# 统一补牌函数名，修复报错 
func _draw_card_to_hand_with_anim():
	var data = deck_manager.draw_one_card()
	if data:
		var new_card = hand_ui.card_scene.instantiate()
		new_card.setup(data)
		# 传入牌堆的全局坐标作为动画起点 
		hand_ui.add_card_with_animation(new_card, draw_pile_ui.global_position)
		draw_pile_ui.update_pile_view(deck_manager.draw_pile.size())

func try_play_card(card_node: Area2D) -> bool:
	var card_data = card_node.card_data
	var last_card = table_manager.get_last_card_data()
	
	if card_data.can_link_to(last_card): # 严格判定 
		hand_ui.cards_in_hand.erase(card_node)
		table_manager.add_card_to_table(card_node)
		_draw_card_to_hand_with_anim() # 成功才补牌 [cite: 6]
		return true
	else:
		_handle_break_chain(card_node) # 失败扣气口 [cite: 28]
		return false

func _handle_break_chain(card_node: Area2D):
	current_breath -= 1
	table_manager.clear_table() # 断龙清场 [cite: 28]
	hand_ui.cards_in_hand.erase(card_node)
	table_manager.add_card_to_table(card_node) # 强行作为新龙头
