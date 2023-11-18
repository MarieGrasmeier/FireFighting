extends RigidBody3D

var initial_direction: Vector3
var initial_speed: float

func _ready():
	pass

func _on_WaterParticle_body_entered(body):
	# print("hit something")
	
	if body.has_method("hit_by_water"):
		body.hit_by_water()
		
	queue_free()  # Remove the particle after hitting something

