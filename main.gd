extends Node3D

# -------------------------------
# Export Variables
@export var BPM: float = 225
@export var beats_per_bar: int = 4
@export var mob_scene: PackedScene
@export var pillar_scene: PackedScene

@onready var player = $Player
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var sun = $DirectionalLight3D
@onready var camera = $Marker3D/Camera3D
@onready var player_camera = $Player/Marker3D/Camera3D
@onready var dialog = $UserInterface/Dialog/Dialog_label

@onready var boss = $Boss

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
	sun.rotate_x(180)
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
		

	if current_bar >= 87 and current_bar < 101 :
		sun.rotate_x(deg_to_rad(5))
		

	if current_bar >= 101 and current_bar < 103 :
		sun.rotate_x(deg_to_rad(45/2))
		
	if current_bar >= 184:
		$UserInterface/Tutorial.visible = false
	

	# อัปเดตกล้องสั่น
	_update_camera_shake(delta)
	_update_camera_pan(delta)
	_update_boss_movement(delta)  # ✅ อัปเดตการลอยของ Boss
	_update_dialog(delta)


# Class variable
var buildup_shake: float = 0.05

func _check_bar_events():
	# -------------------------------
	# Cutscene ก่อน boss
	if current_bar == 1:
		$UserInterface/Tutorial.visible = true
		switch_to_cutscene_camera()
		camera_pan_to($MainFloor/Statue1.global_transform.origin + Vector3(0, 5, 10), bar_duration*4)
		
	if current_bar == 5:
		camera_pan_to($MainFloor/Statue2.global_transform.origin + Vector3(0, 5, 10), bar_duration*4)

	if current_bar == 9:
		camera_pan_to($"MainFloor/Gravestone Cross3".global_transform.origin + Vector3(0, 5, 10), bar_duration*4)
		
	if current_bar == 13:
		camera_pan_to($"Player".global_transform.origin + Vector3(0, 5, 10), bar_duration*4)
	
	if current_bar == 17:
		$UserInterface/Tutorial.visible = false
		boss.visible = true
		switch_to_player_camera()
		camera_shake(0.5, 1)
		show_dialog("ยินดีต้อนรับ.....ยินดีต้อนรับ...", bar_duration*5)
		
		
	if current_bar == 21:
		show_dialog("ขอต้อนรับสู่ดินแดนแห่งนี้...", bar_duration*4)
		
		
	if current_bar == 25:
		show_dialog("....และเตรียมชมการแสดงของข้า.....", bar_duration*5)
		
		
	if current_bar == 30:
		show_dialog("....ข้านะ..ยินดีอย่างมาก.....", bar_duration*7)
		
	if current_bar == 37:
		show_dialog("....เพราะอะไรนะหรอ?.....", bar_duration*5)
		
	if current_bar == 42:
		show_dialog("....เพราะว่า.....", bar_duration*4)
		
	if current_bar == 46:
		show_dialog("....เพราะว่า..เพราะว่า...", bar_duration*5)
		
	if current_bar == 51:
		show_dialog("....เพราะนี้จะเป็นการบรรเลงครั้งสุดท้ายของข้านะสิ :) ...", bar_duration*7)
		
	# -------------------------------
	# Bar 21 - 37 : กระสุนน้อย 1 per bar
	if current_bar >= 21 and current_bar < 37:
		spawn_mobs_player_track_for_beat([1,0,0,0])  # 1 per bar

	# Bar 31 - 51 (bar % 2 == 1) : กระสุนน้อย 3 per bar
	if current_bar >= 37 and current_bar < 51 and current_bar % 2 == 1:
		spawn_mobs_player_track_for_beat([1,1,1,0])

	# -------------------------------
	# Bar 53 - 69 : ฟ้ามืด + กระสุนใหญ่ 2 per bar
	if current_bar >= 51 and current_bar < 53:
		sun.rotate_x(180)
	
	if current_bar >= 53 and current_bar < 69:
		camera_shake(0.07, bar_duration)
		spawn_pillar_for_beat([1,0,1,0])

	# Bar 69 - 77 : กระสุนใหญ่
	if current_bar >= 69 and current_bar < 77:
		camera_shake(0.07, bar_duration)
		if current_bar % 2 == 1:
			spawn_pillar_for_beat([1,0,1,0])
		else:
			spawn_pillar_for_beat([1,0,0,0])

	# Bar 77 - 81 (bar % 2 == 1) : กระสุนใหญ่ 3 per bar
	if current_bar >= 77 and current_bar < 81 and current_bar % 2 == 1:
		camera_shake(0.07, bar_duration)
		spawn_pillar_for_beat([1,1,1,0])

	# Bar 81 - 85 : กระสุนใหญ่ 4 per bar
	if current_bar >= 81 and current_bar < 83:
		camera_shake(0.1, bar_duration)
		spawn_pillar_for_beat([1,1,1,1])

	# Bar 87 - 103 : ฟ้าหมุน + กล้องสั่น
	
	
	if current_bar == 87:
		show_dialog("....ผู้ประสานเสียงจงขับร้อง...", bar_duration*7)
	
	if current_bar == 94:
		show_dialog("....ท่วงทำนองแห่งการทำลายล้าง...", bar_duration*8)
		
	if current_bar >= 87 and current_bar < 102:
		$MainFloor/Statue1.visible = true
		$MainFloor/Statue2.visible = true
		camera_shake(buildup_shake, bar_duration)
		buildup_shake += 0.01

	# Bar 103 - 119
	if current_bar >= 103 and current_bar < 119:
		camera_shake(0.05, bar_duration)
		if current_bar % 2 == 1:
			spawn_pillar_for_beat([2,0,0,0])  # กระสุนใหญ่
		spawn_mobs_player_track_for_beat([1,1,1,1])  # กระสุนน้อย

	# Bar 119 - 135
	if current_bar >= 119 and current_bar < 135:
		camera_shake(0.05, bar_duration)
		if current_bar % 2 == 1:
			spawn_pillar_for_beat([4,0,0,0])
		camera_shake(0.2, bar_duration)
		spawn_mobs_player_track_for_beat([1,1,1,1])  # กระสุนน้อย

	# Bar 135 - 141 (bar % 2 == 1) : กล้องสั่นมาก + กระสุนใหญ่ 8 per bar
	if current_bar >= 135 and current_bar < 141 and current_bar % 2 == 1:
		camera_shake(1.0, 0.3)
		spawn_pillar_for_beat([8,0,0,0])

	# Bar 141 - 143 (bar % 2 == 1) : กล้องสั่นมาก + กระสุนใหญ่ 16 per bar
	if current_bar >= 141 and current_bar < 143 and current_bar % 2 == 1:
		camera_shake(2.0, bar_duration)
		spawn_pillar_for_beat([16,0,0,0])

	# Bar 143 - 149 : กระสุนน้อย 8 per bar
	if current_bar >= 143 and current_bar < 149:
		camera_shake(0.2, bar_duration)
		spawn_pillar_for_beat([1,1,1,1])

	# Bar 151 - 167 : บทสนทนา
	if current_bar >= 151 and current_bar < 167:
		pass
	if current_bar == 151:
		show_dialog("....ไพเราะใช่ไหมละ...", bar_duration*5)
	
	if current_bar == 156:
		show_dialog("....ท่วงทำนองเหล่านี้..ล้วนบรรเลงอย่างดี...", bar_duration*5)
		
	if current_bar == 161:
		show_dialog("....แต่น่าเศร้า เพราะมีเพียงข้าเท่านั้นที่ชอบมัน...", bar_duration*5)
		
		
	if current_bar == 166:
		show_dialog("....ช่าง...น่าเสียดายเหลือเกิน...", bar_duration*5)
		
	# Bar 167 : กระสุนน้อย 8 per bar
	if current_bar >= 167 and current_bar < 180 :
		spawn_pillar_for_beat([2,0,2,0])
		spawn_mobs_player_track_for_beat([1,0,1,0])


	if current_bar >= 167 and current_bar < 180 and current_bar % 2 == 1:
		sun.rotate_x(deg_to_rad(45))


	if current_bar == 180:
		show_dialog("....เอาเถอะ ลาก่อนผู้ชมที่มีเกียรติทั้งหลาย :) ...", bar_duration*5)
		
	# Bar 188 : จบเกม
	if current_bar == 184:
		
		switch_to_cutscene_camera()
		camera_pan_to($Boss.global_transform.origin + Vector3(0, 5, 10), bar_duration*4)
		$UserInterface/Win.visible = true
		switch_to_player_camera()

	

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
# Spawn pillar
# -------------------------------
# Spawn pillar แบบตาม pattern
func spawn_pillar_for_beat(pattern: Array):
	var amount = pattern[current_beat - 1]
	if amount > 0:
		var target_position = player.position
		for i in range(amount):
			# ✅ สุ่มตำแหน่งเกิด
			var spawn_x = randf_range(-58.0, 63.0)
			var spawn_y = 0
			var spawn_z = -73.7
			var spawn_position = Vector3(spawn_x, spawn_y, spawn_z)

			# ✅ สร้างเสา
			var pillar = pillar_scene.instantiate()
			add_child(pillar)
			pillar.initialize(spawn_position, target_position, bar_duration)


