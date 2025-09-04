extends CharacterBody3D

# Movement constants (CS:GO inspired values)
const WALK_SPEED = 5.0
const RUN_SPEED = 7.0
const CROUCH_SPEED = 2.5
const JUMP_VELOCITY = 8.5
const AIR_ACCELERATION = 2.0
const GROUND_ACCELERATION = 10.0
const GROUND_FRICTION = 6.0
const AIR_FRICTION = 0.2
const MAX_SPEED = 10.0

# Mouse sensitivity
const MOUSE_SENSITIVITY = 0.002

# Movement variables
var speed = WALK_SPEED
var is_crouching = false
var wish_dir = Vector3.ZERO

# Camera nodes
@onready var camera_pivot = $CameraPivot
@onready var camera = $CameraPivot/Camera3D

# Get the gravity from the project settings to be synced with RigidBody nodes
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	# Capture mouse cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	# Handle mouse look
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# Rotate the camera pivot (up/down)
		camera_pivot.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, -PI/2, PI/2)
		
		# Rotate the player body (left/right)
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
	
	# Handle escape to free mouse
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	handle_movement(delta)
	
	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	move_and_slide()

func handle_movement(delta):
	# Handle jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# Handle crouching
	is_crouching = Input.is_action_pressed("crouch")
	
	# Get input direction
	var input_dir = Vector2.ZERO
	if Input.is_action_pressed("move_forward"):
		input_dir.y -= 1
	if Input.is_action_pressed("move_backward"):
		input_dir.y += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1
	
	# Normalize input to prevent faster diagonal movement
	input_dir = input_dir.normalized()
	
	# Convert input to world space direction
	wish_dir = Vector3(input_dir.x, 0, input_dir.y)
	wish_dir = wish_dir.rotated(Vector3.UP, rotation.y)
	
	# Determine current speed based on state
	if is_crouching:
		speed = CROUCH_SPEED
	elif Input.is_action_pressed("run"):
		speed = RUN_SPEED
	else:
		speed = WALK_SPEED
	
	# Apply movement based on whether player is on ground or in air
	if is_on_floor():
		ground_movement(delta)
	else:
		air_movement(delta)

func ground_movement(delta):
	if wish_dir.length() > 0:
		# Accelerate towards desired direction
		var current_speed = velocity.dot(wish_dir)
		var add_speed = speed - current_speed
		
		if add_speed > 0:
			var acceleration_speed = GROUND_ACCELERATION * delta * speed
			if acceleration_speed > add_speed:
				acceleration_speed = add_speed
			
			velocity += wish_dir * acceleration_speed
	else:
		# Apply friction when no input
		var friction_speed = GROUND_FRICTION * delta
		if velocity.length() > friction_speed:
			velocity = velocity.normalized() * (velocity.length() - friction_speed)
		else:
			velocity.x = 0
			velocity.z = 0

func air_movement(delta):
	if wish_dir.length() > 0:
		# Air strafing - limited acceleration in air
		var current_speed = velocity.dot(wish_dir)
		var add_speed = speed - current_speed
		
		if add_speed > 0:
			var acceleration_speed = AIR_ACCELERATION * delta * speed
			if acceleration_speed > add_speed:
				acceleration_speed = add_speed
			
			velocity += wish_dir * acceleration_speed
	
	# Apply air friction
	var horizontal_velocity = Vector3(velocity.x, 0, velocity.z)
	if horizontal_velocity.length() > 0:
		var friction_speed = AIR_FRICTION * delta
		if horizontal_velocity.length() > friction_speed:
			horizontal_velocity = horizontal_velocity.normalized() * (horizontal_velocity.length() - friction_speed)
			velocity.x = horizontal_velocity.x
			velocity.z = horizontal_velocity.z
	
	# Cap maximum speed
	var horizontal_speed = Vector3(velocity.x, 0, velocity.z).length()
	if horizontal_speed > MAX_SPEED:
		var ratio = MAX_SPEED / horizontal_speed
		velocity.x *= ratio
		velocity.z *= ratio
