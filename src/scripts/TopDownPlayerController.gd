# This is a top down player controller

#     -- Quirks and Considerations --
#
# If you don't provide an input direction then the speed could be higher than the expected max
# what this means is basically if you dash, you can go a greater distance if you let go of the direction
# I think it is kind of cool because it makes it a little bit more skill based
# you can for example:
# 	w + dash
# 	release w
# 	wait until you reach sprint speed
# 	hold sprint + w
#
# 	depending on the friction and dash timer duration, this could make you travel a greater distance than if you would just hold w + sprint + dash
#
# I think this could possibly be a lot cleaner if this used signals and leveraged animation controllers more, but that might make it less flexible.


extends CharacterBody2D
class_name TopDownPlayerController

# The path to the character's Sprite node, defaults to 'get_node("Sprite")'
@export_node_path("Sprite2D") var PLAYER_SPRITE
@onready var _sprite : Sprite2D = get_node(PLAYER_SPRITE) if PLAYER_SPRITE else $Sprite2D

# The path to the character's AnimationPlayer node, defaults to 'get_node("AnimationPlayer")'
@export_node_path("AnimationPlayer") var ANIMATION_PLAYER
@onready var _animation_player : AnimationPlayer = get_node(ANIMATION_PLAYER) if ANIMATION_PLAYER else $AnimationPlayer

@export var dash_timer: Timer
@export var dash_cooldown_timer : Timer

# Input Map actions related to each movement direction, and sprinting.  Set each to their related
# action's name in your Input Mapping or create actions with the default names.
@export var ACTION_UP : String = "up"
@export var ACTION_DOWN : String = "down"
@export var ACTION_LEFT : String = "left"
@export var ACTION_RIGHT : String = "right"
@export var ACTION_SPRINT : String = "sprint"
@export var ACTION_DASH : String = "dash"

# Enables/Disables hard movement when using a joystick.  When enabled, slightly moving the joystick
# will only move the character at a percentage of the maximum acceleration and speed instead of the maximum.
@export var JOYSTICK_MOVEMENT : bool = false

# The following float values are in px/sec when used in movement calculations with 'delta'
# How fast the character gets to the MAX_SPEED value
@export_range(0, 1000, 0.1) var ACCELERATION : float = 300
# The overall cap on the character's speed
@export_range(0, 1000, 0.1) var MAX_SPEED : float = 1000
@export_range(0, 1000, 0.1) var MAX_WALK_SPEED : float = 100
@export_range(0, 1000, 0.1) var MAX_SPRINT_SPEED : float = 200
# How fast the character's speed goes back to zero when not moving
@export_range(0, 1000, 0.1) var FRICTION : float = 100
# The speed of gravity applied to the character
@export_range(0, 1000, 0.1) var GRAVITY : float = 0

# The possible character STATES and the character's current state
enum STATES {IDLE, WALK, SPRINT, DASH}
var state : int = STATES.IDLE

# ------------------ Sprinting ---------------------------------
# Enable/Disable sprinting
@export var ENABLE_SPRINT : bool = false
# Sprint multiplier, multiplies the MAX_SPEED by this value when sprinting
@export_range(0, 10, 0.1) var SPRINT_MULTIPLIER : float = 1.5
# The player can sprint when can_sprint is true
@onready var can_sprint : bool = ENABLE_SPRINT
# The player is sprinting when sprinting is true
var sprinting : bool = false

# ------------------ Dashing ---------------------------------
# Enable/Disable dashing
@export var ENABLE_DASH : bool = false
# Dash multiplier, multiplies the MAX_SPEED by this value when dashing
@export_range(0, 1000, 0.1) var DASH_SPEED : float = 500
# The player can dash when can_dash is true
@onready var can_dash : bool = ENABLE_DASH
# The player is dashing when dashing is true
var dashing : bool = false
var dash_on_cooldown : bool = false

func _physics_process(delta : float) -> void:
	physics_tick(delta)

# Overrideable physics process used by the controller that calls whatever functions should be called
# and any logic that needs to be done on the _physics_process tick
func physics_tick(delta : float) -> void:
	var inputs : Dictionary = handle_inputs()
	handle_sprint(inputs.sprint_strength)
	handle_dash(inputs.dash_speed)
	handle_velocity(delta, inputs.input_direction)
	manage_animations()
	manage_state()

	velocity.y += GRAVITY * delta
	move_and_slide()

# Manages the character's current state based on the current velocity vector
func manage_state() -> void:
	if velocity.y == 0 and velocity.x == 0:
		state = STATES.IDLE
	else:
		state = STATES.WALK

# Manages the character's animations based on the current state and sprite direction based on
# the current horizontal velocity
func manage_animations() -> void:
	if velocity.x > 0:
		_sprite.flip_h = false
	elif velocity.x < 0:
		_sprite.flip_h = true
	match state:
		STATES.IDLE:
			_animation_player.play("Idle")
		STATES.WALK:
			_animation_player.play("Walk")
		STATES.SPRINT:
			_animation_player.play("Walk") # todo: add sprint animation
		STATES.DASH:
			_animation_player.play("Walk") # todo: add dash animation

