extends Node3D
class_name Gun

# Gun properties
const GUN_NAME = "M1 Rifle"
const DAMAGE = 17  # 3 hits to kill zombie (50 health / 3 = ~17 damage per shot)
const MAGAZINE_SIZE = 10
const RELOAD_TIME = 3.0
const FIRE_RATE = 0.2  # Time between shots

# Gun state
var current_ammo_in_magazine = 0
var total_ammo = 0
var is_reloading = false
var can_fire = true
var fire_timer = 0.0

# Signals
signal ammo_changed(current_ammo, total_ammo)
signal reload_started()
signal reload_finished()
signal fired()

# Node references
@onready var muzzle_point = $GunModel/MuzzlePoint

func _ready():
	# Initialize with empty gun
	current_ammo_in_magazine = 0
	total_ammo = 0

func _process(delta):
	# Handle fire rate timer
	if fire_timer > 0:
		fire_timer -= delta
		if fire_timer <= 0:
			can_fire = true

func pickup_gun(initial_ammo: int = 30):
	"""Called when player picks up this gun or ammo"""
	total_ammo += initial_ammo
	if current_ammo_in_magazine == 0 and total_ammo > 0:
		# Auto-reload if magazine is empty and we have ammo
		reload()
	emit_signal("ammo_changed", current_ammo_in_magazine, total_ammo)
	print("Picked up ", GUN_NAME, "! Ammo: ", current_ammo_in_magazine, "/", total_ammo)

func can_shoot() -> bool:
	return current_ammo_in_magazine > 0 and not is_reloading and can_fire

func shoot() -> bool:
	if not can_shoot():
		return false
	
	current_ammo_in_magazine -= 1
	can_fire = false
	fire_timer = FIRE_RATE
	
	emit_signal("fired")
	emit_signal("ammo_changed", current_ammo_in_magazine, total_ammo)
	
	print("Shot fired! Ammo: ", current_ammo_in_magazine, "/", total_ammo)
	return true

func reload():
	if is_reloading or current_ammo_in_magazine >= MAGAZINE_SIZE or total_ammo <= 0:
		return
	
	is_reloading = true
	emit_signal("reload_started")
	print("Reloading...")
	
	# Start reload timer
	await get_tree().create_timer(RELOAD_TIME).timeout
	
	# Calculate how much ammo to put in magazine
	var ammo_needed = MAGAZINE_SIZE - current_ammo_in_magazine
	var ammo_to_add = min(ammo_needed, total_ammo)
	
	current_ammo_in_magazine += ammo_to_add
	total_ammo -= ammo_to_add
	
	is_reloading = false
	emit_signal("reload_finished")
	emit_signal("ammo_changed", current_ammo_in_magazine, total_ammo)
	
	print("Reload complete! Ammo: ", current_ammo_in_magazine, "/", total_ammo)

func get_muzzle_position() -> Vector3:
	return muzzle_point.global_position

func get_ammo_info() -> Dictionary:
	return {
		"current": current_ammo_in_magazine,
		"total": total_ammo,
		"magazine_size": MAGAZINE_SIZE,
		"is_reloading": is_reloading
	}
