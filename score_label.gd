extends Label

# Path ไปยัง Node Player ใน Scene (ถ้า Player อยู่ใต้ root ของ Scene)
@export var player_scene: PackedScene
var player: Node = null

func _ready():
	if player_scene != null:
		player = player_scene.instantiate()
		add_child(player)  # หรือใส่ลง Scene tree ตามต้องการ
		
		text = "Sanity: %s" % player.current_health
		player.hit.connect(_on_player_hit)
		player.die.connect(_on_player_die)
	else:
		print("Error: Player scene not assigned!")

func _on_player_hit(damage: int):
	if player != null:
		text = "Sanity: %s" % player.current_health

func _on_player_die():
	text = "Sanity: 0"

func _on_mob_squashed():
	text = "Sanity: %s" % player.current_health
	
