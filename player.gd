extends CharacterBody3D

##VARIABLES##

#MOVEMENT
@export var speed: float = 5.0
@export var sprint_speed: float = 20.0
#CAMERA
@export var camera: Camera3D
#SPRITES
@export var front_sprite: Sprite3D
@export var back_sprite: Sprite3D
#HP
var hp: int = 100
@export var max_hp: int = 100
#ATTACK
var can_attack = true
var already_hit: Array = []
@export var attack_cooldown: float = 0.5
@export var attack_damage: int = 25
@export var attack_range: float = 2.5
@export var attack_sprite: AnimatedSprite3D
@export var attack_hitbox: Area3D
#PARRY
var is_parrying = false
var can_parry = true
@export var parry_duration: float = 0.4
@export var parry_cooldown: float = 0.8

#FUNCTIONS

func _physics_process(delta):
	if is_on_floor():
		velocity.y = 0
	else:
		velocity.y -= 9.8 * delta

	var current_speed = sprint_speed if Input.is_key_pressed(KEY_SHIFT) else speed
	var direction = Vector3.ZERO

	if Input.is_action_pressed("move_forward"):
		direction.z -= 1
	if Input.is_action_pressed("move_backward"):
		direction.z += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_right"):
		direction.x += 1

	direction = direction.normalized()

	velocity.x = direction.x * current_speed
	velocity.z = direction.z * current_speed

	move_and_slide()

func _process(_delta):
	if camera == null:
		return

	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_direction = camera.project_ray_normal(mouse_pos)

	var ground_plane = Plane(Vector3.UP, global_position.y)
	var target = ground_plane.intersects_ray(ray_origin, ray_direction)

	if target != null:
		look_at(
			Vector3(target.x, global_position.y, target.z),
			Vector3.UP
		)

	var to_camera = camera.global_position - global_position
	var facing_camera = global_basis.z.dot(to_camera) < 0

	front_sprite.visible = facing_camera
	back_sprite.visible = not facing_camera
	
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and can_attack:
			attack()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			parry()

func attack():
	if not can_attack:
		return

	can_attack = false
	already_hit.clear()
	attack_hitbox.monitoring = false
	attack_sprite.visible = true
	attack_sprite.play("Slash")

	while attack_sprite.is_playing():
		await get_tree().physics_frame

		if attack_hitbox.monitoring:
			for enemy in get_tree().get_nodes_in_group("enemies"):
				if attack_hitbox.overlaps_body(enemy) and not already_hit.has(enemy):
					already_hit.append(enemy)
					enemy.take_damage(attack_damage)
					print("Hit!")

	attack_sprite.visible = false
	attack_hitbox.monitoring = false

	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func parry():
	if not can_parry:
		return

	can_parry = false
	is_parrying = true
	print("PARRY!")

	await get_tree().create_timer(parry_duration).timeout
	is_parrying = false
	print("Parry ended!")

	await get_tree().create_timer(parry_cooldown).timeout
	can_parry = true

func take_damage(amount: int):	
	if is_parrying:
		print("Attack parried!")
		var enemies = get_tree().get_nodes_in_group("enemies")
		for enemy in enemies:
			if global_position.distance_to(enemy.global_position) <= 3.0:
				enemy.stun()
		return

	hp -= amount
	print("Player HP: ", hp)

	if hp <= 0:
		print("You died!")

func _on_attack_frame_changed() -> void:
	if attack_sprite.animation != "Slash":
		return

	if attack_sprite.frame >= 1 and attack_sprite.frame <= 3:
		attack_hitbox.monitoring = true
	else:
		attack_hitbox.monitoring = false
