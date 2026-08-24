extends CharacterBody2D
class_name Player

@export var acceleration: float = 1200.0
@export var friction: float = 1000.0

# 狀態枚舉 (避免與 components/State.gd 名稱衝突)
enum ActionState {
	IDLE,
	MOVE,
	ATTACK,
	DODGE,
	SKILL_COMBO,
	SKILL_FORCE_STRIKE,
	CAST_MAGIC,
	HURT
}

var current_state: ActionState = ActionState.IDLE
var facing_direction: Vector2 = Vector2.DOWN
var aim_direction: Vector2 = Vector2.RIGHT

# 戰鬥計時器與參數
var state_timer: float = 0.0
var combo_step: int = 0
var attack_charge_time: float = 0.0
var dodge_direction: Vector2 = Vector2.ZERO
var dodge_speed: float = 360.0
var is_invulnerable: bool = false

# 預載技能與投射物場景
var kiblast_scene = preload("res://scenes/combat/KiBlastProjectile.tscn")
var meteor_scene = preload("res://scenes/combat/MeteorStrike.tscn")
var seal_card_scene = preload("res://scenes/combat/SealCardProjectile.tscn")

@onready var hurtbox: HurtboxComponent = $HurtboxComponent
@onready var weapon_hitbox: HitboxComponent = $WeaponHitbox
@onready var weapon_collision: CollisionShape2D = $WeaponHitbox/CollisionShape2D

func _ready() -> void:
	Global.player = self
	add_to_group("player")
	weapon_collision.disabled = true
	weapon_hitbox.attacker_node = self
	weapon_hitbox.is_player_team = true
	
	hurtbox.hit_received.connect(_on_hit_received)
	EventBus.player_health_changed.emit(Global.hp, Global.max_hp)
	EventBus.player_mana_changed.emit(Global.mp, Global.max_mp)

func _process(delta: float) -> void:
	# 滑鼠瞄準方向計算
	var mouse_pos = get_global_mouse_position()
	aim_direction = (mouse_pos - global_position).normalized()
	
	_handle_input()
	_update_state(delta)
	queue_redraw()

func _physics_process(delta: float) -> void:
	match current_state:
		ActionState.IDLE, ActionState.MOVE:
			_physics_movement(delta)
		ActionState.DODGE:
			velocity = dodge_direction * dodge_speed
			move_and_slide()
		ActionState.SKILL_COMBO:
			velocity = facing_direction * 180.0
			move_and_slide()
		ActionState.ATTACK, ActionState.SKILL_FORCE_STRIKE, ActionState.CAST_MAGIC, ActionState.HURT:
			velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
			move_and_slide()

func _handle_input() -> void:
	if current_state in [ActionState.ATTACK, ActionState.DODGE, ActionState.SKILL_COMBO, ActionState.SKILL_FORCE_STRIKE, ActionState.CAST_MAGIC, ActionState.HURT]:
		return
		
	# 普通攻擊
	if Input.is_action_just_pressed("attack"):
		_start_attack()
		return
		
	# 翻滾閃避
	if Input.is_action_just_pressed("dodge"):
		_start_dodge()
		return
		
	# 技能1: 連擊
	if Input.is_action_just_pressed("skill_1"):
		if Global.mp >= 15:
			Global.mp -= 15
			EventBus.player_mana_changed.emit(Global.mp, Global.max_mp)
			_start_skill_combo()
		else:
			EventBus.damage_spawned.emit(global_position, "MP不足！", Color(0.4, 0.7, 1.0), false, false)
		return
		
	# 技能2: 乾坤一擲
	if Input.is_action_just_pressed("skill_2"):
		if Global.mp >= 22:
			Global.mp -= 22
			EventBus.player_mana_changed.emit(Global.mp, Global.max_mp)
			_start_force_strike()
		else:
			EventBus.damage_spawned.emit(global_position, "MP不足！", Color(0.4, 0.7, 1.0), false, false)
		return
		
	# 技能3: 氣功彈
	if Input.is_action_just_pressed("skill_3"):
		if Global.mp >= 20:
			Global.mp -= 20
			EventBus.player_mana_changed.emit(Global.mp, Global.max_mp)
			_cast_ki_blast()
		else:
			EventBus.damage_spawned.emit(global_position, "MP不足！", Color(0.4, 0.7, 1.0), false, false)
		return
		
	# 技能4: 超強隕石魔法
	if Input.is_action_just_pressed("skill_4"):
		if Global.mp >= 30:
			Global.mp -= 30
			EventBus.player_mana_changed.emit(Global.mp, Global.max_mp)
			_cast_meteor_magic()
		else:
			EventBus.damage_spawned.emit(global_position, "MP不足！", Color(0.4, 0.7, 1.0), false, false)
		return
		
	# 投擲封印卡
	if Input.is_action_just_pressed("seal_monster"):
		_throw_seal_card()
		return
		
	# 切換寵物戰術
	if Input.is_action_just_pressed("pet_command"):
		_cycle_pet_command()
		return