# -------------------------------
# Camera Functions
func camera_shake(strength: float, duration: float) -> void:
	shake_strength = strength
	shake_duration = duration
	shake_timer = duration

func _update_camera_shake(delta: float) -> void:
	if shake_timer > 0.0:
		shake_timer -= delta
		player_camera.transform.origin = original_camera_transform.origin + Vector3(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)
	else:
		player_camera.transform = original_camera_transform

# -------------------------------
# Camera Pan Variables
var is_panning: bool = false
var pan_timer: float = 0.0
var pan_duration: float = 1.0
var pan_start_transform: Transform3D
var pan_target_transform: Transform3D

func camera_pan_to(target_position: Vector3, duration: float = 1.0):
	is_panning = true
	pan_timer = 0.0
	pan_duration = duration
	pan_start_transform = camera.transform
	
	# ✅ หมายเหตุ: เราจะให้กล้องเลื่อนไปที่ target โดยยังคงมอง player
	var look_at_target = player.global_transform.origin
	var target_transform = camera.transform.looking_at(look_at_target, Vector3.UP)
	target_transform.origin = target_position
	pan_target_transform = target_transform
func _update_camera_pan(delta: float) -> void:
	if is_panning:
		pan_timer += delta
		var t = clamp(pan_timer / pan_duration, 0.0, 1.0)
		
		# ✅ Lerp กล้อง
		var new_origin = pan_start_transform.origin.lerp(pan_target_transform.origin, t)
		var new_basis = pan_start_transform.basis.slerp(pan_target_transform.basis, t)
		
		camera.transform = Transform3D(new_basis, new_origin)
		
		# ✅ ถ้า pan ครบแล้ว
		if t >= 1.0:
			is_panning = false
			
