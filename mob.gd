extends CharacterBody3D 

signal squashed

@export var min_speed = 6
@export var max_speed = 12
@export var damage = 1  # เพิ่ม damage ของ Mob
@onready var despawn_timer = $DespawnTimer

var target_position: Vector3 = Vector3.ZERO

func initialize(start_position: Vector3, player_position: Vector3):
	# วาง mob
	position = start_position
	target_position = player_position
	
	# คำนวณ direction เฉพาะแกน XZ
	var direction = (target_position - position)
	direction.y = 0  # ตัดความสูงออก
	direction = direction.normalized()
	
	# หมุน Y ให้หันไปหา player
	rotation.y = atan2(-direction.x, -direction.z)  # หรือปรับเครื่องหมายตามโมเดล

	# เพิ่มการสุ่มหมุนเล็กน้อย (-45 ถึง +45 องศา)
	rotate_y(randf_range(-PI / 4, PI / 4))
	
	# ความเร็วสุ่ม
	var random_speed = randi_range(min_speed, max_speed)
	velocity = direction * random_speed

func squash():
	squashed.emit()
	queue_free()

func _physics_process(_delta):
	$"Pivot/Root Scene/AnimationPlayer".play("CharacterArmature|Fast_Flying")
	move_and_slide()  # ✅ ไม่ต้องใส่อะไร

func _on_visible_on_screen_notifier_3d_screen_exited():
	queue_free()

func _on_despawn_timer_timeout() -> void:
	queue_free()
