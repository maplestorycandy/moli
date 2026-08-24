extends CharacterBody2D
class_name EnemyBase

const ProceduralMonsterDrawer = preload("res://scripts/world/ProceduralMonsterDrawer.gd")

@export var aggro_range: float = 280.0
@export var attack_range: float = 40.0
@export var attack_cooldown_time: float = 1.8

enum AIState {
	IDLE,
	WANDER,
	CHASE,
	ATTACK,
	HURT,
	STUNNED,
	DEAD
}

var ai_state: AIState = AIState.IDLE
var target: Node2D = null
var spawn_pos: Vector2
var wander_target: Vector2
var state_timer: float = 0.0
var attack_cooldown: float = 0.0
var anim_timer: float = 0.0
var is_stunned: bool = false
var is_wave_attacker: bool = false

# 怪物外觀與多幀動畫資料 (單一真實魔物，多幀循環)
var monster_data: Dictionary = {}
var anim_frames: Array[Texture2D] = []

var drawer_type: String = "slime"
var color_main: Color = Color(0.2, 0.85, 0.45)
var color_sub: Color = Color(0.6, 1.0, 0.7)
var monster_scale: float = 1.0
var is_boss: bool = false

var drop_item_scene = preload("res://scenes/items/DropItem.tscn")

@onready var stats: StatsComponent = $StatsComponent
@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: HurtboxComponent = $HurtboxComponent
@onready var hitbox: HitboxComponent = $HitboxComponent
@onready var hitbox_collision: CollisionShape2D = $HitboxComponent/CollisionShape2D

func _ready() -> void:
	add_to_group("enemies")
	spawn_pos = global_position
	wander_target = spawn_pos
	
	hitbox.is_player_team = false
	hitbox.attacker_node = self
	hitbox_collision.disabled = true
	
	hurtbox.is_player_team = false
	hurtbox.hit_received.connect(_on_hit_received)
	health.died.connect(_on_died)
	
	_on_init_custom()

func setup_from_monster_data(m_data: Dictionary, wave: int = 1) -> void:
	monster_data = m_data
	drawer_type = m_data.get("drawer_type", "slime")
	color_main = m_data.get("color_main", Color.GREEN)
	color_sub = m_data.get("color_sub", Color.WHITE)
	monster_scale = m_data.get("scale", 1.0)
	is_boss = "boss" in m_data.get("id", "") or "B0" in m_data.get("num", "")
	
	# 載入個別乾淨幀圖庫，確保永遠只有單隻魔物，絕不分裂
	anim_frames.clear()
	var num_str = str(m_data.get("num", ""))
	if num_str != "":
		for i in range(4):
			var f_path = "res://assets/sprites/monsters/%s_%d.png" % [num_str, i]
			if ResourceLoader.exists(f_path):
				anim_frames.append(load(f_path))
		if anim_frames.is_empty():
			var single_path = "res://assets/sprites/monsters/%s.png" % num_str
			if ResourceLoader.exists(single_path):
				anim_frames.append(load(single_path))
	
	if not is_node_ready():
		await ready
		
	var wave_mult = 1.0 + (wave * 0.12)
	stats.character_name = m_data.get("name", "魔物")
	stats.race = m_data.get("race", "特殊系")
	stats.level = max(1, wave)
	stats.max_hp = int(m_data.get("base_hp", 100) * wave_mult * 5.0) # 怪物血量提升 5 倍
	stats.max_mp = int(m_data.get("base_mp", 50) * wave_mult)
	stats.atk = int(m_data.get("base_atk", 20) * wave_mult)
	stats.def = int(m_data.get("base_def", 10) * (1.0 + wave * 0.08))
	stats.move_speed = m_data.get("speed", 100.0)
	stats.element_dist = m_data.get("element", { CombatMath.ElementType.NONE: 10 })
	stats.seal_tier = m_data.get("tier", CombatMath.SealCardTier.NORMAL)
	stats.exp_reward = int(25 * wave_mult)
	stats.gold_reward_min = int(10 * wave_mult)
	stats.gold_reward_max = int(35 * wave_mult)
	
	health.current_hp = stats.max_hp
	health.current_mp = stats.max_mp
	health.health_changed.emit(health.current_hp, stats.max_hp)

