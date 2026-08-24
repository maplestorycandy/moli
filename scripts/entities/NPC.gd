extends Area2D
class_name NPC

@export var npc_name: String = "醫院護士 瑪塔"
@export var npc_role: String = "NURSE" # "NURSE", "MERCHANT", "GUARD", "TRAINER"
@export var npc_color: Color = Color(0.95, 0.4, 0.6)

var is_player_nearby: bool = false
var anim_timer: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	anim_timer += delta
	queue_redraw()
	
	if is_player_nearby and Input.is_action_just_pressed("interact"):
		_interact()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_player_nearby = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_player_nearby = false

func _interact() -> void:
	match npc_role:
		"NURSE":
			var lines = [
				"歡迎來到法蘭城醫院！願愛謝拉女神的溫柔光輝撫平冒險者的疲憊。",
				"你的傷口已痊癒，生命值與魔力值已完全恢復！"
			]
			EventBus.dialog_started.emit(npc_name, lines, ["接受治療", "離開"], func(idx):
				if idx == 0:
					Global.hp = Global.max_hp
					Global.mp = Global.max_mp
					EventBus.player_health_changed.emit(Global.hp, Global.max_hp)
					EventBus.player_mana_changed.emit(Global.mp, Global.max_mp)
					EventBus.damage_spawned.emit(Global.player.global_position if Global.player else global_position, "全體完全恢復！", Color(0.2, 1.0, 0.4), false, false)
					SoundManager.play_heal()
			)
			
		"MERCHANT":
			var lines = [
				"我是法蘭城的魔石收購商！你在野外擊敗魔物獲得的【魔石】都可以高價賣給我！"
			]
			EventBus.dialog_started.emit(npc_name, lines, ["出售所有魔石", "購買生命藥水 (40G)", "離開"], func(idx):
				if idx == 0:
					var total_sold = 0
					var total_gold = 0
					for i in range(Global.inventory.size() - 1, -1, -1):
						var it = Global.inventory[i]
						if it.get("id") == "magic_stone":
							var cnt = it.get("count", 1)
							total_sold += cnt
							total_gold += cnt * 80
							Global.inventory.remove_at(i)
						elif it.get("id") == "magic_stone_large":
							var cnt = it.get("count", 1)
							total_sold += cnt
							total_gold += cnt * 500
							Global.inventory.remove_at(i)
					if total_sold > 0:
						Global.add_gold(total_gold)
						EventBus.inventory_updated.emit()
						EventBus.damage_spawned.emit(global_position, "獲得 +%d G！" % total_gold, Color(1.0, 0.9, 0.2), false, false)
					else:
						EventBus.damage_spawned.emit(global_position, "背包中沒有魔石！", Color(0.8, 0.8, 0.8), false, false)
				elif idx == 1:
					if Global.gold >= 40:
						Global.gold -= 40
						Global.add_item({
							"id": "potion_hp_small",
							"name": "生命之藥(200)",
							"type": "consumable",
							"count": 1,
							"desc": "瞬間恢復 200 點生命值",
							"price": 40,
							"color": Color(0.2, 0.9, 0.3)
						})
						EventBus.gold_changed.emit(Global.gold, -40)
			)
			
		"GUARD":
			var lines = [
				"這裡是法蘭城東門橋頭！前方就是廣大的芙蕾雅島冒險原野。",
				"往東南方前進可通往【哈巴魯東邊洞穴】，據說裡面有自稱熱砂之歐茲那克的熊男霸佔，請務必帶足藥水與封印卡！"
			]
			EventBus.dialog_started.emit(npc_name, lines, ["瞭解！"], func(_idx): pass)
			
		"TRAINER":
			var lines = [
				"身為一名封印師，捕捉野怪的精髓在於【殘血削弱】與【屬性卡片】！",
				"要不要向我購買 3 張普卡封印卡 (200G)？"
			]
			EventBus.dialog_started.emit(npc_name, lines, ["購買封印卡 (200G)", "離開"], func(idx):
				if idx == 0:
					if Global.gold >= 200:
						Global.gold -= 200
						Global.add_item({
							"id": "seal_card_normal",
							"name": "普卡封印卡",
							"type": "seal_card",
							"tier": CombatMath.SealCardTier.NORMAL,
							"count": 3,
							"desc": "可封印普通野生怪物的卡片",
							"price": 100,
							"color": Color(0.85, 0.85, 0.9)
						})
						EventBus.gold_changed.emit(Global.gold, -200)
						SoundManager.play_gold()
			)
			
		"TELEPORT":
			var lines = [
				"【魔力寶貝 3D 世界全域傳送矩陣】",
				"開啟全地圖矩陣，自由穿梭於法蘭城、馬斯城、阿凱魯法城、哥拉爾城、雪山之巔與神域深淵！"
			]
			EventBus.dialog_started.emit(npc_name, lines, ["開啟 3D 地圖矩陣", "離開"], func(idx):
				if idx == 0:
					var map_win = get_tree().root.find_child("MapSwitchWindow", true, false)
					if map_win and map_win.has_method("open_window"):
						map_win.open_window()
			)

func _draw() -> void:
	draw_custom_ellipse(Vector2(0, 12), 12.0, 6.0, Color(0, 0, 0, 0.3))
	
	# NPC 外觀 (復古服飾)
	draw_circle(Vector2(0, 2), 10.0, npc_color)
	draw_circle(Vector2(0, -9), 7.5, Color(0.98, 0.8, 0.68)) # 臉部
	
	if npc_role == "NURSE":
		# 經典護士帽與紅十字
		draw_rect(Rect2(-6, -17, 12, 6), Color.WHITE)
		draw_line(Vector2(0, -16), Vector2(0, -12), Color.RED, 2.0)
		draw_line(Vector2(-3, -14), Vector2(3, -14), Color.RED, 2.0)
	elif npc_role == "GUARD":
		# 鋼鐵頭盔
		draw_circle(Vector2(0, -11), 8.5, Color(0.7, 0.75, 0.8))
	else:
		# 棕色冒險帽
		draw_circle(Vector2(0, -13), 8.0, Color(0.45, 0.3, 0.15))
		
	# 提示互動按鈕 [F / 點擊]
	if is_player_nearby:
		var float_y = sin(anim_timer * 8.0) * 3.0
		draw_circle(Vector2(0, -28 + float_y), 9.0, Color(0.1, 0.2, 0.6, 0.85))
		draw_arc(Vector2(0, -28 + float_y), 9.0, 0, TAU, 16, Color(1.0, 0.85, 0.2), 1.5)

func draw_custom_ellipse(c: Vector2, rx: float, ry: float, color: Color) -> void:
	var points = PackedVector2Array()
	for i in range(20):
		var rad = (TAU / 20.0) * i
		points.append(c + Vector2(cos(rad) * rx, sin(rad) * ry))
	draw_colored_polygon(points, color)
