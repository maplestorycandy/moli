extends CharacterBody2D
class_name Player

@export var acceleration: float = 2400.0
@export var friction: float = 1600.0

enum ActionState {
	IDLE,
	MOVE,
	ATTACK,
	DODGE,
	SKILL_COMBO,
	SKILL_FORCE_STRIKE,
	CAST_MAGIC
}

var current_state: ActionState = ActionState.IDLE
var facing_direction: Vector2 = Vector2.DOWN
var aim_direction: Vector2 = Vector2.RIGHT

var state_timer: float = 0.0
var combo_step: int = 0
var dodge_direction: Vector2 = Vector2.ZERO
var dodge_speed: float = 420.0
var is_invulnerable: bool = false
var anim_timer: float = 0.0
var i_frame_timer: float = 0.0

# 英雄 Skin 外觀系統
var skin_data: Dictionary = {}
var skin_anim_frames: Array[Texture2D] = []

# 預載技能與投射物場景
const MagicSpell = preload("res://scripts/combat/MagicSpell.gd")
var kiblast_scene = preload("res://scenes/combat/KiBlastProjectile.tscn")
var magic_spell_scene = preload("res://scenes/combat/MagicSpell.tscn")
var rapid_arrow_scene = preload("res://scenes/combat/RapidArrow.tscn")
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
	
	if has_node("/root/SkinManager"):
		var sm = get_node("/root/SkinManager")
		sm.skin_changed.connect(_on_skin_changed)
		_on_skin_changed(sm.get_current_skin())

func _on_skin_changed(new_skin: Dictionary) -> void:
	skin_data = new_skin
	Global.player_name = new_skin.get("name", "辛 (Shin)").split(" ")[0]
	var num_str = str(new_skin.get("num", "001"))
	
	skin_anim_frames.clear()
	if not new_skin.get("is_custom_draw", false) and num_str != "":
		for i in range(4):
			var f_path = "res://assets/sprites/monsters/%s_%d.png" % [num_str, i]
			if ResourceLoader.exists(f_path):
				skin_anim_frames.append(load(f_path))
		if skin_anim_frames.is_empty():
			var s_path = "res://assets/sprites/monsters/%s.png" % num_str
			if ResourceLoader.exists(s_path):
				skin_anim_frames.append(load(s_path))
				
	EventBus.player_stats_changed.emit()

func _input(event: InputEvent) -> void:
	# 處理滑鼠瞄準
	if event is InputEventMouse:
		var mouse_pos = get_global_mouse_position()
		aim_direction = (mouse_pos - global_position).normalized()
		
	# 處理按鍵直接施法與操作
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE: _start_dodge()
			KEY_1: _start_skill_combo()
			KEY_2: _start_skill_force_strike()
			KEY_3: _start_skill_kiblast()
			KEY_4: _cast_rapid_fire()
			KEY_5: _cast_magic(MagicSpell.SpellType.DRAIN, MagicSpell.SpellTier.SINGLE, 6.0, 20)
			KEY_6: _cast_magic(MagicSpell.SpellType.MIND_WAVE, MagicSpell.SpellTier.STRONG, 9.5, 30)
			KEY_7: _cast_magic(MagicSpell.SpellType.METEOR, MagicSpell.SpellTier.STRONG, 8.5, 25)
			KEY_8: _cast_magic(MagicSpell.SpellType.ICE, MagicSpell.SpellTier.STRONG, 8.5, 25)
			KEY_9: _cast_magic(MagicSpell.SpellType.FIRE, MagicSpell.SpellTier.STRONG, 8.5, 25)
			KEY_0: _cast_magic(MagicSpell.SpellType.WIND, MagicSpell.SpellTier.STRONG, 8.5, 25)
			KEY_Q: _cast_magic(MagicSpell.SpellType.METEOR, MagicSpell.SpellTier.MEGA, 20.0, 50)
			KEY_E: _cast_magic(MagicSpell.SpellType.ICE, MagicSpell.SpellTier.MEGA, 20.0, 50)
			KEY_R: _cast_magic(MagicSpell.SpellType.FIRE, MagicSpell.SpellTier.MEGA, 20.0, 50)
			KEY_F: _cast_magic(MagicSpell.SpellType.WIND, MagicSpell.SpellTier.MEGA, 20.0, 50)
			KEY_G: _use_seal_card()
			KEY_T: _cycle_pet_command()

	# 滑鼠左鍵普攻 (若未點擊在 UI 上)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_start_attack()

func _process(delta: float) -> void:
	anim_timer += delta
	if i_frame_timer > 0.0:
		i_frame_timer -= delta
		if i_frame_timer <= 0.0:
			hurtbox.is_invulnerable = false
			is_invulnerable = false
			
	var mouse_pos = get_global_mouse_position()
	aim_direction = (mouse_pos - global_position).normalized()
	_update_state(delta)
	queue_redraw()

