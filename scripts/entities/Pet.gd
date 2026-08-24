extends CharacterBody2D
class_name PetCompanion

const ProceduralMonsterDrawer = preload("res://scripts/world/ProceduralMonsterDrawer.gd")

@export var follow_distance: float = 65.0
@export var speed: float = 180.0

var pet_data: Dictionary = {}
var anim_frames: Array[Texture2D] = []

var target_enemy: Node2D = null
var attack_timer: float = 0.0
var attack_cooldown: float = 1.4
var is_attacking: bool = false
var anim_timer: float = 0.0

@onready var hurtbox: HurtboxComponent = $HurtboxComponent
@onready var hitbox: HitboxComponent = $HitboxComponent
@onready var collision_shape: CollisionShape2D = $HitboxComponent/CollisionShape2D

func _ready() -> void:
	add_to_group("pet")
	hitbox.is_player_team = true
	hitbox.attacker_node = self
	collision_shape.disabled = true
	
	EventBus.pet_command_changed.connect(_on_command_changed)
	EventBus.pet_stats_changed.connect(_load_active_pet_data)
	EventBus.pet_summoned.connect(func(_d): _load_active_pet_data())
	EventBus.pet_recalled.connect(func(): _load_active_pet_data())
	
	_load_active_pet_data()

func _load_active_pet_data() -> void:
	pet_data = Global.get_active_pet()
	if pet_data.is_empty():
		visible = false
		set_physics_process(false)
		anim_frames.clear()
	else:
		visible = true
		set_physics_process(true)
		hitbox.skill_name = pet_data.get("active_skill", "寵物攻擊")
		if Global.player and is_instance_valid(Global.player):
			global_position = Global.player.global_position + Vector2(-30, 20)
			
		anim_frames.clear()
		var num_str = str(pet_data.get("num", ""))
		if num_str != "":
			for i in range(4):
				var f_path = "res://assets/sprites/monsters/%s_%d.png" % [num_str, i]
				if ResourceLoader.exists(f_path):
					anim_frames.append(load(f_path))
			if anim_frames.is_empty():
				var single_path = "res://assets/sprites/monsters/%s.png" % num_str
				if ResourceLoader.exists(single_path):
					anim_frames.append(load(single_path))

func _on_command_changed(_new_mode: String) -> void:
	pass

func _physics_process(delta: float) -> void:
	anim_timer += delta
	attack_timer -= delta
	
	if not Global.player or not is_instance_valid(Global.player):
		return
		
	var player_pos = Global.player.global_position
	var dist_to_player = global_position.distance_to(player_pos)
	
	# 戰術行為決策
	match Global.pet_command_mode:
		"GUARD":
			var guard_pos = player_pos + Global.player.facing_direction * 35.0
			var to_guard = guard_pos - global_position
			if to_guard.length() > 10.0:
				velocity = to_guard.normalized() * speed
			else:
				velocity = Vector2.ZERO
			move_and_slide()
			
		"STANDBY":
			velocity = Vector2.ZERO
			move_and_slide()
			
		"FOLLOW_ATTACK":
			if not is_instance_valid(target_enemy) or target_enemy.is_queued_for_deletion():
				target_enemy = _find_nearest_enemy()
				
			if target_enemy and global_position.distance_to(target_enemy.global_position) < 240.0:
				var dist_to_enemy = global_position.distance_to(target_enemy.global_position)
				if dist_to_enemy > 40.0:
					var dir = (target_enemy.global_position - global_position).normalized()
					velocity = dir * (speed * 1.15)
					move_and_slide()
				else:
					velocity = Vector2.ZERO
					move_and_slide()
					if attack_timer <= 0.0:
						_perform_pet_attack(target_enemy)
			else:
				if dist_to_player > follow_distance:
					var dir = (player_pos - global_position).normalized()
					velocity = dir * speed
					move_and_slide()
				else:
					velocity = velocity.move_toward(Vector2.ZERO, 600 * delta)
					move_and_slide()
					
	queue_redraw()

func _find_nearest_enemy() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest: Node2D = null
	var min_dist = 300.0
	for e in enemies:
		if is_instance_valid(e) and not e.is_queued_for_deletion():
			var d = global_position.distance_to(e.global_position)
			if d < min_dist:
				min_dist = d
				closest = e
	return closest

func _perform_pet_attack(enemy: Node2D) -> void:
	attack_timer = attack_cooldown
	is_attacking = true
	var dir = (enemy.global_position - global_position).normalized()
	hitbox.position = dir * 24.0
	hitbox.damage_multiplier = 1.35
	hitbox.reset_hit_list()
	collision_shape.disabled = false
	SoundManager.play_swing()
	
	if Global.player and global_position.distance_to(Global.player.global_position) < 90.0:
		EventBus.combo_dual_attack_triggered.emit(enemy.global_position)
	
	get_tree().create_timer(0.2).timeout.connect(func():
		collision_shape.disabled = true
		is_attacking = false
	)

func _draw() -> void:
	if pet_data.is_empty():
		return
		
	var m_scale = pet_data.get("scale", 1.0)
	var cur_tex: Texture2D = null
	if not anim_frames.is_empty():
		var f_idx = int(fmod(anim_timer * 5.0, float(anim_frames.size())))
		cur_tex = anim_frames[f_idx]
		
	if cur_tex:
		draw_circle(Vector2(0, 12), 14.0 * m_scale, Color(0, 0, 0, 0.3))
		var tex_size = cur_tex.get_size()
		var target_h = 72.0 * m_scale
		var tex_scale = target_h / max(1.0, tex_size.y)
		var draw_w = tex_size.x * tex_scale
		var draw_h = target_h
		var bounce = sin(anim_timer * 6.0) * 1.5
		var dest_rect = Rect2(-draw_w / 2.0, -draw_h + 12 + bounce, draw_w, draw_h)
		draw_texture_rect(cur_tex, dest_rect, false)
	else:
		var d_type = pet_data.get("drawer_type", "humanoid")
		var c_main = pet_data.get("color_main", Color(0.25, 0.75, 0.35))
		var c_sub = pet_data.get("color_sub", Color(0.6, 1.0, 0.7))
		ProceduralMonsterDrawer.draw_monster(self, d_type, c_main, c_sub, anim_timer, m_scale * 1.5, false)
	
	# 寵物忠誠綠點
	draw_circle(Vector2(0, -46 * m_scale), 3.5, Color(0.2, 1.0, 0.4))
