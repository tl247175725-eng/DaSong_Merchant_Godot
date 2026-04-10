extends Node2D

@export var card_scene: PackedScene = preload("res://card_ui.tscn")
@export var spacing: float = 220.0 

var cards_in_hand: Array = []
var deck: Array = []
var original_card_height: float = 0.0

func _ready():
	# 逻辑：先实例化一个临时卡牌来获取它的原始尺寸，或者直接指定你的设计高度
	# 假设你的卡牌场景根节点是一个 ColorRect 或 Panel
	var temp_card = card_scene.instantiate()
	original_card_height = temp_card.size.y 
	temp_card.queue_free() # 获取完就释放
	
	# 监听窗口缩放
	get_tree().root.size_changed.connect(_reposition_hand)
	_reposition_hand()

func _on_window_resized():
	# 获取当前真实视窗尺寸
	var screen_size = get_viewport_rect().size
	# X居中，Y上提至距离底部 350 像素（防止 531 高度的卡牌被切断）
	global_position = Vector2(screen_size.x / 2.0, screen_size.y - 350)
	update_hand_positions()

func init_deck():
	var raw_files = DirAccess.get_files_at("res://Resources/Cards/")
	for file in raw_files:
		if file.ends_with(".tres"):
			deck.append(load("res://Resources/Cards/" + file))
	deck.shuffle()

func test_draw_cards(count: int):
	for i in range(min(count, deck.size())):
		add_card_ui(deck.pop_back())

func add_card_ui(data: BaseCard):
	var new_card = card_scene.instantiate()
	add_child(new_card)
	new_card.setup(data)
	cards_in_hand.append(new_card)
	new_card.drag_ended.connect(update_hand_positions)
	update_hand_positions()

func update_hand_positions():
	var screen_width = get_viewport_rect().size.x
	var hand_count = cards_in_hand.size()
	
	# 动态间距逻辑：卡牌多于屏幕宽度 80% 时自动收缩
	var current_spacing = spacing
	var max_allowed_width = screen_width * 0.8
	if (hand_count * spacing) > max_allowed_width:
		current_spacing = max_allowed_width / hand_count
	
	var start_x = -(hand_count - 1) * current_spacing / 2.0
	for i in range(hand_count):
		var card = cards_in_hand[i]
		card.target_position = Vector2(start_x + i * current_spacing, 0)
		if not card.is_dragging:
			card.z_index = i
			move_child(card, i)
# hand_ui.gd 调整建议

func _reposition_hand():
	var screen_size = get_viewport_rect().size
	
	# 1. 计算缩放倍率 (保持 22% 的屏幕高度比例)
	var target_card_height = screen_size.y * 0.22 
	var scale_factor = target_card_height / original_card_height
	
	var cards = get_children()
	var card_count = cards.size()
	if card_count == 0: return
	
	# 定位手牌容器：紧贴底部
	self.position.y = screen_size.y - target_card_height - 20
	self.position.x = screen_size.x / 2
	
	# 2. 核心修复：重命名局部变量，避免 Shadowing 报错
	var card_width = 170 * scale_factor # 假设 170 是基准宽度
	var max_hand_width = screen_size.x * 0.85
	
	# 这里改名为 current_spacing 或 dynamic_spacing
	var dynamic_spacing = card_width * 1.1 
	
	# 如果牌太多，开始像“蜘蛛纸牌”一样挤压间距 [cite: 42]
	if (card_count * dynamic_spacing) > max_hand_width:
		dynamic_spacing = max_hand_width / card_count
			
	for i in range(card_count):
		var card = cards[i]
		card.scale = Vector2(scale_factor, scale_factor)
		
		# 使用新的变量名进行位移计算
		var offset_x = (i - (card_count - 1) / 2.0) * dynamic_spacing
		card.position.x = offset_x
		card.position.y = 0
