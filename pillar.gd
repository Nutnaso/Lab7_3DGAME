extends CharacterBody3D 

signal squashed

@export var min_speed = 30
@export var max_speed = 50
@export var damage = 1  
@onready var despawn_timer = $DespawnTimer

var target_position: Vector3 = Vector3.ZERO
var wait_time: float = 0.0
var is_waiting: bool = true

func initialize(start_position: Vector3, player_position: Vector3, bar_duration: float):
	# วาง pillar
	position = start_position
	target_position = player_position
	
	# ✅ ตั้งเวลาให้รอ 1 bar ก่อนพุ่ง
	wait_time = bar_duration
	is_waiting = true
	velocity = Vector3.ZERO

	# ✅ คำนวณ direction (เฉพาะแกน XZ)
	var direction = (target_position - position)
	direction.y = 0
	direction = direction.normalized()

	# ✅ หมุนเสาให้หันไปทาง player
	rotation.y = atan2(-direction.x, -direction.z)

	# ✅ เพิ่มเอียงฐานเล็กน้อย (เช่นเอียงไปข้างหน้า 15 องศา)
	rotation.x = deg_to_rad(80)  

func squash():
	squashed.emit()
	queue_free()

func _physics_process(delta):
	if is_waiting:
		wait_time -= delta
		if wait_time <= 0.0:
			# ✅ เริ่มพุ่งหา player หลังจากรอครบ 1 bar
			is_waiting = false
			var direction = (target_position - position)
			direction.y = 0
			direction = direction.normalized()
			var random_speed = randi_range(min_speed, max_speed)
			velocity = direction * random_speed
	else:
		move_and_slide()

func _on_visible_on_screen_notifier_3d_screen_exited():
	queue_free()

func _on_despawn_timer_timeout() -> void:
	queue_free()
