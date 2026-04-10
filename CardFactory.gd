# CardFactory.gd - 货郎记自动化进货工具
extends Node

const CSV_PATH = "res://goods_data.csv"
const SAVE_DIR = "res://Resources/Cards/"

func _ready():
	import_cards()

func import_cards():
	# 确保保存目录存在
	var dir = DirAccess.open("res://")
	if not dir.dir_exists(SAVE_DIR):
		dir.make_dir_recursive(SAVE_DIR)
		
	var file = FileAccess.open(CSV_PATH, FileAccess.READ)
	if not file:
		print("找不到 CSV 文件，请检查路径！")
		return
		
	# 跳过表头
	file.get_csv_line()
	
	while !file.eof_reached():
		var line = file.get_csv_line()
		if line.size() < 5: continue
		
		var card = BaseCard.new()
		card.card_id = line[0]
		card.card_name = line[1]
		
		# 转换行当枚举 (茶=0, 瓷=1, 绸=2, 香=3)
		match line[2]:
			"茶": card.suit = BaseCard.Suit.TEA
			"瓷": card.suit = BaseCard.Suit.PORCELAIN
			"绸": card.suit = BaseCard.Suit.SILK
			"香": card.suit = BaseCard.Suit.INCENSE
			
		card.rank = int(line[3])
		card.base_value = int(line[4])
		card.description = line[6] if line.size() > 6 else ""
		
		# 保存为 Resource 文件
		var save_path = SAVE_DIR + card.card_id + ".tres"
		ResourceSaver.save(card, save_path)
		print("进货成功: ", card.card_name, " -> ", save_path)

	print("🎉 全局 52 张基础货物已全部入库！")
