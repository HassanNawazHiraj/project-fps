extends Control

@onready var health_text = $HealthText

func _ready():
	# Connect to player health signal
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.health_changed.connect(_on_health_changed)

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
