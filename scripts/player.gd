extends CharacterBody3D

@export var JUMP_VELOCITY = 4.5
@export var WALKING_SPEED = 5.0
@export var SPRINTING_SPEED = 8.0
@export var CROUCHING_SPEED = 3.0
@export var CROUCHING_DEPTH = -0.9
@export var MOUSE_SENS = 0.25
@export var LERP_SPEED = 10.0
@export var AIR_LERP_SPEED = 6.0
@export var FREE_LOOK_TILT_AMOUNT = 5.0
@export var SLIDING_SPEED = 5.0
@export var WIGGLE_ON_WALKING_SPEED = 14.0
@export var WIGGLE_ON_SPRINTING_SPEED = 22.0
@export var WIGGLE_ON_CROUCHING_SPEED = 10.0
@export var WIGGLE_ON_WALKING_INTENSITY = 0.1
@export var WIGGLE_ON_SPRINTING_INTENSITY = 0.2
@export var WIGGLE_ON_CROUCHING_INTENSITY = 0.05
@export var BUNNY_HOP_ACCELERATION = 0.1

var mouse_capture: bool = true
var nozzle_node
var water_particle_scene = preload("res://WaterParticle.tscn")
var shoot_force = 50.0
var is_shooting: bool
@export var initial_speed = 50.0  # Adjust as needed
var spray_angle = 0 # Starting angle, adjust as needed
var min_angle = 0 # Minimum angle
var max_angle = 40 # Maximum angle

var current_speed = 5.0
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var direction = Vector3.ZERO
var is_walking = false
var is_sprinting = false
var is_crouching = false
var is_free_looking = false
var slide_vector = Vector2.ZERO
var wiggle_vector = Vector2.ZERO
var wiggle_index = 0.0
var wiggle_current_intensity = 0.0
var bunny_hop_speed = SPRINTING_SPEED
var last_velocity = Vector3.ZERO
var stand_after_roll = false


func _ready():
	
	
	
	nozzle_node = $Neck/Head/Eyes/Camera/Nozzle


func _input(event):
	if event is InputEventMouseMotion:
		if is_free_looking:
			$Neck.rotate_y(deg_to_rad(-event.relative.x * MOUSE_SENS))
			$Neck.rotation.y = clamp($Neck.rotation.y, deg_to_rad(-120), deg_to_rad(120))
		else:
			rotate_y(deg_to_rad(-event.relative.x * MOUSE_SENS))
		$Neck/Head.rotate_x(deg_to_rad(-event.relative.y * MOUSE_SENS))
		$Neck/Head.rotation.x = clamp($Neck/Head.rotation.x, deg_to_rad(-90), deg_to_rad(90))
		
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_shooting = event.pressed
			
	if event is InputEventMouseButton:
		# Check for mouse wheel movement
		if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			# Adjust the Cone_Angle based on the wheel direction
			if event.button_index == MOUSE_BUTTON_WHEEL_UP and spray_angle < max_angle:
				spray_angle += 1
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and spray_angle > 0:
				spray_angle -= 1


func _process(delta):
	if is_shooting:
		for i in range(1):
			shoot_water_particle()
			
	if mouse_capture == true:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	

