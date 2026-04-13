extends Control

@onready var breath_label = $BreathLabel
@onready var multiplier_label = $MultiplierLabel
@onready var chain_value_label = $ChainValueLabel
@onready var total_money_label = $TotalMoneyLabel

func _ready():
	get_tree().root.size_changed.connect(_reposition)
	for lbl in [breath_label, multiplier_label, chain_value_label, total_money_label]:
		lbl.add_theme_font_size_override("font_size", 28)
	_reposition()
	update_display(3, 3, 1.0, 0, 0)

func _reposition():
	var vp = get_viewport_rect().size
	self.position = Vector2(20, vp.y - 280)
	breath_label.position = Vector2(0, 0)
	breath_label.size = Vector2(230, 50)
	multiplier_label.position = Vector2(0, 60)
	multiplier_label.size = Vector2(230, 50)
	chain_value_label.position = Vector2(0, 120)
	chain_value_label.size = Vector2(230, 50)
	total_money_label.position = Vector2(0, 180)
	total_money_label.size = Vector2(230, 50)

func update_display(current_breath: int, max_breath: int, multiplier: float, chain_value: int, total_money: int):
	var breath_str = ""
	for i in range(max_breath):
		breath_str += "\u25cf" if i < current_breath else "\u25cb"
	breath_label.text = "☁ 气口  " + breath_str
	breath_label.add_theme_color_override("font_color",
		Color(0.2, 0.9, 0.3) if current_breath == max_breath
		else Color(0.9, 0.5, 0.1) if current_breath > 1
		else Color(0.95, 0.2, 0.2))

	multiplier_label.text = "\u500d\u7387  \u00d7" + ("%.1f" % multiplier)
	multiplier_label.add_theme_color_override("font_color",
		Color(0.2, 0.9, 0.3) if multiplier > 1.0 else Color(0.7, 0.7, 0.7))

	chain_value_label.text = "\u9f99\u94fe  " + str(chain_value) + " \u8d2f"
	chain_value_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.2))

	total_money_label.text = "\u603b\u8ba1  " + str(total_money) + " \u8d2f"
	total_money_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
