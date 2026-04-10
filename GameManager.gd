# GameManager.gd (建议新建并挂载到根节点)
extends Node

var deck: Array[BaseCard] = []      # 抽牌堆（担子里的货）
var discard: Array[BaseCard] = []   # 弃牌堆（卖掉的或弄碎的）

@onready var hand_ui = $HandUI

func _ready():
	# 1. 游戏开始，从资源库装货
	var all_res = DirAccess.get_files_at("res://Resources/Cards/")
	for f in all_res:
		if f.ends_with(".tres"):
			deck.append(load("res://Resources/Cards/" + f))
	
	# 2. 洗牌
	deck.shuffle()
	
	# 3. 初始进货 (抽5张)
	for i in range(5):
		draw_one_card()

func draw_one_card():
	if deck.is_empty():
		# 自动洗回弃牌堆，防止断货 [cite: 215]
		deck = discard.duplicate()
		discard.clear()
		deck.shuffle()
		
	if not deck.is_empty():
		var card_data = deck.pop_back()
		hand_ui.add_card_ui(card_data) # 把数据传给 UI 渲染