func _physics_movement(delta: float) -> void:
	var input_vec = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	).normalized()
	
	if input_vec != Vector2.ZERO:
		facing_direction = input_vec
		velocity = velocity.move_toward(input_vec * Global.agi_speed, acceleration * delta)
		current_state = ActionState.MOVE
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		current_state = ActionState.IDLE
		
	move_and_slide()

# --- 戰鬥與技能動作 ---

func _start_attack() -> void:
	current_state = ActionState.ATTACK
	state_timer = 0.0
	combo_step = (combo_step % 3) + 1
	facing_direction = aim_direction
	
	weapon_hitbox.damage_multiplier = 1.0 + (combo_step * 0.2)
	weapon_hitbox.skill_name = "普通攻擊"
	weapon_hitbox.reset_hit_list()
	weapon_hitbox.position = facing_direction * 28.0
	weapon_hitbox.rotation = facing_direction.angle()
	weapon_collision.disabled = false
	
	SoundManager.play_swing()
	EventBus.character_attack_triggered.emit(self, global_position + facing_direction * 30, "普通攻擊")

func _start_dodge() -> void:
	current_state = ActionState.DODGE
	state_timer = 0.0
	var input_vec = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	).normalized()
	
	dodge_direction = input_vec if input_vec != Vector2.ZERO else facing_direction
	hurtbox.is_invulnerable = true
	SoundManager.play_dodge()

func _start_skill_combo() -> void:
	current_state = ActionState.SKILL_COMBO
	state_timer = 0.0
	combo_step = 0
	facing_direction = aim_direction
	EventBus.damage_spawned.emit(global_position + Vector2(0, -35), "【連擊】", Color(0.3, 1.0, 0.8), false, false)

func _start_force_strike() -> void:
	current_state = ActionState.SKILL_FORCE_STRIKE
	state_timer = 0.0
	facing_direction = aim_direction
	EventBus.damage_spawned.emit(global_position + Vector2(0, -35), "【乾坤一擲】蓄力！", Color(1.0, 0.6, 0.1), false, false)

func _cast_ki_blast() -> void:
	facing_direction = aim_direction
	SoundManager.play_swing()
	EventBus.damage_spawned.emit(global_position + Vector2(0, -35), "【氣功彈】", Color(1.0, 0.9, 0.2), false, false)
	
	# 發射 2 枚氣功彈 (略帶擴散角)
	var angles = [-0.15, 0.15]
	for a in angles:
		var dir = aim_direction.rotated(a)
		var proj = kiblast_scene.instantiate()
		proj.global_position = global_position + dir * 20
		get_parent().add_child(proj)
		proj.setup(dir, self)

func _cast_meteor_magic() -> void:
	var target_pos = get_global_mouse_position()
	EventBus.damage_spawned.emit(global_position + Vector2(0, -35), "【超強隕石魔法】", Color(0.9, 0.6, 0.1), false, false)
	var spell = meteor_scene.instantiate()
	get_parent().add_child(spell)
	spell.setup(target_pos, self)

func _throw_seal_card() -> void:
	# 檢查背包中是否有封印卡
	var has_card = false
	var chosen_tier = CombatMath.SealCardTier.NORMAL
	var card_name = "普卡封印卡"
	
	for item in Global.inventory:
		if item.get("type") == "seal_card" and item.get("count", 0) > 0:
			has_card = true
			chosen_tier = item.get("tier", CombatMath.SealCardTier.NORMAL)
			card_name = item.get("name", "封印卡")
			Global.consume_item(item["id"])
			break
			
	if not has_card:
		EventBus.damage_spawned.emit(global_position, "沒有封印卡！", Color(1.0, 0.3, 0.3), false, false)
		return
		
	var target_pos = get_global_mouse_position()
	var card_proj = seal_card_scene.instantiate()
	card_proj.global_position = global_position
	get_parent().add_child(card_proj)
	card_proj.setup(target_pos, chosen_tier, card_name, self)