# Gets the strength and status of the mapped actions
func handle_inputs() -> Dictionary:
	return {
		input_direction = get_input_direction(),
		sprint_strength = Input.get_action_strength(ACTION_SPRINT) if ENABLE_SPRINT else 0.0,
		dash_speed = 1.0 if ENABLE_DASH and Input.get_action_strength(ACTION_DASH) > 0 else 0.0
	}

# Gets the X/Y axis movement direction using the input mappings assigned to the ACTION UP/DOWN/LEFT/RIGHT variables
func get_input_direction() -> Vector2:
	var x_dir = Input.get_action_strength(ACTION_RIGHT) - Input.get_action_strength(ACTION_LEFT)
	var y_dir = Input.get_action_strength(ACTION_DOWN) - Input.get_action_strength(ACTION_UP)

	return Vector2(x_dir if JOYSTICK_MOVEMENT else sign(x_dir), y_dir if JOYSTICK_MOVEMENT else sign(y_dir))

# ------------------ Movement Logic ---------------------------------
# Takes delta and the current input direction and either applies the movement or applies friction
func handle_velocity(delta : float, input_direction : Vector2) -> void:
	if input_direction.x != 0 or input_direction.y != 0:
		apply_velocity(delta, input_direction)

	apply_friction(delta)

# Applies velocity in the current input direction using the ACCELERATION, MAX_SPEED, and SPRINT_MULTIPLIER
func apply_velocity(delta : float, move_direction : Vector2) -> void:
	var sprint_strength = SPRINT_MULTIPLIER if sprinting else 1.0
	var max_speeds : Array[float] = [MAX_WALK_SPEED]
	if sprinting:
		max_speeds.append(MAX_SPRINT_SPEED)
	if dashing:
		max_speeds.append(DASH_SPEED)
	var max_speed = max_speeds.max()

	# only increase speed if direction changed or speed is less than expected max
	if !dashing \
		or ((dashing and sprinting) and ((abs(move_direction.x) > 0 and abs(velocity.x) < MAX_SPRINT_SPEED) or (abs(move_direction.y) > 0 and abs(velocity.y) < MAX_SPRINT_SPEED))) \
		or ((dashing and !sprinting) and ((abs(move_direction.x) > 0 and abs(velocity.x) < MAX_WALK_SPEED) or (abs(move_direction.y) > 0 and abs(velocity.y) < MAX_WALK_SPEED))):
		velocity.x += move_direction.x * ACCELERATION * delta * sprint_strength
		velocity.y += move_direction.y * ACCELERATION * delta * sprint_strength
		velocity.x = clamp(velocity.x, -max_speed * abs(move_direction.x), max_speed * abs(move_direction.x))
		velocity.y = clamp(velocity.y, -max_speed * abs(move_direction.y), max_speed * abs(move_direction.y))

	if dashing and !dash_on_cooldown:
		dash_timer.start()
		dash_cooldown_timer.start()
		dash_on_cooldown = true
		velocity.x = move_direction.x * DASH_SPEED
		velocity.y = move_direction.y * DASH_SPEED

	velocity.x = clamp(velocity.x, -MAX_SPEED * abs(move_direction.x), MAX_SPEED * abs(move_direction.x))
	velocity.y = clamp(velocity.y, -MAX_SPEED * abs(move_direction.y), MAX_SPEED * abs(move_direction.y))


# Applies friction to the horizontal axis when not moving using the FRICTION value
func apply_friction(delta : float) -> void:
	var fric_x = FRICTION * delta * sign(velocity.x) * -1
	var fric_y = FRICTION * delta * sign(velocity.y) * -1

	if abs(velocity.x) <= abs(fric_x):
		velocity.x = 0
	else:
		velocity.x += fric_x

	if abs(velocity.y) <= abs(fric_y):
		velocity.y = 0
	else:
		velocity.y += fric_y


# Sets the sprinting variable according to the strength of the sprint input action
func handle_sprint(sprint_strength : float) -> void:
	if sprint_strength != 0 and can_sprint:
		sprinting = true
		state = STATES.SPRINT
	else:
		sprinting = false

# Sets the dashing variable according to the strength of the dash input action
func handle_dash(dash_speed : float) -> void:
	if dash_speed > 0 and can_dash and !dash_on_cooldown:
		dashing = true
		state = STATES.DASH
	elif !can_dash:
		dashing = false

# after the duration of the timer, set dashing to false so the max speed decreases
func _on_dash_timer_timeout() -> void:
	dashing = false
	dash_timer.stop()

func _on_dash_cooldown_timer_timeout() -> void:
	dash_on_cooldown = false
	dash_cooldown_timer.stop()
