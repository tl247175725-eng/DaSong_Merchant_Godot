extends Node

const CSV_PATH = "res://goods_data.csv"
const SAVE_DIR = "res://Resources/Cards/"

func _ready():
	import_cards()

func import_cards():
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
		if line.size() < 5:
			continue

		var card = BaseCard.new()
		card.card_id = line[0]
		card.card_name = line[1]

		match line[2]:
			"茶": card.suit = BaseCard.Suit.TEA
			"瓷": card.suit = BaseCard.Suit.PORCELAIN
			"绸": card.suit = BaseCard.Suit.SILK
			"香": card.suit = BaseCard.Suit.INCENSE

		card.rank = int(line[3])
		card.base_value = int(line[4])

		match line[5]:
			"普通": card.card_type = BaseCard.CardType.NORMAL
			"效果": card.card_type = BaseCard.CardType.EFFECT
			"结算": card.card_type = BaseCard.CardType.SETTLE

		card.effect_id = line[6] if line.size() > 6 else "NONE"
		card.description = line[7] if line.size() > 7 else ""

		var save_path = SAVE_DIR + card.card_id + ".tres"
		ResourceSaver.save(card, save_path)
		print("进货成功: ", card.card_name, " -> ", save_path)

	print("全局 52 张基础货物已全部入库！")
