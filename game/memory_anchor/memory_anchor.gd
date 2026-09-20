extends Checkpoint
## Ancla de Memoria: además de descansar (Z, lo hace Checkpoint), permite
## gastar Ecos en mejorar el Filo (C).


func _physics_process(delta: float) -> void:
	super(delta)
	if targets_in_range.is_empty():
		return

	var player := targets_in_range[0]
	if Input.is_action_just_pressed("upgrade"):
		player.try_upgrade_weapon()

	var label := prompt as Label
	if label:
		label.text = "Z: Recordar\nC: %s" % player.upgrade_prompt()
