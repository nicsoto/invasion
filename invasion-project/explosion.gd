extends CPUParticles3D


func _ready() -> void:
	# La conexión se libera también si se reinicia el nivel antes del final.
	finished.connect(queue_free)
	emitting = true
