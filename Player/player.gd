extends CharacterBody2D

@export_category("Upgrades")
@export var dash: bool = true
@export var dash_upgrade: bool = true
@export var gun: bool = true
@export var sword: bool = true

@export_category("Input")
@export var input_dir: Vector2 = Vector2.ZERO

@export_category("Movement")
@export var facing_dir: float = 1
@export var move_speed: float = 150.0
@export var friction: float = 250.0
@export var jump_force: float = 400.0

@export_category("Dashing")
@export var dashes: int = 1
var available_dashes: int = dashes
@export var dash_dist: float = 100.0
var can_redash: bool = false
@export var redash_window_length: float = 0.5
var redash_timer: float = 1.0
var dash_on_cooldown: bool = false
@export var dash_cooldown: float = 1.0
var dash_cooldown_timer: float = 1.0

@export_category("Aiming")
var locked: bool = false
var prev_aim_dir: Vector2 = Vector2.ZERO
var aim_dir: Vector2 = Vector2.RIGHT
@export var gun_rot_speed: float = 10.0
@export var gun_hold_dist: Vector2 = Vector2(20, 30)
@onready var gun_sprite: MeshInstance2D = $Gun
var gun_offset: Vector2 = Vector2.ZERO

# camera
@onready var camera: Camera2D = get_parent().get_node("Camera")
var cam_offset: Vector2 = Vector2.ZERO
var cam_offset_multiplier: Vector2 = Vector2(0.3, 0.3)
var cam_follow_speed: float = 6.0

func _physics_process(delta: float):
	if !is_on_floor():
		velocity += get_gravity() * delta
	
	upgrades()
	gather_inputs()
	move_cam(delta)
	
	if can_redash:
		redash_window(delta)
	elif locked:
		free_aim()
	else:
		normal_movement(delta)
		
	move_gun(delta)
	move_and_slide()

func upgrades():
	if dash_upgrade:
		dashes = 3
	else:
		dashes = 1

func gather_inputs():
	# basic movement
	input_dir =  Vector2(Input.get_axis("Move Left", "Move Right"), 0)
	# jump
	if Input.is_action_just_pressed("Jump") && is_on_floor():
		jump()
	# cut jump short if key released early
	if velocity.y < 0 && !is_on_floor() && Input.is_action_just_released("Jump"):
		velocity.y /= 2
	# aiming
	aim_dir = Vector2(
		Input.get_axis("Move Left", "Move Right"),
		Input.get_axis("Look Up", "Look Down")
	).normalized()
	# free aim
	if gun:
		if Input.is_action_just_pressed("Aim"):
			locked = true
		if Input.is_action_just_released("Aim"):
			locked = false
			gun_offset = Vector2.ZERO
	# dashing
	if Input.is_action_just_pressed("Dash") && !dash_on_cooldown && dash:
		start_dash()
	# sword
	if Input.is_action_just_pressed("Attack"):
		if sword && !locked:
			pass
		if gun && locked:
			shoot()

func redash_window(delta):
	redash_timer -= delta
	if redash_timer <= 0:
		end_dash()
	velocity = Vector2.ZERO

func normal_movement(delta):
	if dash_on_cooldown:
		dash_cooldown_timer -= delta
		if dash_cooldown_timer <= 0:
			dash_on_cooldown = false
	movement(delta)

func free_aim():
	if is_on_floor():
		velocity.x = 0
	if aim_dir != Vector2.ZERO:
		gun_offset = aim_dir.normalized()
	else:
		gun_offset = Vector2(facing_dir, 0)
	
	if aim_dir.x < 0:
		facing_dir = -1
	elif aim_dir.x > 0:
		facing_dir = 1

func move_gun(delta):
	gun_sprite.position = gun_sprite.position.lerp(gun_offset * gun_hold_dist, gun_rot_speed * delta)
	gun_sprite.look_at(position)

func jump():
	velocity.y = -jump_force

func movement(delta):
	# basic movement
	if input_dir.x != 0:
		velocity.x = input_dir.x * move_speed
		if input_dir.x > 0:
			facing_dir = 1
		else:
			facing_dir = -1
	else:
		# friction
		if is_on_floor():
			velocity.x = 0
		else:
			velocity.x = move_toward(velocity.x, 0, friction * delta)

func start_dash():
	locked = false
	available_dashes -= 1
	if aim_dir != Vector2.ZERO:
		position += aim_dir * dash_dist
	else:
		position += Vector2(facing_dir, 0) * dash_dist
	start_dash_cooldown()

func start_dash_cooldown():
	# redash logic
	if available_dashes > 0:
		can_redash = true
		redash_timer = redash_window_length
	else:
		end_dash()

func end_dash():
	available_dashes = dashes
	can_redash = false
	dash_on_cooldown = true
	dash_cooldown_timer = dash_cooldown

func shoot():
	pass

func move_cam(delta):
	# move ahead according to player velocity
	cam_offset = velocity * cam_offset_multiplier
	# aiming
	if locked:
		cam_offset = gun_offset * gun_hold_dist * 2
	# move camera
	camera.global_position = camera.global_position.lerp(global_position + cam_offset, cam_follow_speed * delta)
