extends RigidBody3D


# Member variables
var ignition_temperature: float = 200.0 # The temperature at which the voxel ignites
@export var current_temperature: float = 200.0 #The current temperature of the voxel
@export var is_on_fire: bool = true # Whether the voxel is currently on fire
@export var max_combustion_temperature: float = 500.0 # After reaching this value, the current temperature will not rise any further
var heat_release: float = 5.0 # The amount of heat released when the voxel is on fire
var heat_loss: float = 2.0 # The amount of heat lost when the voxel is not on fire
var cooling_effect: float # The amount of cooling when hit by water
var spray_angle
@onready var player = $"../Player"


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_on_fire and current_temperature < max_combustion_temperature:
		# Increase temperature because the voxel is on fire
		
		current_temperature = min(current_temperature + heat_release * delta, max_combustion_temperature)
		# Check if the voxel should stop burning
		if current_temperature >= ignition_temperature:
			is_on_fire = true
	else:
		# Decrease temperature because the voxel is not on fire
		current_temperature -= heat_loss * delta
		# Ensure temperature does not go below ambient/room temperature
		current_temperature = max(current_temperature, 0.0)

	# Check for neighboring voxels that are on fire
	check_neighbors()

	# Update the voxel's visual representation based on whether it's on fire
	update_visuals()
	
	check_for_ignition()
	
	check_if_extinguished()
	
	# print(current_temperature)

func check_neighbors():
	# Assuming each voxel has a collider that is a child node named "Collider"
	var collider = $Area3D
	for body in collider.get_overlapping_bodies():
		if body.is_in_group("fuel") and body.is_on_fire:
			# Increase temperature based on the neighbor's temperature
			var neighbor_temp = body.current_temperature
			if neighbor_temp > current_temperature and current_temperature < max_combustion_temperature:
				current_temperature = min(current_temperature + heat_release * get_process_delta_time(), max_combustion_temperature)

func check_for_ignition():
	if current_temperature > ignition_temperature and not is_on_fire:
		is_on_fire = true
		# print("Igniting!")
		# Optionally, perform additional actions upon ignition, like visual effects
func check_if_extinguished():
	if current_temperature < ignition_temperature:
		is_on_fire = false

func hit_by_water():
	spray_angle = player.spray_angle
	cooling_effect = 4.0+(spray_angle/2.0)
	# Call this method when the voxel is hit by a water object
	current_temperature -= cooling_effect
	# Ensure temperature does not go below ambient/room temperature
	current_temperature = max(current_temperature, 0.0)
	# print("hit by water")
	print("Spray Angle", spray_angle)
	print("Cooling Effect", cooling_effect)

func update_visuals():
	# Assuming the voxel has a MeshInstance3D as a child node named "Mesh"
	var mesh_instance = $MeshInstance3D
	var flame_particles = $Flame
	if is_on_fire:
		# Change the color to red
		mesh_instance.material_override = create_color_material(Color.RED)
		if !flame_particles.emitting:
			flame_particles.emitting = true
		
	else:
		# Revert to the original appearance
		mesh_instance.material_override = null
		flame_particles.emitting = false

func create_color_material(color: Color) -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	return material
