extends StaticBody3D

#VARIABLES
#HP
var hp: int = 100
#CHARACTER
var player: CharacterBody3D
#ATTACK
var can_attack = true
var is_stunned = false
@export var attack_range: float = 2.5
@export var attack_damage: int = 20
@export var attack_interval: float = 2.0

#COLOR
@export var mesh: MeshInstance3D
var original_color: Color


#FUNTIONS

func _ready():
	player = get_tree().get_first_node_in_group("player")
	original_color = mesh.material_override.albedo_color

func _process(_delta):
	if player == null:
		return
	if is_stunned:
			return

	var distance = global_position.distance_to(player.global_position)

	if distance <= attack_range and can_attack:
		attack_player()

func attack_player():
	can_attack = false
	print("Enemy attacks!")

	player.take_damage(attack_damage)

	await get_tree().create_timer(attack_interval).timeout
	can_attack = true

func take_damage(amount: int):
	flash_red()
	hp -= amount
	print("Enemy HP: ", hp)

	if hp <= 0:
		print("Enemy defeated!")
		queue_free()

func stun():
	is_stunned = true
	print("Enemy stunned!")

	await get_tree().create_timer(1.5).timeout

	is_stunned = false
	print("Enemy recovered!")

func flash_red():
	mesh.material_override.albedo_color = Color.RED

	await get_tree().create_timer(0.1).timeout

	mesh.material_override.albedo_color = original_color
