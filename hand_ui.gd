extends Node2D

# 1. 导出变量与场景配置
@export var card_scene: PackedScene = preload("res://card_ui.tscn")
@export var spacing: float = 220.0 # 默认间距

var cards_in_hand: Array = []
var original_card_height: float = 531.0 # 根据你的 card_ui.tscn (Source 137) 矩形高度预设

func _ready():
	# 安全检查：确保场景已正确加载
	if card_scene == null:
		push_error("合伙人！HandUI 里的 Card Scene 没赋值或路径失效！")
		return

	# 获取原始高度：由于你的卡牌是 Area2D，我们通过实例化后读取 CollisionShape 的尺寸
	var temp_card = card_scene.instantiate()
	var shape = temp_card.get_node("CollisionShape2D").shape
	if shape is RectangleShape2D:
		original_card_height = shape.size.y # 获取 531 这个数值
	temp_card.queue_free()
	
	# 监听窗口缩放并初始化
	get_tree().root.size_changed.connect(_reposition_hand)
	_reposition_hand()

# 进货逻辑：由 GameManager 调用
func add_card_ui(data: BaseCard):
	var new_card = card_scene.instantiate()
	add_child(new_card)
	new_card.setup(data) # 渲染卡牌数据
	cards_in_hand.append(new_card)
	
	# 绑定拖拽结束信号，让卡牌回位
	if new_card.has_signal("drag_ended"):
		new_card.drag_ended.connect(_reposition_hand)
	
	_reposition_hand()

# 核心：蜘蛛纸牌式自适应排版逻辑 [cite: 42, 66]
func _reposition_hand():
	var screen_size = get_viewport_rect().size
	var card_count = cards_in_hand.size()
	
	# 1. 计算缩放倍率：卡牌高度保持为屏幕总高度的 22%
	var target_card_height = screen_size.y * 0.22 
	var scale_factor = target_card_height / original_card_height
	
	# 2. 定位容器位置：紧贴屏幕底部，留出 20px 呼吸感
	self.position.y = screen_size.y - target_card_height - 20
	self.position.x = screen_size.x / 2 # 居中
	
	if card_count == 0: return

	# 3. 动态间距算法：当牌太多时自动挤压 [cite: 42]
	var base_card_width = 380.0 * scale_factor # 380 是你 card_ui 的原始宽度
	var max_hand_width = screen_size.x * 0.85  # 手牌最多占据 85% 屏幕宽
	var dynamic_spacing = base_card_width * 1.05 # 默认略有间隔
	
	if (card_count * dynamic_spacing) > max_hand_width:
		dynamic_spacing = max_hand_width / card_count
			
	# 4. 执行位移与缩放
	for i in range(card_count):
		var card = cards_in_hand[i]
		if card.is_dragging: continue # 拖拽时不更新它的位置
		
		card.scale = Vector2(scale_factor, scale_factor)
		
		# 以容器中心为基准计算偏移量
		var offset_x = (i - (card_count - 1) / 2.0) * dynamic_spacing
		card.target_position = Vector2(offset_x, 0)
		
		# 处理层级
		card.z_index = i
