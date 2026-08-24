extends Node2D
class_name DamageNumber

@onready var label: Label = $Label

func setup(text: String, color: Color, is_crit: bool = false, is_effective: bool = false) -> void:
	if not is_node_ready():
		await ready
		
	label.text = text
	label.modulate = color
	
	if is_crit:
		scale = Vector2(1.5, 1.5)
	elif is_effective:
		scale = Vector2(1.25, 1.25)
	else:
		scale = Vector2(1.0, 1.0)
		
	var tween = create_tween().set_parallel(true)
	var rise_offset = Vector2(randf_range(-20, 20), -45)
	
	tween.tween_property(self, "position", position + rise_offset, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", scale * 1.2, 0.2).set_trans(Tween.TRANS_BACK)
	tween.chain().tween_property(self, "scale", scale * 0.8, 0.5)
	tween.tween_property(self, "modulate:a", 0.0, 0.7).set_delay(0.2)
	
	tween.finished.connect(func(): queue_free())