func _on_init_custom() -> void:
	pass

func _process(delta: float) -> void:
	anim_timer += delta
	state_timer += delta
	attack_cooldown -= delta
	queue_redraw()

func _physics_process(delta: float) -> void:
	if is_stunned or ai_state == AIState.STUNNED or ai_state == AIState.DEAD:
		velocity = Vector2.ZERO
		move_and_slide()
		return
		
	match ai_state:
		AIState.IDLE:
			velocity = velocity.move_toward(Vector2.ZERO, 400 * delta)
			_check_for_aggro()
			if state_timer >= randf_range(1.5, 3.0):
				_start_wander()
				
		AIState.WANDER:
			var to_w = wander_target - global_position
			if to_w.length() < 10.0 or state_timer >= 3.0:
				ai_state = AIState.IDLE
				state_timer = 0.0
			else:
				velocity = to_w.normalized() * (stats.move_speed * 0.4)
			_check_for_aggro()
			
		AIState.CHASE:
			if not is_instance_valid(target):
				target = _select_best_target()
				if not target:
					ai_state = AIState.IDLE
					state_timer = 0.0
			else:
				var dist = global_position.distance_to(target.global_position)
				if dist <= attack_range and attack_cooldown <= 0.0:
					_start_attack()
				else:
					var dir = (target.global_position - global_position).normalized()
					velocity = dir * stats.move_speed
					
		AIState.ATTACK:
			velocity = Vector2.ZERO
			_process_attack_state(delta)
			
		AIState.HURT:
			velocity = velocity.move_toward(Vector2.ZERO, 600 * delta)
			if state_timer >= 0.25:
				ai_state = AIState.CHASE if is_instance_valid(target) else AIState.IDLE
				state_timer = 0.0
				
	move_and_slide()

func _select_best_target() -> Node2D:
	if is_wave_attacker:
		var goddess = get_tree().get_first_node_in_group("goddess") as Node2D
		if Global.player and is_instance_valid(Global.player):
			var dist_p = global_position.distance_to(Global.player.global_position)
			if dist_p < 200.0:
				return Global.player
		if goddess and is_instance_valid(goddess):
			return goddess
	if Global.player and is_instance_valid(Global.player):
		return Global.player
	return null

func _check_for_aggro() -> void:
	target = _select_best_target()
	if target:
		var d = global_position.distance_to(target.global_position)
		if is_wave_attacker or d <= aggro_range:
			ai_state = AIState.CHASE
			state_timer = 0.0

func _start_wander() -> void:
	if is_wave_attacker:
		ai_state = AIState.CHASE
		target = _select_best_target()
		return
	ai_state = AIState.WANDER
	state_timer = 0.0
	var offset = Vector2(randf_range(-100, 100), randf_range(-100, 100))
	wander_target = spawn_pos + offset

func _start_attack() -> void:
	ai_state = AIState.ATTACK
	state_timer = 0.0
	attack_cooldown = attack_cooldown_time
	
	var dir = (target.global_position - global_position).normalized() if is_instance_valid(target) else Vector2.DOWN
	hitbox.position = dir * (20.0 * monster_scale)
	hitbox.damage_multiplier = 1.0
	hitbox.reset_hit_list()

func _process_attack_state(_delta: float) -> void:
	if state_timer >= 0.2 and hitbox_collision.disabled:
		hitbox_collision.disabled = false
		SoundManager.play_swing()
	elif state_timer >= 0.35 and not hitbox_collision.disabled:
		hitbox_collision.disabled = true
	elif state_timer >= 0.55:
		ai_state = AIState.CHASE if is_instance_valid(target) else AIState.IDLE
		state_timer = 0.0

func set_stunned(val: bool) -> void:
	is_stunned = val
	ai_state = AIState.STUNNED if val else AIState.IDLE
	hitbox_collision.disabled = true

func _on_hit_received(_dmg: int, _is_crit: bool, _is_effective: bool, knock_dir: Vector2, knock_force: float) -> void:
	if ai_state != AIState.DEAD:
		ai_state = AIState.HURT
		state_timer = 0.0
		hitbox_collision.disabled = true
		velocity = knock_dir * knock_force
		target = Global.player

