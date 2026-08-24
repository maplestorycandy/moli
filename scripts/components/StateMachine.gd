extends Node
class_name StateMachine

@export var initial_state: State
var current_state: State
var states: Dictionary = {}

func _ready() -> void:
	await owner.ready
	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.state_machine = self
			child.character = owner as CharacterBody2D
			
	if initial_state:
		initial_state.enter()
		current_state = initial_state

func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

func transition_to(target_state_name: String) -> void:
	var key = target_state_name.to_lower()
	if not states.has(key):
		return
		
	var next_state = states[key]
	if current_state == next_state:
		return
		
	if current_state:
		current_state.exit()
		
	current_state = next_state
	current_state.enter()
