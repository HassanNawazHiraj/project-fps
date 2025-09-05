extends Area3D

# Pickup properties
const GUN_TYPE = "M1"
const AMMO_AMOUNT = 30
const PICKUP_MESSAGE = "Press F to pick up M1 Rifle"

# State
var player_in_range = false
var has_been_picked_up = false

# Node references
@onready var pickup_model = $PickupModel
@onready var rotation_timer = $RotationTimer

# Signals
signal gun_picked_up(gun_type: String, ammo_amount: int)

func _ready():
	# Add to group for player to find
	add_to_group("gun_pickups")
	
	# Connect signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	rotation_timer.timeout.connect(_on_rotation_timer_timeout)
	
	# Start floating animation
	_start_floating_animation()

func _start_floating_animation():
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(self, "position:y", position.y + 0.2, 2.0)
	tween.tween_property(self, "position:y", position.y - 0.2, 2.0)

func _on_rotation_timer_timeout():
	# Rotate the pickup slowly
	pickup_model.rotation_degrees.y += 2

func _input(event):
	if player_in_range and event.is_action_pressed("interact"):
		_pickup_gun()

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = true
		# Show pickup prompt (we'll implement UI later)
		print(PICKUP_MESSAGE)

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		print("") # Clear message

func _pickup_gun():
	if not player_in_range:
		return
	
	# Emit signal to player
	emit_signal("gun_picked_up", GUN_TYPE, AMMO_AMOUNT)
	
	if not has_been_picked_up:
		# First pickup - give gun + ammo
		print("Picked up M1 Rifle with ", AMMO_AMOUNT, " rounds!")
		has_been_picked_up = true
		# Hide the pickup (don't queue_free so player can get more ammo later)
		visible = false
		set_collision_layer_value(1, false)
		set_collision_mask_value(1, false)
		
		# Respawn after 10 seconds for more ammo
		await get_tree().create_timer(10.0).timeout
		visible = true
		set_collision_layer_value(1, true)
		set_collision_mask_value(1, true)
	else:
		# Subsequent pickups - just give ammo
		print("Picked up ", AMMO_AMOUNT, " additional rounds!")
		
		# Hide temporarily
		visible = false
		set_collision_layer_value(1, false)
		set_collision_mask_value(1, false)
		
		# Respawn after 5 seconds
		await get_tree().create_timer(5.0).timeout
		visible = true
		set_collision_layer_value(1, true)
		set_collision_mask_value(1, true)
