extends Area2D

var card_data: BlockCard
var is_on_table: bool = false
var target_position: Vector2 = Vector2.ZERO
var is_expanded: bool = false

const INTENSITY_STYLES = {
	BlockCard.Intensity.LOW: {
		"bg": Color(0.17, 0.13, 0.13),
		"border": Color(0.37, 0.19, 0.19),
	},
	BlockCard.Intensity.MID: {
		"bg": Color(0.14, 0.09, 0.09),
		"border": Color(0.47, 0.12, 0.12),
	},
	BlockCard.Intensity.HIGH: {
		"bg": Color(0.11, 0.06, 0.06),
		"border": Color(0.64, 0.18, 0.18),
	},
	BlockCard.Intensity.EXTREME: {
		"bg": Color(0.08, 0.03, 0.03),
		"border": Color(0.76, 0.20, 0.20),
	},
}

const TEXT_COLOR = Color(0.97, 0.76, 0.76)  # 统一字迹颜色，不受强度影响

var border_color: Color = Color(0.64, 0.18, 0.18)
var bg_color: Color = Color(0.11, 0.06, 0.06)
var border_alpha: float = 0.6
var glow_time: float = 0.0

const CARD_SCALE = 0.5

func _ready():
	self.scale = Vector2(CARD_SCALE, CARD_SCALE)
	queue_redraw()

func _process(delta):
	if not is_expanded:
		position = position.lerp(target_position, 15 * delta)
	# 低频暗红呼吸
	glow_time += delta * 1.2
	border_alpha = 0.5 + (sin(glow_time) + 1.0) / 2.0 * 0.5
	queue_redraw()

func setup(data: BlockCard):
	card_data = data
	var style = INTENSITY_STYLES[data.intensity]
	bg_color = style["bg"]
	border_color = style["border"]

	$MarkLabel.text = "阻"
	$MarkLabel.add_theme_color_override("font_color", TEXT_COLOR)
	$MarkLabel.add_theme_font_size_override("font_size", 32)

	$NameLabel.text = data.card_name
	$NameLabel.add_theme_color_override("font_color", TEXT_COLOR)
	$NameLabel.add_theme_font_size_override("font_size", 34)

	$EffectLabel.text = _get_effect_text(data.effect_id)
	$EffectLabel.add_theme_color_override("font_color", TEXT_COLOR)
	$EffectLabel.add_theme_font_size_override("font_size", 28)

	queue_redraw()

func _get_effect_text(effect_id: String) -> String:
	match effect_id:
		"BLOCK_RESET_MULTI":   return "倍率归1\n龙链从头计算"
		"BLOCK_MINUS_MULTI":   return "倍率-0.5\n不低于1"
		"BLOCK_MINUS_BREATH":  return "气口-1"
		"BLOCK_DISCARD_HAND":  return "随机丢弃\n1张手牌"
		"BLOCK_ZERO_NEXT":     return "下一张货物牌\n价值归零"
		"BLOCK_RESET_BREATH":  return "倍率归1\n且气口-1"
		_: return ""

func _draw():
	if card_data == null:
		return
	var shape_rect = $CollisionShape2D.shape.get_rect()

	# 深色背景填充
	draw_rect(shape_rect, bg_color, true)

	# 光晕层
	var glow_steps = 6
	for s in range(1, glow_steps + 1):
		var expand = s * 5.0
		var falloff = 1.0 - float(s) / float(glow_steps + 1)
		var alpha = border_alpha * falloff * falloff * 0.4
		var gc = Color(border_color.r, border_color.g, border_color.b, alpha)
		draw_rect(shape_rect.grow(expand), gc, false, 3.0)

	# 主边框
	var bc = Color(border_color.r, border_color.g, border_color.b, border_alpha)
	draw_rect(shape_rect, bc, false, 6.0)
func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed and is_expanded:
			_collapse_card()
signal table_card_pressed(card)

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			table_card_pressed.emit(self)

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
