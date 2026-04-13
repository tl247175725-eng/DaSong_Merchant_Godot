extends Control

@onready var label = $Label
@onready var bar = $Bar
@onready var fill = $Fill

const MAX_PATIENCE = 10.0
const BAR_WIDTH = 200.0
const BAR_HEIGHT = 18.0

var patience: float = MAX_PATIENCE
var shake_time: float = 0.0
var is_shaking: bool = false

func _ready():
	get_tree().root.size_changed.connect(_reposition)
	_setup_children()
	_reposition()

func _setup_children():
	label.size = Vector2(BAR_WIDTH, 26)
	label.text = "客户耐心"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	bar.size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	bar.color = Color(0.2, 0.2, 0.2)
	fill.size = Vector2(BAR_WIDTH, BAR_HEIGHT)

func _reposition():
	var cx = get_viewport_rect().size.x / 2.0
	position = Vector2(cx - BAR_WIDTH / 2.0, 30)
	label.position = Vector2(0, 0)
	bar.position = Vector2(0, 28)
	fill.position = Vector2(0, 28)
	_update_visuals()

func _process(delta):
	if is_shaking:
		shake_time += delta
		var cx = get_viewport_rect().size.x / 2.0
		position.x = cx - BAR_WIDTH / 2.0 + sin(shake_time * 30.0) * 3.0
	else:
		position.x = get_viewport_rect().size.x / 2.0 - BAR_WIDTH / 2.0

func consume(amount: float) -> bool:
	# 消耗耐心值，返回是否触发插牌
	patience -= amount
	patience = max(patience, 0.0)
	_update_visuals()
	if patience <= 0.0:
		patience = MAX_PATIENCE
		_update_visuals()
		return true  # 触发插牌
	return false

func _update_visuals():
	var ratio = patience / MAX_PATIENCE
	fill.size = Vector2(BAR_WIDTH * ratio, BAR_HEIGHT)

	# 颜色随耐心变化
	if ratio > 0.5:
		fill.color = Color(0.2, 0.85, 0.3)   # 绿
	elif ratio > 0.25:
		fill.color = Color(0.95, 0.75, 0.1)  # 黄
	else:
		fill.color = Color(0.95, 0.2, 0.2)   # 红

	# 低于25%开始抖动
	is_shaking = (ratio <= 0.25)
