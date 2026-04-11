extends Area2D

signal drag_started
signal drag_ended

var card_data: BaseCard
var target_position: Vector2
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO

const CARD_SCALE = 0.6 

func _ready():
	self.scale = Vector2(CARD_SCALE, CARD_SCALE)
	queue_redraw()

func _process(delta):
	if is_dragging:
		global_position = get_global_mouse_position() + drag_offset
	else:
		position = position.lerp(target_position, 15 * delta)

# 解决“粘着鼠标”：全局监听释放
func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed and is_dragging:
			is_dragging = false
			z_index = get_index() 
			
			# 简单粗暴的判定：如果拖到了屏幕中上方（Y坐标小于屏幕高度的 60%）
			var screen_h = get_viewport_rect().size.y
			if global_position.y < screen_h * 0.6:
				# 尝试出牌，呼叫 GameManager (假设 GameManager 挂载在 "/root/Game")
				var game_mgr = get_node("/root/Game") 
				if game_mgr.try_play_card(self):
					# 出牌成功，不需要自己发信号了，GameManager 已经接管了这个节点
					return 
			
			# 没拖到判定区，或者接龙失败，发信号让 HandUI 把牌吸回去
			drag_ended.emit()

# 解决“重叠选中”：拦截输入事件
func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# 核心：拦截点击，不让下层卡牌接收到输入
			get_viewport().set_input_as_handled() 
			is_dragging = true
			drag_offset = global_position - get_global_mouse_position()
			z_index = 999 # 拖拽时置顶显示
			drag_started.emit()

# 渲染卡牌数据与颜色
func setup(data: BaseCard):
	card_data = data
	
	# 中式配色
	var suit_name = ""
	var suit_color = Color.BLACK
	match data.suit:
		BaseCard.Suit.TEA: suit_name = "茶"; suit_color = Color(0.27, 0.45, 0.33)
		BaseCard.Suit.PORCELAIN: suit_name = "瓷"; suit_color = Color(0.35, 0.45, 0.60)
		BaseCard.Suit.SILK: suit_name = "绸"; suit_color = Color(0.65, 0.50, 0.25)
		BaseCard.Suit.INCENSE: suit_name = "香"; suit_color = Color(0.45, 0.35, 0.55)

	# 1. 名称 (核心标题：48号)
	$NameLabel.text = data.card_name
	$NameLabel.add_theme_font_size_override("font_size", 48)
	
	# 2. 点数数字 (大宋货品等阶：110号)
	$NumberLabel.text = str(data.rank)
	$NumberLabel.add_theme_font_size_override("font_size", 110)
	$NumberLabel.add_theme_color_override("font_color", suit_color)
	
	# 3. 行当标签 (40号)
	$SuitLabel.text = "【" + suit_name + "】"
	$SuitLabel.add_theme_font_size_override("font_size", 40)
	$SuitLabel.add_theme_color_override("font_color", suit_color)

	# 4. 效果内容 (次要核心：40号 - 比名称略小)
	var effect_text = ""
	match data.suit:
		BaseCard.Suit.TEA: effect_text = "提神：连续两张可回气"
		BaseCard.Suit.PORCELAIN: effect_text = "易碎：断龙则倒扣资金"
		BaseCard.Suit.SILK: effect_text = "丝滑：品阶允许 ±2 接龙"
		BaseCard.Suit.INCENSE: effect_text = "熏除：可销毁一张废牌"
	
	# 强制换行对齐效果内容
	$EffectLabel.text = "效果：\n" + effect_text + "\n价值：" + str(data.base_value) + " 贯"
	$EffectLabel.add_theme_font_size_override("font_size", 40)

	# 5. 风味描述 (背景文字：32号)
	$DescLabel.text = data.description
	$DescLabel.add_theme_font_size_override("font_size", 32)
	$DescLabel.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2))

	# 黑色对比
	for l in [$NameLabel, $EffectLabel]:
		l.add_theme_color_override("font_color", Color.BLACK)

func _draw():
	var shape_rect = $CollisionShape2D.shape.get_rect()
	draw_rect(shape_rect, Color.BLACK, false, 5.0)