func _physics_process(delta):
	var input_dir = Input.get_vector("left", "right", "forward", "back")
	
	if Input.is_action_just_pressed("mouseCapture"):
		mouse_capture = !mouse_capture
	
	
	
	if stand_after_roll:
		$Neck/Head.position.y = lerp($Neck/Head.position.y, 0.0, delta * LERP_SPEED)
		$StandingCollisionShape.disabled = true
		$CrouchingCollisionShape.disabled = false
		stand_after_roll = false
	
	if Input.is_action_pressed("crouch") or $RayCast.is_colliding():
		if is_on_floor():
			current_speed = lerp(current_speed, CROUCHING_SPEED, delta * LERP_SPEED)
		$Neck/Head.position.y = lerp($Neck/Head.position.y, CROUCHING_DEPTH, delta * LERP_SPEED)
		$StandingCollisionShape.disabled = true
		$CrouchingCollisionShape.disabled = false
		wiggle_current_intensity = WIGGLE_ON_CROUCHING_INTENSITY
		wiggle_index += WIGGLE_ON_CROUCHING_SPEED * delta
		if is_sprinting and input_dir != Vector2.ZERO and is_on_floor():
			$SlidingTimer.start()
			slide_vector = input_dir
		elif !Input.is_action_pressed("sprint"):
			$SlidingTimer.stop()
		is_walking = false
		is_sprinting = false
		is_crouching = true
	else:
		$Neck/Head.position.y = lerp($Neck/Head.position.y, 0.0, delta * LERP_SPEED)
		$StandingCollisionShape.disabled = false
		$CrouchingCollisionShape.disabled = true
		$SlidingTimer.stop()
		if Input.is_action_pressed("sprint"):
			if !Input.is_action_pressed("jump"):
				bunny_hop_speed = SPRINTING_SPEED
			current_speed = lerp(current_speed, bunny_hop_speed, delta * LERP_SPEED)
			wiggle_current_intensity = WIGGLE_ON_SPRINTING_INTENSITY
			wiggle_index += WIGGLE_ON_SPRINTING_SPEED * delta
			is_walking = false
			is_sprinting = true
			is_crouching = false
		else:
			current_speed = lerp(current_speed, WALKING_SPEED, delta * LERP_SPEED)
			wiggle_current_intensity = WIGGLE_ON_WALKING_INTENSITY
			wiggle_index += WIGGLE_ON_WALKING_SPEED * delta
			is_walking = true
			is_sprinting = false
			is_crouching = false
	
	if Input.is_action_pressed("free_look") or !$SlidingTimer.is_stopped():
		is_free_looking = true
		if $SlidingTimer.is_stopped():
			$Neck/Head/Eyes.rotation.z = -deg_to_rad(
				$Neck.rotation.y * FREE_LOOK_TILT_AMOUNT
			)
		else:
			$Neck/Head/Eyes.rotation.z = lerp(
				$Neck/Head/Eyes.rotation.z,
				deg_to_rad(4.0), 
				delta * LERP_SPEED
			)
	else:
		is_free_looking = false
		rotation.y += $Neck.rotation.y
		$Neck.rotation.y = 0
		$Neck/Head/Eyes.rotation.z = lerp(
			$Neck/Head/Eyes.rotation.z,
			0.0,
			delta*LERP_SPEED
		)
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif $SlidingTimer.is_stopped() and input_dir != Vector2.ZERO:
		wiggle_vector.y = sin(wiggle_index)
		wiggle_vector.x = sin(wiggle_index / 2) + 0.5
		$Neck/Head/Eyes.position.y = lerp(
			$Neck/Head/Eyes.position.y,
			wiggle_vector.y * (wiggle_current_intensity / 2.0), 
			delta * LERP_SPEED
		)
		$Neck/Head/Eyes.position.x = lerp(
			$Neck/Head/Eyes.position.x,
			wiggle_vector.x * wiggle_current_intensity, 
			delta * LERP_SPEED
		)
	else:
		$Neck/Head/Eyes.position.y = lerp($Neck/Head/Eyes.position.y, 0.0, delta * LERP_SPEED)
		$Neck/Head/Eyes.position.x = lerp($Neck/Head/Eyes.position.x, 0.0, delta * LERP_SPEED)
		if last_velocity.y <= -7.5:
			$Neck/Head.position.y = lerp($Neck/Head.position.y, CROUCHING_DEPTH, delta * LERP_SPEED)
			$StandingCollisionShape.disabled = false
			$CrouchingCollisionShape.disabled = true
			$Neck/Head/Eyes/AnimationPlayer.play("roll")
		elif last_velocity.y <= -5.0:
			$Neck/Head/Eyes/AnimationPlayer.play("landing")
	
	if Input.is_action_pressed("jump") and is_on_floor():
		$Neck/Head/Eyes/AnimationPlayer.play("jump")
		if !$SlidingTimer.is_stopped():
			velocity.y = JUMP_VELOCITY * 1.5
			$SlidingTimer.stop()
		else:
			velocity.y = JUMP_VELOCITY
		if is_sprinting:
			bunny_hop_speed += BUNNY_HOP_ACCELERATION
		else:
			bunny_hop_speed = SPRINTING_SPEED
	
	if $SlidingTimer.is_stopped():
		if is_on_floor():
			direction = lerp(
				direction,
				(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(),
				delta * LERP_SPEED
			)
		elif input_dir != Vector2.ZERO:
			direction = lerp(
				direction,
				(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(),
				delta * AIR_LERP_SPEED
			)
	else:
		direction = (transform.basis * Vector3(slide_vector.x, 0.0, slide_vector.y)).normalized()
		current_speed = ($SlidingTimer.time_left / $SlidingTimer.wait_time + 0.5) * SLIDING_SPEED
	
	current_speed = clamp(current_speed, 3.0, 12.0)
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
	
	last_velocity = velocity
	
	move_and_slide()


func _on_sliding_timer_timeout():
	is_free_looking = false


func _on_animation_player_animation_finished(anim_name):
	stand_after_roll = anim_name == 'roll' and !is_crouching
	
func shoot_water_particle():
	const DEGREE_TO_RADIAN = PI / 180.0
	# const CONE_ANGLE = 10.0  # Cone angle in degrees

	var water_particle_instance = water_particle_scene.instantiate()
	water_particle_instance.global_transform = nozzle_node.global_transform

	# Get the forward direction of the nozzle/camera
	var forward_direction = nozzle_node.global_transform.basis.z.normalized() * -1

	# Randomize the direction within the cone angle
	var random_horizontal_angle = randf_range(-spray_angle / 2, spray_angle / 2) * DEGREE_TO_RADIAN
	var random_vertical_angle = randf_range(-spray_angle / 2, spray_angle / 2) * DEGREE_TO_RADIAN

	# Apply horizontal rotation
	var horizontal_rotated_direction = forward_direction.rotated(Vector3.UP, random_horizontal_angle)

	# Apply vertical rotation
	# We need to find a perpendicular vector to the forward direction for the vertical rotation axis
	var vertical_rotation_axis = horizontal_rotated_direction.cross(Vector3.UP).normalized()
	var random_direction = horizontal_rotated_direction.rotated(vertical_rotation_axis, random_vertical_angle)


	# Set the initial velocity in the randomized forward direction
	if water_particle_instance is RigidBody3D:
		water_particle_instance.linear_velocity = random_direction * initial_speed

	get_tree().root.add_child(water_particle_instance)



	
	
	