func _physics_process(delta: float) -> void:
	# 永遠支援 WASD / 方向鍵 / 滑鼠右鍵移動
	var move_vec = Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP) or Input.is_action_pressed("move_up"): move_vec.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN) or Input.is_action_pressed("move_down"): move_vec.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT) or Input.is_action_pressed("move_left"): move_vec.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT) or Input.is_action_pressed("move_right"): move_vec.x += 1.0
	
	if move_vec == Vector2.ZERO and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		var mouse_pos = get_global_mouse_position()
		var diff = mouse_pos - global_position
		if diff.length() > 15.0:
			move_vec = diff.normalized()

	if move_vec != Vector2.ZERO:
		facing_direction = move_vec.normalized()
		
	match current_state:
		ActionState.DODGE:
			velocity = dodge_direction * dodge_speed
		ActionState.SKILL_COMBO:
			velocity = facing_direction * (Global.move_speed * 1.5)
		_:
			if move_vec != Vector2.ZERO:
				velocity = velocity.move_toward(move_vec.normalized() * Global.move_speed, acceleration * delta)
				current_state = ActionState.MOVE
			else:
				velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
				if current_state == ActionState.MOVE:
					current_state = ActionState.IDLE
					
	move_and_slide()

func _start_dodge() -> void:
	var move_vec = Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): move_vec.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): move_vec.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): move_vec.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): move_vec.x += 1.0
	if move_vec == Vector2.ZERO:
		move_vec = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		
	dodge_direction = move_vec.normalized() if move_vec != Vector2.ZERO else facing_direction
	current_state = ActionState.DODGE
	state_timer = 0.0
	is_invulnerable = true
	hurtbox.is_invulnerable = true
	SoundManager.play_swing()

func _start_attack() -> void:
	current_state = ActionState.ATTACK
	state_timer = 0.0
	facing_direction = aim_direction
	
	var is_dual = BuffManager.has_buff("dual_attack")
	var dmg_mult = 2.5 if not is_dual else 3.8
	_trigger_weapon_hitbox("普通攻擊", dmg_mult, 0.1, 0.22)
	SoundManager.play_swing()

func _start_skill_combo() -> void:
	var mp_cost = 15
	if Global.mp < mp_cost:
		_show_not_enough_mp()
		return
	Global.consume_mp(mp_cost)
	
	current_state = ActionState.SKILL_COMBO
	state_timer = 0.0
	combo_step = 0
	facing_direction = aim_direction
	_process_combo_step()

func _process_combo_step() -> void:
	combo_step += 1
	var is_master = BuffManager.has_buff("combo_master")
	var max_step = 6 if is_master else 4
	
	_trigger_weapon_hitbox("連擊", 3.5 + (combo_step * 0.4), 0.03, 0.12)
	SoundManager.play_swing()
	EventBus.screen_shake_requested.emit(6.0, 0.1)
	
	if combo_step < max_step:
		get_tree().create_timer(0.1).timeout.connect(func():
			if current_state == ActionState.SKILL_COMBO:
				_process_combo_step()
		)
	else:
		get_tree().create_timer(0.18).timeout.connect(func():
			if current_state == ActionState.SKILL_COMBO:
				current_state = ActionState.IDLE
		)

func _start_skill_force_strike() -> void:
	var mp_cost = 25
	if Global.mp < mp_cost:
		_show_not_enough_mp()
		return
	Global.consume_mp(mp_cost)
	
	current_state = ActionState.SKILL_FORCE_STRIKE
	state_timer = 0.0
	facing_direction = aim_direction
	SoundManager.play_magic()

func _start_skill_kiblast() -> void:
	var mp_cost = 20
	if Global.mp < mp_cost:
		_show_not_enough_mp()
		return
	Global.consume_mp(mp_cost)
	
	facing_direction = aim_direction
	var blast = kiblast_scene.instantiate()
	blast.global_position = global_position + aim_direction * 20.0
	get_parent().add_child(blast)
	
	var is_master = BuffManager.has_buff("qigong_split")
	var count = 5 if is_master else 3
	var atk_val = int(Global.atk * 6.5)
	blast.setup(aim_direction, atk_val, count)
	SoundManager.play_magic()

func _cast_rapid_fire() -> void:
	var mp_cost = 25
	if Global.mp < mp_cost:
		_show_not_enough_mp()
		return
	Global.consume_mp(mp_cost)
	
	facing_direction = aim_direction
	var arrow_count = 8
	var dmg_per_arrow = int(Global.atk * 3.2)
	
	for i in range(arrow_count):
		var spread_angle = randf_range(-0.45, 0.45)
		var arrow_dir = aim_direction.rotated(spread_angle)
		var arrow = rapid_arrow_scene.instantiate()
		arrow.global_position = global_position + arrow_dir * 18.0
		get_parent().add_child(arrow)
		arrow.setup(arrow_dir, dmg_per_arrow)
		
	SoundManager.play_swing()
	EventBus.screen_shake_requested.emit(8.0, 0.2)

