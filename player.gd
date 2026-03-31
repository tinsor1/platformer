extends CharacterBody2D

@export_category("Input")
@export var input_dir: Vector2 = Vector2.ZERO

@export_category("Movement")
@export var move_speed: float = 150.0
@export var friction: float = 250.0
@export var jump_force: float = 400.0

func _physics_process(delta: float):
	if !is_on_floor():
		velocity += get_gravity() * delta
	
	gather_inputs()
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

func jump():
	velocity.y = -jump_force

func movement(delta):
	if input_dir != Vector2.ZERO:
		velocity.x = input_dir.x * move_speed
	else:
		if is_on_floor():
			velocity.x = 0
		else:
			velocity.x = move_toward(velocity.x, 0, friction * delta)
