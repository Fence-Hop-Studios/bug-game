extends Spatial

const GRAVITY = -15

var explosionDelay:float



func _ready():
	pass
	


func _process(delta):
	explosionDelay += delta
	if explosionDelay >= 5:
		$Particles.emitting = true
