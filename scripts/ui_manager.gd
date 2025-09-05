extends Control

@onready var health_text = $HealthText
@onready var ammo_text = $AmmoText
@onready var reload_text = $ReloadText
@onready var interact_text = $InteractText

func _ready():
	# Add UI to group
	add_to_group("ui")
	
	# Connect to player signals
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.health_changed.connect(_on_health_changed)
		player.gun_equipped.connect(_on_gun_equipped)
		player.ammo_updated.connect(_on_ammo_updated)
	
	# Connect to gun pickup areas for interaction prompts
	await get_tree().process_frame
	var gun_pickups = get_tree().get_nodes_in_group("gun_pickups")
	for pickup in gun_pickups:
		pickup.body_entered.connect(_on_pickup_area_entered)
		pickup.body_exited.connect(_on_pickup_area_exited)

func _on_health_changed(current_health: float, max_health: float):
	# Update text to show "Health: X"
	health_text.text = "Health: %d" % int(current_health)
	
	# Change color based on health percentage (optional)
	var health_percentage = current_health / max_health
	if health_percentage > 0.6:
		health_text.modulate = Color.WHITE
	elif health_percentage > 0.3:
		health_text.modulate = Color.YELLOW
	else:
		health_text.modulate = Color.RED

func _on_gun_equipped(gun_name: String):
	print("Gun equipped: ", gun_name)

func _on_ammo_updated(current_ammo: int, total_ammo: int):
	ammo_text.text = "%d / %d" % [current_ammo, total_ammo]

func _on_pickup_area_entered(body):
	if body.is_in_group("player"):
		interact_text.text = "Press F to pick up M1 Rifle"

func _on_pickup_area_exited(body):
	if body.is_in_group("player"):
		interact_text.text = ""

func show_reload_message():
	reload_text.text = "RELOADING..."

func hide_reload_message():
	reload_text.text = ""
