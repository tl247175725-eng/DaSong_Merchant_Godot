# DeckManager.gd
extends Node

# 抽牌堆和弃牌堆
var draw_pile: Array[BaseCard] = []
var discard_pile: Array[BaseCard] = []

# 初始化牌库：从 Resources/Cards 文件夹加载所有 .tres 货物
func init_deck():
	var path = "res://Resources/Cards/"
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var card_res = load(path + file_name)
				if card_res is BaseCard:
					draw_pile.append(card_res)
			file_name = dir.get_next()
	
	# 初始洗牌
	draw_pile.shuffle()
	print("担子已装好，共有货物：", draw_pile.size(), " 件")

# 核心：抽取一张牌
func draw_one_card() -> BaseCard:
	if draw_pile.is_empty():
		# 如果抽牌堆空了，将弃牌堆洗回抽牌堆
		if discard_pile.is_empty():
			print("货卖完了！没法再抽了。")
			return null
		_reshuffle_discard_into_draw()
	
	return draw_pile.pop_back()

# 将牌放入弃牌堆 (当成交或断龙清空桌面时调用)
func add_to_discard(card_data: BaseCard):
	discard_pile.append(card_data)

# 私有逻辑：洗牌
func _reshuffle_discard_into_draw():
	print("正在重新整理担子（洗牌）...")
	draw_pile = discard_pile.duplicate()
	discard_pile.clear()
	draw_pile.shuffle()