func _cast_magic(spell_type: int, spell_tier: int, dmg_multiplier: float, mp_cost: int) -> void:
	if Global.mp < mp_cost:
		_show_not_enough_mp()
		return
	Global.consume_mp(mp_cost)
	
	facing_direction = aim_direction
	var target_p = get_global_mouse_position()
	
	if spell_type == MagicSpell.SpellType.MIND_WAVE:
		target_p = global_position
		
	var spell = magic_spell_scene.instantiate()
	spell.global_position = target_p
	get_parent().add_child(spell)
	
	var dmg = int(Global.atk * dmg_multiplier)
	spell.setup(spell_type, spell_tier, dmg)

func _use_seal_card() -> void:
	var card_item = null
	for it in Global.inventory:
		if it.get("type") == "seal_card" and it.get("count", 0) > 0:
			card_item = it
			break
			
	if not card_item:
		EventBus.damage_spawned.emit(global_position + Vector2(0, -30), "沒有封印卡！", Color(1, 0.4, 0.4), false, false)
		return
		
	card_item["count"] -= 1
	if card_item["count"] <= 0:
		Global.inventory.erase(card_item)
	EventBus.inventory_updated.emit()
	
	var seal_proj = seal_card_scene.instantiate()
	seal_proj.global_position = global_position
	get_parent().add_child(seal_proj)
	seal_proj.setup(aim_direction, card_item.get("tier", CombatMath.SealCardTier.NORMAL))
	SoundManager.play_swing()

func _cycle_pet_command() -> void:
	match Global.pet_command_mode:
		"FOLLOW_ATTACK": Global.pet_command_mode = "GUARD"
		"GUARD": Global.pet_command_mode = "STANDBY"
		"STANDBY": Global.pet_command_mode = "FOLLOW_ATTACK"
	EventBus.pet_command_changed.emit(Global.pet_command_mode)

func _trigger_weapon_hitbox(skill_name: String, dmg_mult: float, active_delay: float, duration: float) -> void:
	weapon_hitbox.skill_name = skill_name
	weapon_hitbox.damage_multiplier = dmg_mult
	weapon_hitbox.position = facing_direction * 28.0
	
	get_tree().create_timer(active_delay).timeout.connect(func():
		weapon_collision.disabled = false
		weapon_hitbox.reset_hit_list()
	)
	get_tree().create_timer(active_delay + duration).timeout.connect(func():
		weapon_collision.disabled = true
	)

func _update_state(delta: float) -> void:
	state_timer += delta
	match current_state:
		ActionState.DODGE:
			if state_timer >= 0.28:
				is_invulnerable = false
				hurtbox.is_invulnerable = false
				current_state = ActionState.IDLE
		ActionState.ATTACK:
			if state_timer >= 0.25:
				current_state = ActionState.IDLE
		ActionState.SKILL_FORCE_STRIKE:
			if state_timer >= 0.35 and weapon_collision.disabled:
				_trigger_weapon_hitbox("乾坤一擲", 12.0, 0.0, 0.25)
				EventBus.screen_shake_requested.emit(18.0, 0.35)
				SoundManager.play_crit()
			elif state_timer >= 0.55:
				current_state = ActionState.IDLE

func _show_not_enough_mp() -> void:
	EventBus.damage_spawned.emit(global_position + Vector2(0, -30), "MP 不足！", Color(0.4, 0.6, 1.0), false, false)

func _on_hit_received(dmg: int, _is_crit: bool, _is_effective: bool, knock_dir: Vector2, knock_force: float) -> void:
	if is_invulnerable:
		return
		
	Global.take_damage(dmg)
	EventBus.screen_shake_requested.emit(5.0, 0.15)
	SoundManager.play_hurt()
	
	# 給予 0.35 秒無敵受擊冷卻，不再打斷玩家移動！
	i_frame_timer = 0.35
	hurtbox.is_invulnerable = true
	is_invulnerable = true
	velocity += knock_dir * (knock_force * 0.3)
	
	if Global.hp <= 0:
		EventBus.show_banner_notification.emit("勇者倒下了...", "愛謝拉女神的光芒將你喚回！")
		Global.hp = Global.max_hp
		global_position = Vector2(600, 500)
		EventBus.player_health_changed.emit(Global.hp, Global.max_hp)

