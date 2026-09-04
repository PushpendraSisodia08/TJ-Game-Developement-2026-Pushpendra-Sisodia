extends Node2D
@export var pipe_scene : PackedScene
const BASE_SCROLL_SPEED : int = 3
const MAX_SCROLL_SPEED : int = 10
const SPEED_UP_INTERVAL : int = 3     # increase speed/tighten pipes every N points
const SPEED_UP_AMOUNT : int = 1       # how much faster each time
const BASE_PIPE_GAP : float = 4.0   # horizontal pixel gap between pipes at start
const MIN_PIPE_GAP : float = 4.0    # gap never shrinks below this
const GAP_DECREASE_AMOUNT : float = 25.0  # how much tighter each time
var scroll_speed : int = BASE_SCROLL_SPEED
var pipe_gap : float = BASE_PIPE_GAP
const PIPE_DELAY : int = 100
const PIPE_RANGE : int = 200
var screen_size : Vector2i
var ground_height : int
@onready var die: AudioStreamPlayer2D = $die
@onready var jump: AudioStreamPlayer2D = $jump
@onready var point: AudioStreamPlayer2D = $point
@onready var hit: AudioStreamPlayer2D = $hit
@onready var start: AudioStreamPlayer2D = $start
var game_running : bool = false
var game_over : bool = false
var score : int = 0
var highest_score : int = 0
var scroll : int = 0
var pipes : Array
var pipe_timer : int = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	screen_size = get_window().size
	ground_height = $Ground.get_node("Sprite2D").texture.get_height()
	load_high_score()
	new_game()
func new_game():
	#reset variables
	game_running = false
	game_over = false
	score = 0
	scroll = 0
	scroll_speed = BASE_SCROLL_SPEED
	pipe_gap = BASE_PIPE_GAP
	$PipeTimer.wait_time = pipe_gap / scroll_speed
	$UI/ScoreLabel.text = "SCORE: " + str(score)
	$UI/GameOver.hide()
	$GameLogo.show()
	#clear any pipes left over from a previous run BEFORE generating new ones
	get_tree().call_group("pipes", "queue_free")
	pipes.clear()
	#generate starting pipes
	generate_pipes()
	$Bird.reset()
	$UI/ScoreLabel.text = str(score)
	start.play()
func _input(event):
	if game_over == false:
		var pressed_flap : bool = false
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				pressed_flap = true
		elif event is InputEventKey:
			if event.keycode == KEY_SPACE and event.pressed and not event.echo:
				pressed_flap = true

		if pressed_flap:
			if game_running == false:
				start_game()
				jump.play()
			else:
				if $Bird.flying:
					$Bird.flap()
					check_top()
					jump.play()
func start_game():
	game_running = true
	$Bird.flying = true
	$Bird.flap()
	$GameLogo.hide()
	#start pipe timer
	$PipeTimer.start()
func _process(delta):
	if game_running:
		scroll += scroll_speed
		#reset scroll
		if scroll >= screen_size.x:
			scroll = 0
		#move ground node
		$Ground.position.x = -scroll
		#move pipes
		for pipe in pipes:
			pipe.position.x -= scroll_speed
func _on_pipe_timer_timeout():
	generate_pipes()
func generate_pipes():
	var pipe = pipe_scene.instantiate()
	pipe.position.x = screen_size.x + PIPE_DELAY
	pipe.position.y = (screen_size.y - ground_height) / 2 + randi_range(-PIPE_RANGE, PIPE_RANGE)
	pipe.add_to_group("pipes")
	pipe.hit.connect(bird_hit)
	pipe.scored.connect(scored)
	add_child(pipe)
	pipes.append(pipe)
	
func scored():
	score += 1
	$UI/ScoreLabel.text = "SCORE: " + str(score)
	point.play()
	if score % SPEED_UP_INTERVAL == 0:
		if scroll_speed < MAX_SCROLL_SPEED:
			scroll_speed += SPEED_UP_AMOUNT
		if pipe_gap > MIN_PIPE_GAP:
			pipe_gap -= GAP_DECREASE_AMOUNT
		$PipeTimer.start(pipe_gap / scroll_speed)
	if score > highest_score:
		highest_score = score
		$UI/HighestScoreLabel.text = "BEST: " + str(highest_score)
		save_high_score()
	
func load_high_score():
	if FileAccess.file_exists("user://highscore.save"):
		var save_file = FileAccess.open("user://highscore.save", FileAccess.READ)
		highest_score = save_file.get_32()
		save_file.close()
	$UI/HighestScoreLabel.text = "BEST: " + str(highest_score)
func save_high_score():
	var save_file = FileAccess.open("user://highscore.save", FileAccess.WRITE)
	save_file.store_32(highest_score)
	save_file.close()
	
func check_top():
	if $Bird.position.y < 1:
		$Bird.falling = true
		stop_game()
		
func stop_game():
	$PipeTimer.stop()
	$UI/GameOver.show()
	$Bird.flying = false
	game_running = false
	game_over = true
func bird_hit():
	game_running = false
	game_over = true
	$PipeTimer.stop()
	$Bird.falling = true
	hit.play()
	die.play()
	stop_game()
func _on_ground_hit():
	$Bird.falling = false
	stop_game()
	hit.play()
func _on_game_over_restart():
	new_game()
