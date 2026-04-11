# TableManager.gd
extends Control

@onready var card_container = $CardContainer
@onready var red_rope = $RedRope

var table_cards: Array = []
var cards_per_row = 8
var current_row_index = 0

func get_last_card_data() -> BaseCard:
	return table_cards.back().card_data if not table_cards.is_empty() else null

func add_card_to_table(card_node: Node2D):
	if card_node.get_parent():
		card_node.get_parent().remove_child(card_node)
	card_container.add_child(card_node)
	
	var total_count = table_cards.size()
	var row = total_count / cards_per_row
	var col = total_count % cards_per_row
	
	# 满行触发上移：让旧牌像“流水席”一样滑走 [cite: 6]
	if row > current_row_index:
		current_row_index = row
		var shift_tween = create_tween()
		shift_tween.tween_property(card_container, "position:y", card_container.position.y - 200, 0.4)

	# 目标：始终在屏幕中心区域生成
	var viewport_center_x = get_viewport_rect().size.x / 2
	var start_x = - (cards_per_row * 150) / 2 # 以 150 间距水平居中
	var target_pos = Vector2(start_x + col * 150, 0) # y轴由容器的 shift 控制
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(card_node, "position", target_pos, 0.4).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(card_node, "scale", Vector2(0.5, 0.5), 0.4)
	
	table_cards.append(card_node)
	_update_red_rope()

func _update_red_rope():
	red_rope.clear_points()
	for card in table_cards:
		red_rope.add_point(card.position)

func clear_table():
	for card in table_cards:
		card.queue_free()
	table_cards.clear()
	current_row_index = 0
	card_container.position.y = 0 # 容器位置重置
	red_rope.clear_points()