# --- 繪製主角 Skin 視覺造型 ---
func _draw() -> void:
	var p_scale = skin_data.get("scale", 1.0)
	
	# 陰影
	draw_custom_ellipse(Vector2(0, 20), 24.0 * p_scale, 12.0 * p_scale, Color(0, 0, 0, 0.35))
	
	# 翻滾殘影
	if current_state == ActionState.DODGE:
		draw_circle(Vector2.ZERO, 26.0 * p_scale, Color(0.4, 0.8, 1.0, 0.35))
		
	# 受擊閃白
	if i_frame_timer > 0.0 and fmod(i_frame_timer, 0.1) > 0.05:
		draw_circle(Vector2(0, -10), 22.0 * p_scale, Color(1.0, 0.3, 0.3, 0.4))
		
	# 乾坤一擲蓄力氣場
	if current_state == ActionState.SKILL_FORCE_STRIKE and state_timer < 0.35:
		var aura_r = (38.0 + sin(state_timer * 25.0) * 8.0) * p_scale
		draw_arc(Vector2.ZERO, aura_r, 0, TAU, 28, Color(1.0, 0.7, 0.1, 0.85), 4.5)
		draw_circle(Vector2.ZERO, aura_r * 0.6, Color(1.0, 0.4, 0.1, 0.35))
		
	var cur_tex: Texture2D = null
	if not skin_anim_frames.is_empty():
		var f_idx = int(fmod(anim_timer * 5.0, float(skin_anim_frames.size())))
		cur_tex = skin_anim_frames[f_idx]
		
	if cur_tex:
		var tex_size = cur_tex.get_size()
		var target_h = 76.0 * p_scale
		var tex_scale = target_h / max(1.0, tex_size.y)
		var draw_w = tex_size.x * tex_scale
		var draw_h = target_h
		var bounce = sin(anim_timer * 6.0) * 1.5
		var dest_rect = Rect2(-draw_w / 2.0, -draw_h + 16 + bounce, draw_w, draw_h)
		draw_texture_rect(cur_tex, dest_rect, false)
	else:
		var cape_off = -facing_direction * 9.0
		draw_circle(cape_off + Vector2(0, 3), 18.0, Color(0.15, 0.35, 0.85))
		draw_circle(Vector2(0, 3), 16.0, Color(0.2, 0.45, 0.95))
		draw_circle(Vector2(0, 6), 10.0, Color(0.85, 0.85, 0.95))
		
		draw_circle(Vector2(0, -14), 14.0, Color(1.0, 0.85, 0.2))
		draw_circle(Vector2(0, -11), 11.0, Color(0.98, 0.8, 0.68))
		draw_circle(Vector2(3, -20), 8.0, Color(1.0, 0.88, 0.2))
		draw_circle(Vector2(-5, -19), 7.0, Color(1.0, 0.88, 0.2))
		
		var eye_offset = facing_direction.normalized() * 4.5
		draw_circle(Vector2(-3, -12) + eye_offset, 2.2, Color(0.1, 0.2, 0.5))
		draw_circle(Vector2(3, -12) + eye_offset, 2.2, Color(0.1, 0.2, 0.5))
		
		var sword_pos = facing_direction * 24.0 + Vector2(0, 3)
		var sword_angle = facing_direction.angle()
		var hilt = sword_pos
		var tip = hilt + Vector2.from_angle(sword_angle) * 32.0
		draw_line(hilt, tip, Color(0.9, 0.95, 1.0), 5.0)
		draw_line(hilt, tip, Color.WHITE, 2.5)
		draw_circle(hilt, 4.5, Color(0.9, 0.7, 0.1))
		
		var shield_pos = facing_direction.rotated(PI/2) * 16.0 + Vector2(0, 3)
		draw_circle(shield_pos, 8.0, Color(0.85, 0.7, 0.2))
		draw_circle(shield_pos, 5.0, Color(0.2, 0.45, 0.95))

	# 揮劍刀光弧線特效
	if current_state in [ActionState.ATTACK, ActionState.SKILL_COMBO, ActionState.SKILL_FORCE_STRIKE] and not weapon_collision.disabled:
		var slash_col = Color(0.6, 0.9, 1.0, 0.9)
		var s_angle = facing_direction.angle()
		if current_state == ActionState.SKILL_FORCE_STRIKE:
			slash_col = Color(1.0, 0.4, 0.1, 0.95)
			draw_arc(Vector2.ZERO, 65.0 * p_scale, s_angle - 1.2, s_angle + 1.2, 20, slash_col, 10.0)
		else:
			draw_arc(Vector2.ZERO, 48.0 * p_scale, s_angle - 0.9, s_angle + 0.9, 20, slash_col, 6.0)

func draw_custom_ellipse(center: Vector2, rx: float, ry: float, color: Color) -> void:
	var points = PackedVector2Array()
	for i in range(24):
		var rad = (TAU / 24.0) * i
		points.append(center + Vector2(cos(rad) * rx, sin(rad) * ry))
	draw_colored_polygon(points, color)
