extends Control

@onready var card_container = $CardContainer
@onready var red_rope = $RedRope
@onready var hint_box = $HintBox 

var table_cards: Array = []
var cards_per_row: int = 8

func _ready():
	# 强行将虚框对齐到屏幕物理中心
	var screen_center = get_viewport_rect().size / 2.0
	hint_box.global_position = screen_center - (hint_box.size / 2.0)
	hint_box.visible = true # 引导玩家放入首张货物 [cite: 6]

func get_last_card_data() -> BaseCard:
	return table_cards.back().card_data if not table_cards.is_empty() else null

func add_card_to_table(card_node: Node2D):
	if hint_box.visible: hint_box.visible = false 
	
	card_node.reparent(card_container)
	
	var total_count = table_cards.size()
	var col = total_count % cards_per_row
	var row = int(total_count / float(cards_per_row)) # 这里的 row 现在会被用到

	var screen_center = get_viewport_rect().size / 2.0
	var spacing_x = 160.0
	var start_x = screen_center.x - ((cards_per_row - 1) * spacing_x / 2.0)
	
	# 修改点：将 row 加入计算，这样放满 8 张后会自动下移
	var target_gp = Vector2(start_x + col * spacing_x, screen_center.y - 150 + (row * 200))
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(card_node, "global_position", target_gp, 0.4).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(card_node, "scale", Vector2(0.5, 0.5), 0.4)
	
	table_cards.append(card_node)
	_update_red_rope()

func _update_red_rope():
	if not red_rope: return
	red_rope.clear_points()
	for card in table_cards:
		red_rope.add_point(card.position)

func clear_table():
	for card in table_cards:
		if is_instance_valid(card): card.queue_free()
	table_cards.clear()
	hint_box.visible = true
	if red_rope: red_rope.clear_points()