func _cycle_pet_command() -> void:
	if Global.pet_command_mode == "FOLLOW_ATTACK":
		Global.pet_command_mode = "GUARD"
		EventBus.show_banner_notification.emit("寵物指令切換", "【護衛模式】寵物將優先守護玩家並阻擋攻擊！")
	elif Global.pet_command_mode == "GUARD":
		Global.pet_command_mode = "STANDBY"
		EventBus.show_banner_notification.emit("寵物指令切換", "【待命模式】寵物原地警戒保持戰力！")
	else:
		Global.pet_command_mode = "FOLLOW_ATTACK"
		EventBus.show_banner_notification.emit("寵物指令切換", "【進攻模式】寵物協同並肩主動攻擊敵人！")
	EventBus.pet_command_changed.emit(Global.pet_command_mode)

func _update_state(delta: float) -> void:
	state_timer += delta
	
	match current_state:
		ActionState.ATTACK:
			if state_timer >= 0.18:
				weapon_collision.disabled = true
			if state_timer >= 0.28:
				current_state = ActionState.IDLE
				
		ActionState.DODGE:
			if state_timer >= 0.25:
				hurtbox.is_invulnerable = false
				current_state = ActionState.IDLE
				
		ActionState.SKILL_COMBO:
			# 3~6 段高速劈砍節奏 (支援天賦: 連擊狂暴)
			var max_steps = 6 if BuffManager.has_buff("combo_frenzy") else 3
			var step_dur = 0.10 if max_steps == 6 else 0.12
			
			if state_timer >= step_dur * (combo_step + 1) and combo_step < max_steps:
				combo_step += 1
				var mult = 1.2 + (combo_step * 0.3)
				_trigger_combo_slash(mult)
			elif state_timer >= step_dur * (max_steps + 1):
				weapon_collision.disabled = true
				current_state = ActionState.IDLE
				
		ActionState.SKILL_FORCE_STRIKE:
			# 蓄力 0.45 秒後揮出毀天滅地一擊
			if state_timer >= 0.45 and not weapon_collision.disabled == false:
				weapon_hitbox.damage_multiplier = 3.2 # 320% 超高爆發
				weapon_hitbox.skill_name = "乾坤一擲"
				weapon_hitbox.reset_hit_list()
				weapon_hitbox.position = facing_direction * 36.0
				weapon_hitbox.rotation = facing_direction.angle()
				weapon_collision.disabled = false
				SoundManager.play_crit()
				EventBus.screen_shake_requested.emit(14.0, 0.3)
			if state_timer >= 0.65:
				weapon_collision.disabled = true
				current_state = ActionState.IDLE
				
		ActionState.HURT:
			if state_timer >= 0.2:
				current_state = ActionState.IDLE

func _trigger_combo_slash(mult: float) -> void:
	weapon_hitbox.damage_multiplier = mult
	weapon_hitbox.skill_name = "連擊"
	weapon_hitbox.reset_hit_list()
	weapon_hitbox.position = facing_direction * 30.0
	weapon_hitbox.rotation = facing_direction.angle()
	weapon_collision.disabled = false
	SoundManager.play_swing()
	EventBus.screen_shake_requested.emit(4.0, 0.1)

func _on_hit_received(dmg: int, _is_crit: bool, _is_effective: bool, knock_dir: Vector2, knock_force: float) -> void:
	Global.hp -= dmg
	Global.hp = max(0, Global.hp)
	EventBus.player_health_changed.emit(Global.hp, Global.max_hp)
	
	if Global.hp <= 0:
		EventBus.player_died.emit()
		EventBus.show_banner_notification.emit("你已倒下！", "眼前一片漆黑...已回到法蘭城醫院治療。")
		Global.hp = Global.max_hp
		global_position = Vector2(300, 300)
		EventBus.player_health_changed.emit(Global.hp, Global.max_hp)
	else:
		velocity = knock_dir * (knock_force * 0.7)
		current_state = ActionState.HURT
		state_timer = 0.0

