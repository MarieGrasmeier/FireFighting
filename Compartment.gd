#@tool
extends Node3D

# Preload the Voxel scene
var voxel_scene = preload("res://CompartmentVoxel.tscn")

func _ready():
	#if Engine.is_editor_hint():
		generate_grid()  # Generate grid in the editor

func generate_grid():
	print("Generating Grid")
	for x in range(20):
		for y in range(5):
			for z in range(10):
				var voxel_instance = voxel_scene.instantiate()
				voxel_instance.global_transform.origin = Vector3(x * 0.5, y * 0.5, z * 0.5)
				add_child(voxel_instance)
				# Set some voxels as smoke sources for demonstration
				if x == 10 and y == 5 and z == 2:
					voxel_instance.is_smoke_source = true
