extends Area2D

signal drag_started
signal drag_ended
signal table_card_pressed  # 接龙区牌被点击

var card_data: BaseCard
var target_position: Vector2
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var is_on_table: bool = false
var is_hovered: bool = false
var is_expanded: bool = false  # 点击弹出状态
var peek_width: float = -1.0  # -1表示完整显示，否则只画左侧这么宽
var is_wild_marked: bool = false

const CARD_SCALE = 0.6

# 花色基础颜色
const SUIT_COLORS = {
	BaseCard.Suit.TEA:       Color(0.11, 0.62, 0.46),
	BaseCard.Suit.PORCELAIN: Color(0.09, 0.37, 0.65),
	BaseCard.Suit.SILK:      Color(0.45, 0.20, 0.65),  # 紫
	BaseCard.Suit.INCENSE:   Color(0.52, 0.31, 0.04),
	BaseCard.Suit.NONE:      Color(0.3, 0.3, 0.3),
}
const SETTLE_COLOR = Color(0.89, 0.29, 0.29)

# 呼吸灯状态
var border_color: Color = Color(0.3, 0.3, 0.3)
var border_width: float = 4.0
var breathe_tween: Tween = null

# 呼吸灯参数（用_process驱动，更稳定）
var breathe_time: float = 0.0
var breathe_speed: float = 1.0
var glow_color_base: Color = Color(0.3, 0.3, 0.3)  # 固定边框颜色
var glow_alpha: float = 0.0  # 只让透明度呼吸
var use_process_breathe: bool = false
var shake_enabled: bool = false
var shake_time: float = 0.0

func _ready():
	self.scale = Vector2(CARD_SCALE, CARD_SCALE)
	queue_redraw()
	set_process(true)

func _process(delta):
	if is_dragging:
		global_position = get_global_mouse_position() + drag_offset
	elif not is_expanded:
		# 只有未弹出状态才进行lerp，否则与tween打架
		position = position.lerp(target_position, 15 * delta)

		# 呼吸灯：只有在接龙区才更新
	if use_process_breathe and is_on_table:
		breathe_time += delta * breathe_speed
		glow_alpha = (sin(breathe_time) + 1.0) / 2.0
		queue_redraw()

	# 颜抖
	if shake_enabled and not is_expanded:
		shake_time += delta
		var shake_x = sin(shake_time * 25.0) * 2.0
		position.x = target_position.x + shake_x

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed:
			# 鼠标左键松开：拖拽结束 or 接龙牌收回
			if is_dragging:
				is_dragging = false
				z_index = get_index()
				if is_on_table:
					drag_ended.emit()
					return
				var screen_h = get_viewport_rect().size.y
				if global_position.y < screen_h * 0.6:
					var game_mgr = get_node("/root/Game")
					if game_mgr.try_play_card(self):
						is_on_table = true
						return
				drag_ended.emit()
			if is_on_table and is_expanded:
				_collapse_card()

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if is_on_table:
				# 发信号给TableManager统一处理，不自己处理
				table_card_pressed.emit(self)
			else:
				get_viewport().set_input_as_handled()
				is_dragging = true
				drag_offset = global_position - get_global_mouse_position()
				z_index = 999
				drag_started.emit()
		else:
			# 鼠标松开：接龙区的牌收回
			if is_on_table and is_expanded:
				_collapse_card()

func _expand_card():
	if is_expanded:
		return
	is_expanded = true
	z_index = 999
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "position", target_position + Vector2(0, -120), 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(0.6, 0.6), 0.15)

func _collapse_card():
	is_expanded = false
	z_index = get_index()
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "position", target_position, 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(0.5, 0.5), 0.15)