# --- 繪製魔力寶貝經典主角 辛 (Shin) 視覺造型 ---
func _draw() -> void:
	# 陰影
	draw_custom_ellipse(Vector2(0, 14), 16.0, 8.0, Color(0, 0, 0, 0.35))
	
	# 翻滾殘影
	if current_state == ActionState.DODGE:
		draw_circle(Vector2.ZERO, 18.0, Color(0.4, 0.8, 1.0, 0.3))
		
	# 乾坤一擲蓄力氣場
	if current_state == ActionState.SKILL_FORCE_STRIKE and state_timer < 0.45:
		var aura_r = 24.0 + sin(state_timer * 25.0) * 5.0
		draw_arc(Vector2.ZERO, aura_r, 0, TAU, 24, Color(1.0, 0.7, 0.1, 0.8), 2.5)
		draw_circle(Vector2.ZERO, aura_r * 0.6, Color(1.0, 0.4, 0.1, 0.3))
		
	# 主角身軀 (藍色勇者斗篷與輕鎧)
	# 斗篷
	var cape_off = -facing_direction * 6.0
	draw_circle(cape_off + Vector2(0, 2), 12.0, Color(0.15, 0.35, 0.85))
	
	# 身體/輕鎧 (白金與鋼藍)
	draw_circle(Vector2(0, 2), 10.0, Color(0.2, 0.45, 0.95))
	draw_circle(Vector2(0, 4), 6.0, Color(0.85, 0.85, 0.9)) # 胸甲
	
	# 頭部與金色刺猬髮型 (經典辛的招牌金髮)
	draw_circle(Vector2(0, -9), 9.0, Color(1.0, 0.85, 0.2)) # 金髮主體
	draw_circle(Vector2(0, -7), 7.0, Color(0.98, 0.8, 0.68)) # 臉部膚色
	draw_circle(Vector2(2, -13), 5.0, Color(1.0, 0.88, 0.2)) # 翹起的金髮撮
	draw_circle(Vector2(-3, -12), 4.5, Color(1.0, 0.88, 0.2))
	
	# 眼睛
	var eye_offset = facing_direction.normalized() * 3.0
	draw_circle(Vector2(-2, -8) + eye_offset, 1.5, Color(0.1, 0.2, 0.5))
	draw_circle(Vector2(2, -8) + eye_offset, 1.5, Color(0.1, 0.2, 0.5))
	
	# 經典佩劍 (雙手大劍 / 單手劍)
	var sword_pos = facing_direction * 16.0 + Vector2(0, 2)
	var sword_angle = facing_direction.angle()
	
	# 揮劍刀光弧線特效
	if current_state in [ActionState.ATTACK, ActionState.SKILL_COMBO, ActionState.SKILL_FORCE_STRIKE] and not weapon_collision.disabled:
		var slash_col = Color(0.6, 0.9, 1.0, 0.9)
		if current_state == ActionState.SKILL_FORCE_STRIKE:
			slash_col = Color(1.0, 0.4, 0.1, 0.95) # 乾坤一擲熾紅刀光
			draw_arc(Vector2.ZERO, 40.0, sword_angle - 1.2, sword_angle + 1.2, 16, slash_col, 8.0)
		else:
			draw_arc(Vector2.ZERO, 32.0, sword_angle - 0.9, sword_angle + 0.9, 16, slash_col, 4.5)
			
	# 劍身繪製
	var hilt = sword_pos
	var tip = hilt + Vector2.from_angle(sword_angle) * 22.0
	draw_line(hilt, tip, Color(0.9, 0.95, 1.0), 3.5)
	draw_line(hilt, tip, Color.WHITE, 1.5)
	draw_circle(hilt, 3.0, Color(0.9, 0.7, 0.1)) # 金色劍柄十字鐔

func draw_custom_ellipse(center: Vector2, rx: float, ry: float, color: Color) -> void:
	var points = PackedVector2Array()
	for i in range(24):
		var rad = (TAU / 24.0) * i
		points.append(center + Vector2(cos(rad) * rx, sin(rad) * ry))
	draw_colored_polygon(points, color)
