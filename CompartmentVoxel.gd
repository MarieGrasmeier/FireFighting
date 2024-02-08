extends Area3D

# Voxel properties
@export var smoke_density: float = 0.0
var temperature: float = 0.0
@export var is_smoke_source: bool = false

# Visual representation
@onready var mesh_instance_3d = $CollisionShape3D/MeshInstance3D


func _ready():
	update_visuals()
	# Check for overlapping fuel voxels periodically
	set_process(true)

func _process(delta):
	check_for_fire_sources()
	if is_smoke_source:
		increase_smoke()
	update_visuals()
	#print("smoke:", is_smoke_source)

func check_for_fire_sources():
	for body in get_overlapping_bodies():
		#print("Detected body: ", body.name, " at position: ", body.global_transform.origin)
		if body.is_in_group("fuel") and body.is_on_fire:
			#print("Fire detected in: ", body.name)
			is_smoke_source = true
			#print(is_smoke_source)
			return  # Found a burning fuel voxel, no need to check furtherdess
		else:
			if body.is_in_group("smokeVoxel"):
				is_smoke_source = true
				return
			else:
				is_smoke_source = false  # No burning fuel voxels found

func increase_smoke():
	smoke_density = min(smoke_density + 0.001, 1)  # Increase smoke, max density is 1.0
	temperature = min(temperature + 5.0, 100.0)  # Increase temperature, max is 100
	print("smoke density:", smoke_density)


func update_visuals():
	#print(smoke_density)
	var color = Color(1.0, 1.0, 1.0, smoke_density)  # Adjust color for smoke
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.flags_transparent = true  # Enable transparency
	material.params_blend_mode = StandardMaterial3D.BLEND_MODE_MIX
	material.params_use_alpha_scissor = true
	
	material.params_cull_mode = StandardMaterial3D.CULL_DISABLED
	material.params_depth_draw_mode = StandardMaterial3D.DEPTH_DRAW_ALWAYS  # Ensure depth draw
	material.params_use_alpha_scissor = true  # Use alpha scissor for better performance
	material.params_alpha_scissor_threshold = 0.5  # Adjust this value as needed
	mesh_instance_3d.material_override = material