func setup(data: BaseCard):
	card_data = data

	var suit_color = SUIT_COLORS.get(data.suit, Color(0.3, 0.3, 0.3))
	var is_settle = data.is_settle_card()

	var suit_name = ""
	match data.suit:
		BaseCard.Suit.TEA:       suit_name = "茶"
		BaseCard.Suit.PORCELAIN: suit_name = "瓷"
		BaseCard.Suit.SILK:      suit_name = "绸"
		BaseCard.Suit.INCENSE:   suit_name = "香"

	var quality_text = _get_quality_text(data)
	var type_text = _get_type_text(data)
	var effect_text = _get_effect_description(data.effect_id)

	# 花色标签
	$SuitLabel.text = suit_name
	$SuitLabel.add_theme_color_override("font_color", suit_color)
	$SuitLabel.add_theme_font_size_override("font_size", 36)

	# 品质标签
	$QualityLabel.text = quality_text
	$QualityLabel.add_theme_color_override("font_color", suit_color)
	$QualityLabel.add_theme_font_size_override("font_size", 24)

	# 货物名称
	$NameLabel.text = data.card_name
	$NameLabel.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
	$NameLabel.add_theme_font_size_override("font_size", 36)

	# 基础价值
	$NumberLabel.text = str(data.base_value) + " 贯"
	$NumberLabel.add_theme_color_override("font_color", suit_color)
	$NumberLabel.add_theme_font_size_override("font_size", 52)

	# 卡牌类型 + 效果描述
	if is_settle:
		$EffectLabel.text = type_text + "\n" + effect_text
		$EffectLabel.add_theme_color_override("font_color", SETTLE_COLOR)
		$EffectLabel.add_theme_font_size_override("font_size", 32)
	else:
		$EffectLabel.text = type_text + ("\n" + effect_text if effect_text != "" else "")
		$EffectLabel.add_theme_color_override("font_color", suit_color)
		$EffectLabel.add_theme_font_size_override("font_size", 32)

	# 风味描述
	$DescLabel.text = data.description
	$DescLabel.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	$DescLabel.add_theme_font_size_override("font_size", 24)

	# 手牌不启动呼吸灯，进入接龙区才启动
	use_process_breathe = false
	border_color = suit_color if not is_settle else SETTLE_COLOR

	# 极品牌动态添加祥云标签
	var old_cloud = get_node_or_null("CloudLabel")
	if old_cloud:
		old_cloud.queue_free()
	if data.rank > 10:
		var cloud_label = Label.new()
		cloud_label.text = "☁"
		cloud_label.position = Vector2(-163, -110)
		cloud_label.add_theme_font_size_override("font_size", 28)
		cloud_label.add_theme_color_override("font_color", suit_color if not is_settle else SETTLE_COLOR)
		cloud_label.name = "CloudLabel"
		add_child(cloud_label)

	queue_redraw()

func _start_breathe(data: BaseCard):
	if breathe_tween:
		breathe_tween.kill()

	var suit_color = SUIT_COLORS.get(data.suit, Color(0.3, 0.3, 0.3))
	var is_settle = data.is_settle_card()
	var is_effect = (data.card_type == BaseCard.CardType.EFFECT)

	if is_settle:
		# 结算牌：红色强呼吸 + 颤抖
		_breathe_settle()
	elif is_effect:
		# 效果牌：花色强呼吸，频率更快
		_breathe_loop(suit_color, 0.8, 2.5, 1.5)
	else:
		# 普通牌：花色弱呼吸
		_breathe_loop(suit_color, 0.4, 4.0, 4.0)

func _breathe_loop(color: Color, _intensity: float, _duration_in: float, _duration_out: float):
	glow_color_base = color
	border_color = color
	border_width = 5.0
	breathe_speed = 1.5
	use_process_breathe = true
	shake_enabled = false

func _breathe_settle():
	glow_color_base = SETTLE_COLOR
	border_color = SETTLE_COLOR
	border_width = 7.0
	breathe_speed = 3.0
	use_process_breathe = true
	shake_enabled = true
	shake_time = 0.0

func _set_border_color(color: Color):
	border_color = color
	queue_redraw()

func _get_quality_text(data: BaseCard) -> String:
	if data.card_type == BaseCard.CardType.SETTLE:
		return "极\n品"
	if data.rank <= 5:
		return "低\n品"
	elif data.rank <= 10:
		return "精\n品"
	else:
		return "极\n品"

func _get_type_text(data: BaseCard) -> String:
	match data.card_type:
		BaseCard.CardType.NORMAL: return "普通"
		BaseCard.CardType.EFFECT: return "效果"
		BaseCard.CardType.SETTLE: return "结算"
	return ""

