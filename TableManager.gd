# TableManager.gd
extends Control

@onready var card_container = $CardContainer
@onready var red_rope = $RedRope
@onready var hint_box = $HintBox # 确保你在编辑器里给 HintBox 设好了尺寸和中心锚点

var table_cards: Array = []
var cards_per_row: int = 8
var current_row_index: int = 0

func _ready():
	# 将虚框强行对齐到屏幕正中心
	var screen_center = get_viewport_rect().size / 2.0
	hint_box.global_position = screen_center - (hint_box.size / 2.0)
	hint_box.visible = true 

func get_last_card_data() -> BaseCard:
	return table_cards.back().card_data if not table_cards.is_empty() else null

func add_card_to_table(card_node: Node2D):
	if hint_box.visible: hint_box.visible = false 
	
	# 1. 转换“家”：从 HandUI 挪到成交区
	if card_node.get_parent():
		card_node.get_parent().remove_child(card_node)
	card_container.add_child(card_node)
	
	# 2. 计算位置：基于屏幕中心的“之”字型排列
	var total_count = table_cards.size()
	var row = int(total_count / cards_per_row)
	var col = total_count % cards_per_row
	
	if row > current_row_index:
		current_row_index = row
		create_tween().tween_property(card_container, "position:y", card_container.position.y - 220, 0.4)

	# 关键修复：计算目标全局坐标，再转回局部坐标
	var screen_center = get_viewport_rect().size / 2.0
	var spacing_x = 160.0 
	var start_x = screen_center.x - ((cards_per_row - 1) * spacing_x / 2.0)
	
	# 每一张牌的目标位置
	var target_global_pos = Vector2(start_x + col * spacing_x, screen_center.y - 150)
	
	# 动画：从目前手上的位置飞到目标位置
	var tween = create_tween().set_parallel(true)
	# 使用 global_position 确保“指哪飞哪”，不受父节点干扰
	tween.tween_property(card_node, "global_position", target_global_pos, 0.4).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(card_node, "scale", Vector2(0.5, 0.5), 0.4)
	
	table_cards.append(card_node)
	_update_red_rope()

func _update_red_rope():
	if not red_rope: return
	red_rope.clear_points()
	# Line2D 使用的是相对于 TableManager 的局部坐标
	for card in table_cards:
		red_rope.add_point(card.position)

func clear_table():
	for card in table_cards:
		if is_instance_valid(card): card.queue_free()
	table_cards.clear()
	current_row_index = 0
	card_container.position = Vector2.ZERO
	hint_box.visible = true
	if red_rope: red_rope.clear_points()
