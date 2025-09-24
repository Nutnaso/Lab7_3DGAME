extends CharacterBody3D

signal hit(damage: int)  # ส่งเมื่อโดนโจมตี
signal die                # ส่งเมื่อ Player ตาย

# -------------------------------
# Stats
# -------------------------------
@export var speed: float = 14
@export var fall_acceleration: float = 75
@export var jump_impulse: float = 20
@export var bounce_impulse: float = 16

@export var dash_impulse: float = 25
@export var dash_duration: float = 0.2
@export var dash_iframe_duration: float = 0.5
@export var jump_iframe_duration: float = 1.0
@export var blink_threshold: float = 0.2
@export var blink_speed: float = 0.1

@export var max_health: int = 10
var current_health: int

# -------------------------------
# Variables
# -------------------------------
var target_velocity: Vector3 = Vector3.ZERO
var dash_velocity: Vector3 = Vector3.ZERO
var dash_timer: float = 0.0

var is_iframe: bool = false
var iframe_timer: float = 0.0
var blink_timer: float = 0.0

@onready var barrier = $"Pivot/swat/Barrier"

# -------------------------------
func _ready() -> void:
	current_health = max_health
	barrier.visible = false

# -------------------------------
func _physics_process(delta: float) -> void:
	var direction = Vector3.ZERO

	# Movement Input
	if Input.is_action_pressed("move_right"):
		direction.x += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_back"):
		direction.z += 1
	if Input.is_action_pressed("move_forward"):
		direction.z -= 1

	if direction != Vector3.ZERO:
		direction = direction.normalized()
		$Pivot.basis = Basis.looking_at(direction)

	# Ground velocity
	target_velocity.x = direction.x * speed
	target_velocity.z = direction.z * speed

	# Gravity
	if not is_on_floor():
		target_velocity.y -= fall_acceleration * delta

	# Jump
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		target_velocity.y = jump_impulse
		_start_iframe(jump_iframe_duration)

	# Dash
	if Input.is_action_just_pressed("dash") and direction != Vector3.ZERO:
		dash_velocity = direction * dash_impulse
		dash_timer = dash_duration
		_start_iframe(dash_iframe_duration)

	# Update dash
	if dash_timer > 0.0:
		dash_timer -= delta
	else:
		dash_velocity = Vector3.ZERO

	# Combine
	velocity = target_velocity + dash_velocity
	move_and_slide()

	# 🎬 Animation: Run / Idle
	if direction != Vector3.ZERO:
		$Pivot/swat/AnimationPlayer.play("CharacterArmature|Run")
	else:
		$Pivot/swat/AnimationPlayer.play("CharacterArmature|Idle")

	# **จำกัดตำแหน่ง Player ให้อยู่ในขอบเขต 1280x720**
	var half_width = 1.777777 * 28
	var half_height = 1 * 5
	position.x = clamp(position.x, -half_width, half_width)
	position.z = clamp(position.z, -half_height, half_height)

	# I-frame
	_update_iframe(delta)

	# Collision check
	_check_collisions()



# -------------------------------
func _update_iframe(delta: float) -> void:
	if is_iframe:
		iframe_timer -= delta
		if iframe_timer <= blink_threshold:
			blink_timer -= delta
			if blink_timer <= 0.0:
				barrier.visible = not barrier.visible
				blink_timer = blink_speed
		if iframe_timer <= 0.0:
			is_iframe = false
			barrier.visible = false

func _start_iframe(duration: float) -> void:
	is_iframe = true
	iframe_timer = duration
	blink_timer = blink_speed
	barrier.visible = true

	# Material
	if barrier.get_active_material(0) == null:
		var new_mat = StandardMaterial3D.new()
		barrier.set_surface_override_material(0, new_mat)

	var mat: StandardMaterial3D = barrier.get_active_material(0)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1.0, 0.84, 0.0, 0.1)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.84, 0.0, 0.1)

# -------------------------------
# Health
# -------------------------------
func take_damage(amount: int) -> void:
	if is_iframe:
		return
	current_health -= amount
	hit.emit(amount)
	if current_health <= 0:
		_die()
	else:
		_start_iframe(0.5)

func heal(amount: int) -> void:
	current_health = min(current_health + amount, max_health)

func _die() -> void:
	die.emit()
	get_tree().change_scene_to_file("res://end_screen.tscn")

	queue_free()

# -------------------------------
# Mob collision
# -------------------------------
func _on_mob_detector_body_entered(body: Node) -> void:
	if body.is_in_group("Mobs"):
		if is_iframe:
			if body.has_method("squash"):
				body.squash()
				current_health += 1
		else:
			# ให้ Mob ส่ง damage
			var dmg: int = 1
			# เช็คว่ามี property 'damage' หรือไม่
			if "damage" in body:  # <-- ใช้ใน Godot 4
				dmg = body.damage
			take_damage(dmg)

func _check_collisions() -> void:
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		if collision.get_collider() and collision.get_collider().is_in_group("mob"):
			var mob = collision.get_collider()
			if Vector3.UP.dot(collision.get_normal()) > 0.1:
				if mob.has_method("squash"):
					mob.squash()
				target_velocity.y = bounce_impulse
				break
