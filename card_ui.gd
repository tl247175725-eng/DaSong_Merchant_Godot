extends Area2D

signal drag_started
signal drag_ended

var card_data: BaseCard      # 绑定的数据资源
var target_position: Vector2 # 自动排序的目标位置
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO

func _ready():
	# 简单的平滑移动：每帧向目标位置靠拢
	# 也可以用 Tween，但这里用 lerp 更适合实时跟随
	pass
# card_ui.gd
func _process(delta):
	if is_dragging:
		global_position = get_global_mouse_position() + drag_offset
	else:
		# 改成 position，它就学会“相对于担子”排队了
		position = position.lerp(target_position, 15 * delta)

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging = true
				drag_offset = global_position - get_global_mouse_position()
				z_index = 100 # 拖拽时显示在最上层
				drag_started.emit()
			else:
				is_dragging = false
				z_index = 0
				drag_ended.emit()

# 初始化卡牌数据
func setup(data: BaseCard):
	card_data = data
	$NameLabel.text = data.card_name
	$ValueLabel.text = str(data.base_value)