func _get_effect_description(effect_id: String) -> String:
	match effect_id:
		"NONE": return ""
		"TEA_DRAW1": return "打出时抽1张牌"
		"TEA_BREATH1": return "打出时回复1点气口"
		"TEA_PEEK3": return "看牌库顶3张，选1张入手"
		"TEA_DRAW2_DISCARD1": return "抽2张牌，丢弃1张手牌"
		"TEA_CHAIN_BONUS": return "连续两张茶牌时\n额外抽2张并回1气口"
		"TEA_BREATH2_WILDLINK": return "回复2点气口\n下一张牌视为同花色"
		"TEA_DRAW3_BONUS500": return "抽3张牌\n龙链总价值+500贯"
		"SETTLE_TEA": return "气口-1\n但结算金额×1.5"
		"POR_DOUBLE_RISK100": return "本张价值×2\n但下一张非瓷牌倒扣100贯"
		"POR_MULTI_RISK200": return "龙链倍率+0.5\n断龙时倒扣200贯"
		"POR_TRIPLE_DISCARD1": return "本张价值×3\n但随机丢弃1张手牌"
		"POR_CHAIN_BONUS100": return "龙链所有瓷牌价值+100贯"
		"POR_DOUBLE_MULTI_BREATH": return "本张价值×2且倍率翻倍\n但气口-1"
		"POR_CHAIN_MULTI15": return "龙链当前总价值×1.5"
		"POR_TRIPLE_DRAW_RISK500": return "本张价值×3且抽1张\n断龙时倒扣500贯"
		"SETTLE_POR": return "结算金额×0.3\n下一条龙起始倍率×3"
		"SILK_PUSH_SETTLE": return "将1张结算牌压入牌库底部"
		"SILK_BURN_SETTLE": return "销毁1张结算牌，回1气口"
		"SILK_WILD_NEXT": return "下一张牌视为同花色"
		"SILK_DRAW2_BURN": return "抽2张牌\n可选择销毁其中结算牌"
		"SILK_SKIP_SETTLE": return "跳过下一张结算牌的惩罚"
		"SILK_CONVERT_BLOCK": return "将1张客户阻断牌转为普通牌"
		"SILK_BURN_ALL_SETTLE": return "销毁手中所有结算牌\n每销毁1张回1气口"
		"SETTLE_SILK": return "手牌全部丢弃重抽5张\n结算金额不打折"
		"INC_BURN_DRAW2": return "销毁手中1张任意牌\n抽2张牌"
		"INC_BURN_BLOCK": return "销毁1张客户阻断牌或诅咒牌"
		"INC_BURN_SETTLE_BONUS": return "销毁1张结算牌\n龙链价值+该牌价值×2"
		"INC_BURN_RANDOM_SETTLE": return "随机销毁牌库中1张结算牌"
		"INC_CONVERT_SETTLE": return "将龙链中1张结算牌变为普通牌"
		"INC_BURN_ALL_NEGATIVE": return "销毁所有负面牌\n每张龙链价值+200贯"
		"INC_CLEAR_ALL_BLOCK": return "清除龙链中所有阻断牌效果\n龙链倍率+1"
		"SETTLE_INC": return "结算金额×2\n但牌库顶压入2张诅咒牌"
		_: return ""

func _draw():
	if card_data == null:
		return
	var shape_rect = $CollisionShape2D.shape.get_rect()

# 手牌：静态边框，画在外侧不被子节点背景压住
	if not is_on_table:
		var suit_color = SUIT_COLORS.get(card_data.suit, Color(0.3, 0.3, 0.3))
		var c = SETTLE_COLOR if card_data.is_settle_card() else suit_color
		var w = 4.0
		var outer = shape_rect.grow(w * 0.5)
		draw_rect(outer, c, false, w)
		# 极品牌画祥云
		if card_data.rank > 10:
			_draw_cloud(Vector2(-167, -140))
		return
	# 极品牌接龙区也画祥云
	if card_data.rank > 10:
		_draw_cloud(Vector2(-167, -140))
	# 接龙区：光晕 + 主边框
	if use_process_breathe and glow_alpha > 0.01:
		var glow_steps = 10
		for s in range(1, glow_steps + 1):
			var expand = s * 5.0
			var falloff = 1.0 - float(s) / float(glow_steps + 1)
			var alpha = glow_alpha * falloff * falloff * 0.6
			var gc = Color(glow_color_base.r, glow_color_base.g, glow_color_base.b, alpha)
			draw_rect(shape_rect.grow(expand), gc, false, 3.0)
	draw_rect(shape_rect, border_color, false, border_width)

func _draw_cloud(pos: Vector2):
	var suit_color = SUIT_COLORS.get(card_data.suit, Color(0.3, 0.3, 0.3))
	if card_data.is_settle_card():
		suit_color = SETTLE_COLOR
	var c = Color(suit_color.r, suit_color.g, suit_color.b, 1.0)
	var s = 14.0
	draw_circle(pos + Vector2(0, 0), s * 0.7, c)
	draw_circle(pos + Vector2(s * 0.8, -s * 0.3), s * 0.55, c)
	draw_circle(pos + Vector2(-s * 0.8, -s * 0.3), s * 0.55, c)
	draw_circle(pos + Vector2(s * 0.4, -s * 0.75), s * 0.45, c)
	draw_circle(pos + Vector2(-s * 0.4, -s * 0.75), s * 0.45, c)
	draw_rect(Rect2(pos + Vector2(-s * 1.0, -s * 0.1), Vector2(s * 2.0, s * 0.4)), c, true)
	
func set_wild_visual(enabled: bool):
	is_wild_marked = enabled
	if enabled:
		var tween = create_tween().set_loops(999)
		tween.tween_property(self, "position", target_position + Vector2(3, 0), 0.05)
		tween.tween_property(self, "position", target_position + Vector2(-3, 0), 0.05)
		tween.tween_property(self, "position", target_position, 0.05)
		breathe_tween = tween
	else:
		if breathe_tween:
			breathe_tween.kill()
		position = target_position
	queue_redraw()
