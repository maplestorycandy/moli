extends Area2D
class_name DropItem

@export var item_id: String = "magic_stone"
@export var item_name: String = "魔石"
@export var item_type: String = "material" # "gold", "material", "consumable", "seal_card"
@export var count: int = 1
@export var gold_amount: int = 50
@export var icon_color: Color = Color(0.3, 0.7, 1.0)

var anim_timer: float = 0.0
var is_picked: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var tween = create_tween()
	var jump_offset = Vector2(randf_range(-25, 25), randf_range(-25, 25))
	tween.tween_property(self, "position", position + jump_offset, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func setup(id: String, i_name: String, i_type: String, cnt: int, gold_val: int = 0, col: Color = Color.WHITE) -> void:
	item_id = id
	item_name = i_name
	item_type = i_type
	count = cnt
	gold_amount = gold_val
	icon_color = col

func _process(delta: float) -> void:
	anim_timer += delta
	queue_redraw()
	
	# 自動被周遭玩家吸引
	if Global.player and not is_picked:
		var dist = global_position.distance_to(Global.player.global_position)
		if dist < 70.0:
			global_position = global_position.move_toward(Global.player.global_position, 280.0 * delta)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not is_picked:
		is_picked = true
		if item_type == "gold":
			Global.add_gold(gold_amount)
			EventBus.damage_spawned.emit(global_position, "+%d G" % gold_amount, Color(1.0, 0.9, 0.2), false, false)
		else:
			Global.add_item({
				"id": item_id,
				"name": item_name,
				"type": item_type,
				"count": count,
				"desc": "冒險中獲得的寶物",
				"price": 60,
				"color": icon_color
			})
			EventBus.damage_spawned.emit(global_position, "+%s x%d" % [item_name, count], icon_color, false, false)
			SoundManager.play_gold()
			
		queue_free()

func _draw() -> void:
	var float_y = sin(anim_timer * 6.0) * 3.0
	draw_circle(Vector2(0, 6), 7.0, Color(0, 0, 0, 0.25)) # 陰影
	
	if item_type == "gold":
		# 金幣
		draw_circle(Vector2(0, float_y), 6.0, Color(1.0, 0.85, 0.1))
		draw_circle(Vector2(0, float_y), 3.5, Color(0.9, 0.6, 0.0))
	elif item_id == "magic_stone":
		# 魔力寶貝經典魔石 (菱形藍紫色水晶)
		var pts = PackedVector2Array([
			Vector2(0, -8 + float_y),
			Vector2(6, float_y),
			Vector2(0, 8 + float_y),
			Vector2(-6, float_y)
		])
		draw_colored_polygon(pts, Color(0.5, 0.3, 0.9))
		draw_polyline(pts, Color(0.8, 0.6, 1.0), 1.5)
	else:
		# 寶物袋 / 卡片
		draw_circle(Vector2(0, float_y), 6.0, icon_color)
		draw_arc(Vector2.ZERO, 9.0, 0, TAU, 12, Color.WHITE, 1.0)
