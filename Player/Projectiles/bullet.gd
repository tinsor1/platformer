extends Area2D

var velocity: Vector2 = Vector2.ZERO

func _ready():
	body_entered.connect(on_body_entered)

func on_body_entered(_body: Node):
	queue_free()

func _process(delta):
	position += velocity * delta
