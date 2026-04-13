extends Resource
class_name BlockCard

enum Intensity { LOW, MID, HIGH, EXTREME }

@export var card_id: String = ""
@export var card_name: String = ""
@export var intensity: Intensity = Intensity.LOW
@export var effect_id: String = ""
@export var description: String = ""
