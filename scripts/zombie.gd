extends CharacterBody3D

# Zombie constants
const WALK_SPEED = 2.0
const CHASE_SPEED = 4.0
const ATTACK_DAMAGE = 5.0
const ATTACK_COOLDOWN = 0.8  # Match animation length
const DETECTION_RANGE = 8.0
const ATTACK_RANGE = 2.0

# States
enum ZombieState {
	WANDERING,
	CHASING,
	ATTACKING,
	DEAD
}

# Variables
var current_state = ZombieState.WANDERING
var previous_state = ZombieState.WANDERING
var player_ref = null
var last_player_position = Vector3.ZERO
var wander_direction = Vector3.ZERO
var attack_timer = 0.0
var health = 50.0
var is_attacking_animation = false

# Node references
@onready var detection_area = $DetectionArea
@onready var attack_range = $AttackRange
@onready var raycast = $RayCast3D
@onready var animation_player = $AnimationPlayer
@onready var walk_timer = $WalkTimer
@onready var mesh_instance = $MeshInstance3D
@onready var left_arm = $LeftArm
@onready var right_arm = $RightArm

# Arm materials
var green_material: StandardMaterial3D
var red_material: StandardMaterial3D

# Get gravity
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	# Create arm materials
	_create_arm_materials()
	
	# Connect area signals
	detection_area.body_entered.connect(_on_detection_area_entered)
	detection_area.body_exited.connect(_on_detection_area_exited)
	attack_range.body_entered.connect(_on_attack_range_entered)
	attack_range.body_exited.connect(_on_attack_range_exited)
	
	# Connect animation signals
	animation_player.animation_finished.connect(_on_animation_finished)
	
	# Connect walk timer
	walk_timer.timeout.connect(_on_walk_timer_timeout)
	
	# Set initial wander direction
	_set_new_wander_direction()
	
	# Set initial arm state
	_set_arms_green()
	animation_player.play("idle")
	
	# Change zombie color to distinguish from player
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.GREEN
	mesh_instance.material_override = material

func _physics_process(delta):
	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Update attack timer
	if attack_timer > 0:
		attack_timer -= delta
	
	# Check for state changes and update arms/animations
	if current_state != previous_state:
		_on_state_changed()
		previous_state = current_state
	
	# State machine
	match current_state:
		ZombieState.WANDERING:
			_handle_wandering(delta)
		ZombieState.CHASING:
			_handle_chasing(delta)
		ZombieState.ATTACKING:
			_handle_attacking(delta)
		ZombieState.DEAD:
			_handle_dead(delta)
		ZombieState.DEAD:
			_handle_dead(delta)
	
	move_and_slide()

func _handle_wandering(_delta):
	# Move in wander direction
	velocity.x = wander_direction.x * WALK_SPEED
	velocity.z = wander_direction.z * WALK_SPEED
	
	# Face movement direction
	if wander_direction.length() > 0:
		look_at(global_position + wander_direction, Vector3.UP)

func _handle_chasing(_delta):
	if player_ref == null:
		current_state = ZombieState.WANDERING
		return
	
	# Check if player is running and in detection range
	var player_script = player_ref.get_script()
	var is_player_running = false
	if player_script and player_ref.has_method("_input"):
		is_player_running = Input.is_action_pressed("run")
	
	# Check line of sight to player
	var can_see_player = _can_see_player()
	
	# If player is walking and behind wall, lose track
	if not is_player_running and not can_see_player:
		current_state = ZombieState.WANDERING
		player_ref = null
		return
	
	# Move towards player
	var direction = (player_ref.global_position - global_position).normalized()
	velocity.x = direction.x * CHASE_SPEED
	velocity.z = direction.z * CHASE_SPEED
	
	# Face player
	look_at(player_ref.global_position, Vector3.UP)
	
	last_player_position = player_ref.global_position

func _handle_attacking(_delta):
	# Stop moving during attack
	velocity.x = 0
	velocity.z = 0
	
	# Face player during attack
	if player_ref:
		look_at(player_ref.global_position, Vector3.UP)
	
	if player_ref and attack_timer <= 0 and not is_attacking_animation:
		# Start attack animation and set timer
		is_attacking_animation = true
		animation_player.play("attack")
		attack_timer = ATTACK_COOLDOWN
		
		# Deal damage immediately when attack starts
		if player_ref.has_method("take_damage"):
			player_ref.take_damage(ATTACK_DAMAGE)
			print("Zombie attacks player for ", ATTACK_DAMAGE, " damage!")

func _handle_dead(_delta):
	# Stop all movement
	velocity.x = 0
	velocity.z = 0

func _can_see_player():
	if player_ref == null:
		return false
	
	# Cast ray to player
	raycast.target_position = to_local(player_ref.global_position)
	raycast.force_raycast_update()
	
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		return collider == player_ref
	
	return true

func _set_new_wander_direction():
	# Random direction for wandering
	var angle = randf() * TAU
	wander_direction = Vector3(cos(angle), 0, sin(angle))

func _on_detection_area_entered(body):
	if body.is_in_group("player"):
		player_ref = body
		current_state = ZombieState.CHASING

func _on_detection_area_exited(body):
	if body.is_in_group("player") and body == player_ref:
		# Only lose track if player is walking and can't see them
		var is_player_running = Input.is_action_pressed("run")
		if not is_player_running and not _can_see_player():
			current_state = ZombieState.WANDERING
			player_ref = null

func _on_attack_range_entered(body):
	if body.is_in_group("player") and current_state == ZombieState.CHASING:
		current_state = ZombieState.ATTACKING

func _on_attack_range_exited(body):
	if body.is_in_group("player") and current_state == ZombieState.ATTACKING:
		current_state = ZombieState.CHASING

func _on_walk_timer_timeout():
	if current_state == ZombieState.WANDERING:
		_set_new_wander_direction()

func _on_animation_finished(animation_name):
	if animation_name == "attack":
		is_attacking_animation = false

func take_damage(damage):
	health -= damage
	if health <= 0:
		die()

func die():
	current_state = ZombieState.DEAD
	print("Zombie died!")
	# Change color to indicate death
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.GRAY
	mesh_instance.material_override = material
	_set_arms_green()  # Reset arms to green when dead

func _create_arm_materials():
	# Create green material
	green_material = StandardMaterial3D.new()
	green_material.albedo_color = Color(0, 1, 0, 1)
	green_material.roughness = 0.8
	
	# Create red material
	red_material = StandardMaterial3D.new()
	red_material.albedo_color = Color(1, 0, 0, 1)
	red_material.roughness = 0.8

func _set_arms_green():
	if left_arm and green_material:
		left_arm.material_override = green_material
	if right_arm and green_material:
		right_arm.material_override = green_material

func _set_arms_red():
	if left_arm and red_material:
		left_arm.material_override = red_material
	if right_arm and red_material:
		right_arm.material_override = red_material

func _on_state_changed():
	match current_state:
		ZombieState.WANDERING:
			_set_arms_green()
			animation_player.play("idle")
			is_attacking_animation = false
		ZombieState.CHASING:
			_set_arms_red()
			animation_player.play("idle")
			is_attacking_animation = false
		ZombieState.ATTACKING:
			_set_arms_red()
			# Don't immediately play attack animation here - let the attack handler do it
			if not is_attacking_animation:
				animation_player.play("idle")
		ZombieState.DEAD:
			_set_arms_green()
			animation_player.play("idle")
			is_attacking_animation = false
