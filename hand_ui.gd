extends Node2D

@export var card_scene: PackedScene = preload("res://card_ui.tscn")
@export var spacing: float = 120.0 # 卡牌间距

var cards_in_hand: Array = []

func _ready():
	# 测试：从你的资源库里随机抽 5 张牌看看
	test_draw_cards(5)

func test_draw_cards(count: int):
	# 1. 获取文件列表（这时候它是 PackedStringArray）
	var raw_files = DirAccess.get_files_at("res://Resources/Cards/")
	
	# 2. 【关键修复】把“货单束”解开，变成普通的数组
	var all_files = Array(raw_files)
	
	# 3. 现在可以丝滑地乱序了
	all_files.shuffle()
	
	for i in range(min(count, all_files.size())):
		# 确保只加载 .tres 资源文件，跳过 .import 结尾的残留
		if not all_files[i].ends_with(".tres"):
			continue
			
		var card_res = load("res://Resources/Cards/" + all_files[i])
		add_card_ui(card_res)

func add_card_ui(data: BaseCard):
	var new_card = card_scene.instantiate()
	add_child(new_card)
	new_card.setup(data)
	cards_in_hand.append(new_card)
	new_card.drag_ended.connect(_on_card_drag_ended)
	update_hand_positions()

# 核心：计算每张牌应该在的位置
func update_hand_positions():
	# 这里可以调用你之前的 HandManager 排序逻辑
	# 暂时先简单按加入顺序排成一排
	var start_x = -(cards_in_hand.size() - 1) * spacing / 2.0
	for i in range(cards_in_hand.size()):
		cards_in_hand[i].target_position = Vector2(start_x + i * spacing, 500)

func _on_card_drag_ended():
	# 拖拽结束后，重新检查接龙逻辑或重新排序
	update_hand_positions()