func switch_to_cutscene_camera():
	player_camera.current = false
	camera.current = true

func switch_to_player_camera():
	camera.current = false
	player_camera.current = true


# -------------------------------
# Boss Movement Variables
var boss_float_speed: float = 2.0      # ความเร็วการลอยขึ้นลง
var boss_float_amplitude: float = 0.9  # ระยะการลอยขึ้นลง (7.5 - 5.7 = 1.8, ครึ่งหนึ่งคือ 0.9)
var boss_follow_speed: float = 3.0     # ความเร็วการหน่วงตาม player (แกน X)

func _update_boss_movement(delta: float) -> void:
	if boss.visible:
		# ---------------------------
		# Target ตำแหน่ง Boss
		var target_x = clamp(player.global_transform.origin.x, -58.0, 63.0)
		var base_y = 6.6
		var float_y = base_y + sin(Time.get_ticks_msec() / 1000.0 * boss_float_speed) * boss_float_amplitude
		var fixed_z = -90
		var target_pos = Vector3(target_x, float_y, fixed_z)
		
		# ---------------------------
		# Smooth follow โดยใช้ lerp
		var current_pos = boss.global_transform.origin
		var new_pos = current_pos.lerp(target_pos, boss_follow_speed * delta)
		
		boss.global_transform.origin = new_pos
		
		# ---------------------------
		# Boss หันมามอง Player
		boss.look_at(player.global_transform.origin, Vector3.UP)
		
		
# -------------------------------
# Dialog / Subtitle Functions
var dialog_timer: float = 0.0

func show_dialog(text: String, duration: float = 2.0) -> void:
	dialog.text = text
	dialog.visible = true
	dialog_timer = duration

func _update_dialog(delta: float) -> void:
	if dialog.visible:
		dialog_timer -= delta
		if dialog_timer <= 0.0:
			dialog.visible = false