func _on_died() -> void:
	ai_state = AIState.DEAD
	hitbox_collision.disabled = true
	hurtbox.set_deferred("monitoring", false)
	
	var gold_mult = 2 if BuffManager.has_buff("gold_master") else 1
	Global.add_exp(stats.exp_reward)
	var gold_val = randi_range(stats.gold_reward_min, stats.gold_reward_max) * gold_mult
	Global.add_gold(gold_val)
	EventBus.damage_spawned.emit(global_position + Vector2(0, -20), "+%d EXP" % stats.exp_reward, Color(0.3, 0.9, 1.0), false, false)
	
	_spawn_drops()
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.45)
	tween.finished.connect(func(): queue_free())

func _spawn_drops() -> void:
	var bonus_chance = 1.5 if BuffManager.has_buff("gold_master") else 1.0
	
	if randf() < (0.55 * bonus_chance):
		var d = drop_item_scene.instantiate()
		d.global_position = global_position
		get_parent().add_child(d)
		d.setup("magic_stone", "魔石", "material", 1, 0, Color(0.6, 0.3, 0.9))
		
	if randf() < 0.25:
		var d = drop_item_scene.instantiate()
		d.global_position = global_position
		get_parent().add_child(d)
		d.setup("potion_hp_small", "生命之藥(200)", "consumable", 1, 0, Color(0.2, 0.9, 0.3))
		
	if randf() < (0.20 * bonus_chance):
		var card_id = "seal_card_normal"
		var card_name = "普卡封印卡"
		var c_tier = stats.seal_tier
		if c_tier == CombatMath.SealCardTier.SILVER:
			card_id = "seal_card_silver"
			card_name = "銀卡封印卡"
		elif c_tier == CombatMath.SealCardTier.GOLD:
			card_id = "seal_card_gold"
			card_name = "金卡封印卡"
			
		var d = drop_item_scene.instantiate()
		d.global_position = global_position
		get_parent().add_child(d)
		d.setup(card_id, card_name, "seal_card", 1, 0, Color(0.85, 0.85, 0.9))

func _draw() -> void:
	var cur_tex: Texture2D = null
	if not anim_frames.is_empty():
		var f_idx = int(fmod(anim_timer * 5.0, float(anim_frames.size())))
		cur_tex = anim_frames[f_idx]
		
	if cur_tex:
		draw_circle(Vector2(0, 12), 16.0 * monster_scale, Color(0, 0, 0, 0.35))
		if is_boss:
			var aura_r = 45.0 * monster_scale + sin(anim_timer * 10.0) * 5.0
			draw_arc(Vector2.ZERO, aura_r, 0, TAU, 32, color_sub, 3.5)
			
		var tex_size = cur_tex.get_size()
		var target_h = 76.0 * monster_scale
		var tex_scale = target_h / max(1.0, tex_size.y)
		var draw_w = tex_size.x * tex_scale
		var draw_h = target_h
		var bounce = sin(anim_timer * 6.0) * 1.5
		var dest_rect = Rect2(-draw_w / 2.0, -draw_h + 12 + bounce, draw_w, draw_h)
		draw_texture_rect(cur_tex, dest_rect, false)
	else:
		ProceduralMonsterDrawer.draw_monster(self, drawer_type, color_main, color_sub, anim_timer, monster_scale * 1.5, is_boss)
	
	# 怪物頭頂血條
	if ai_state != AIState.DEAD and health and stats:
		var bar_w = 56.0 * monster_scale
		var bar_h = 5.0
		var bar_pos = Vector2(-bar_w / 2.0, -48.0 * monster_scale)
		var hp_r = health.get_hp_ratio()
		
		draw_rect(Rect2(bar_pos, Vector2(bar_w, bar_h)), Color(0.1, 0.1, 0.1, 0.8), true)
		var hp_col = Color(0.2, 0.9, 0.3) if hp_r > 0.3 else Color(1.0, 0.2, 0.2)
		draw_rect(Rect2(bar_pos, Vector2(bar_w * hp_r, bar_h)), hp_col, true)
		draw_rect(Rect2(bar_pos, Vector2(bar_w, bar_h)), Color(0, 0, 0, 0.9), false, 1.0)
