extends Node3D

# -------------------------------
# Export Variables
@export var BPM: float = 188
@export var beats_per_bar: int = 4
@export var mob_scene: PackedScene
@onready var player = $Player
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var sun = $DirectionalLight3D
@onready var special_object = $MainFloor/Boss
@onready var camera = $Marker3D/Camera3D

# -------------------------------
# Internal Variables
var beat_duration: float
var bar_duration: float
var elapsed_time: float = 0.0
var current_bar: int = 0
var current_beat: int = 0
var last_beat: int = 0

# -------------------------------
# Camera Shake Variables
var shake_timer: float = 0.0
var shake_duration: float = 0.0
var shake_strength: float = 0.0
var original_camera_transform: Transform3D

# -------------------------------
func _ready():
	sun.rotate_x(0)
	beat_duration = 60.0 / BPM
	bar_duration = beat_duration * beats_per_bar
	audio_player.play()
	original_camera_transform = camera.transform

# -------------------------------
func _process(delta):
	elapsed_time = audio_player.get_playback_position()
	current_bar = int(elapsed_time / bar_duration) + 1
	current_beat = int(fposmod(elapsed_time, bar_duration) / beat_duration) + 1

	# ตรวจสอบ beat ใหม่
	if current_beat != last_beat:
		last_beat = current_beat
		print("DEBUG: Bar %d, Beat %d" % [current_bar, current_beat])
		_check_bar_events()
		
		
		
	if current_bar >= 89 and current_bar < 93 :
		sun.rotate_x(deg_to_rad(5))
		
		
		
	if current_bar >= 93 and current_bar < 101 :
		sun.rotate_x(deg_to_rad(45/2))
			

	# อัปเดตกล้องสั่น
	_update_camera_shake(delta)

# -------------------------------
func _check_bar_events():
	
	if current_bar >= 1 and current_bar < 21:
		$UserInterface/Tutorial.visible = true
		
	if current_bar >= 5 and current_bar < 21:
		sun.rotate_x(deg_to_rad(5))
		# เรียกสั่นกล้องทุก beat
		
	if current_bar >= 21 and current_bar < 37 and current_bar % 4 == 1 :
		$UserInterface/Tutorial.visible = false
		camera_shake(0.2, bar_duration/2)
		spawn_mobs_random_for_beat([1,0,0,0])
		
	if current_bar >= 37 and current_bar < 49:
		sun.rotate_x(deg_to_rad(5))
		spawn_mobs_random_for_beat([1,0,0,0])
		
		
	if current_bar >= 49 and current_bar < 51:
		sun.rotate_x(deg_to_rad(5))
		camera_shake(0.01, bar_duration)
		spawn_mobs_random_for_beat([1,0,1,0])
	
	if current_bar >= 51 and current_bar < 53:
		sun.rotate_x(deg_to_rad(5))
		camera_shake(0.07, bar_duration)
		spawn_mobs_random_for_beat([1,1,1,1])
		
		
		
	if current_bar >= 53 and current_bar < 85:
		camera_shake(0.1, bar_duration)
		special_object.visible = true
		$MainFloor/Boss/AnimationPlayer.play("CharacterArmature|Yes")
		spawn_mobs_random_for_beat([0,1,0,1])
		
		
	if current_bar == 85:
		special_object.visible = false
		$MainFloor.visible = false
		
		
	if current_bar == 88:
		sun.rotate_x(deg_to_rad(135))
		camera_shake(2, 0.1)
		special_object.visible = true
		$MainFloor.visible = true
		$MainFloor/Boss/AnimationPlayer.play("CharacterArmature|Headbutt")
	
	
	if current_bar >= 89 and current_bar < 93 :
		camera_shake(0.1, bar_duration)
		$MainFloor/Boss/AnimationPlayer.play("CharacterArmature|Fast_Flying")
		spawn_mobs_random_for_beat([1,1,1,1])
	
	
	if current_bar >= 93 and current_bar < 101 :
		camera_shake(0.5, bar_duration/4)
		$MainFloor/Boss/AnimationPlayer.play("CharacterArmature|Fast_Flying")
		spawn_mobs_random_for_beat([2,2,2,2])
		
	if current_bar == 103 :
		special_object.visible = false
		$UserInterface/Win.visible = true
# -------------------------------
# Spawn mobs แบบสุ่ม
func spawn_mobs_random_for_beat(pattern: Array):
	var amount = pattern[current_beat - 1]
	if amount > 0:
		var target_position = player.position
		for i in range(amount):
			var mob = mob_scene.instantiate()
			mob.squashed.connect($UserInterface/ScoreLabel._on_mob_squashed.bind())
			var mob_spawn_location = get_node("SpawnPath/SpawnLocation")
			mob_spawn_location.progress_ratio = randf()
			mob.initialize(mob_spawn_location.position, target_position)
			add_child(mob)

# -------------------------------
# Spawn mobs แบบติดตามผู้เล่น
func spawn_mobs_player_track_for_beat(pattern: Array):
	var amount = pattern[current_beat - 1]
	if amount > 0:
		var target_position = player.position
		for i in range(amount):
			var mob = mob_scene.instantiate()
			mob.squashed.connect($UserInterface/ScoreLabel._on_mob_squashed.bind())
			var mob_spawn_location = get_node("SpawnPath/SpawnLocation")
			mob_spawn_location.progress_ratio = randf()
			mob.initialize(mob_spawn_location.position, target_position)
			add_child(mob)

# -------------------------------
# Camera Shake Functions
func camera_shake(strength: float, duration: float) -> void:
	shake_strength = strength
	shake_duration = duration
	shake_timer = duration

func _update_camera_shake(delta: float) -> void:
	if shake_timer > 0.0:
		shake_timer -= delta
		camera.transform.origin = original_camera_transform.origin + Vector3(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)
	else:
		camera.transform = original_camera_transform
