extends CharacterBody2D

@export_category("Input")
@export var input_dir: Vector2 = Vector2.ZERO

@export_category("Movement")
@export var facing_dir: float = 1
@export var move_speed: float = 150.0
@export var friction: float = 250.0
@export var jump_force: float = 400.0

@export_category("Dashing")
var available_dashes: int = 3
@export var dash_speed: float = 250.0
@export var dash_dist: float = 100.0
var can_redash: bool = false
@export var redash_window_length: float = 0.25
var redash_timer: float = 1.0
var dash_on_cooldown: bool = false
@export var dash_cooldown: float = 1.0
var dash_cooldown_timer: float = 1.0

@export_category("Aiming")
var prev_aim_dir: Vector2 = Vector2.ZERO
var aim_dir: Vector2 = Vector2.RIGHT

func _physics_process(delta: float):
	if !is_on_floor():
		velocity += get_gravity() * delta
	
	gather_inputs()
	
	if can_redash:
		redash_timer -= delta
		if redash_timer <= 0:
			end_dash()
		velocity = Vector2.ZERO
	else:
		if dash_on_cooldown:
			dash_cooldown_timer -= delta
			if dash_cooldown_timer <= 0:
				dash_on_cooldown = false
				available_dashes = 3
		movement(delta)
		
	move_and_slide()

func gather_inputs():
	# basic movement
	input_dir =  Vector2(Input.get_axis("Move Left", "Move Right"), 0)
	# jump
	if Input.is_action_just_pressed("Jump") && is_on_floor():
		jump()
	# cut jump short if key released early
	if velocity.y < 0 && !is_on_floor() && Input.is_action_just_released("Jump"):
		velocity.y = 0
	# aiming
	aim_dir = Vector2(
		Input.get_axis("Move Left", "Move Right"),
		Input.get_axis("Look Up", "Look Down")
	).normalized()
	
	aim()

func aim():
	var new_aim_dir = Vector2(
		Input.get_axis("Move Left", "Move Right"),
		Input.get_axis("Look Up", "Look Down")
	).normalized()
	
	if Input.is_action_just_pressed("Dash"):
		if !dash_on_cooldown && available_dashes > 0:
				aim_dir = new_aim_dir if new_aim_dir != Vector2.ZERO else aim_dir
				start_dash()
	elif can_redash && available_dashes > 0:
		# Flick redash: stick moved from neutral while dash is held
		if Input.is_action_pressed("Dash") && prev_aim_dir == Vector2.ZERO && new_aim_dir != Vector2.ZERO:
			aim_dir = new_aim_dir
			start_dash()

	prev_aim_dir = new_aim_dir
	aim_dir = new_aim_dir if new_aim_dir != Vector2.ZERO else aim_dir

func jump():
	velocity.y = -jump_force

func movement(delta):
	if input_dir.x != 0:
		velocity.x = input_dir.x * move_speed
		if input_dir.x > 0:
			facing_dir = 1
		else:
			facing_dir = -1
	else:
		if is_on_floor():
			velocity.x = 0
		else:
			velocity.x = move_toward(velocity.x, 0, friction * delta)
			
func start_dash():
	available_dashes -= 1
	if aim_dir != Vector2.ZERO:
		#velocity = aim_dir * dash_speed
		position += aim_dir * dash_dist
	else:
		#velocity = Vector2(facing_dir * dash_speed, 0)
		position += Vector2(facing_dir, 0) * dash_dist
	start_dash_cooldown()
	
func start_dash_cooldown():
	can_redash = true
	redash_timer = redash_window_length

func end_dash():
	can_redash = false
	dash_on_cooldown = true
	dash_cooldown_timer = dash_cooldown
