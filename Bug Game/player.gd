extends KinematicBody

const GRAVITY = -15


var velocity = Vector3.ZERO
var baseMovementSpeed = 3
var movementSpeed
var acceleration:float = 6.0
var jumpHeight = 7

var baseStamina:float = 4
var stamina:float = baseStamina
var outOfStamina:bool
var wallRunDelay:float = 1.5
var readyToWallRun:bool

#bug jump
var bugJumping:bool
var chargeBugJump:float
var bugJumpChargeTimer:float

var isHoldingJump:bool
var isHoldingSprint:bool
var isOnGround:bool
var currentlyMoving:bool
var currentlyWallRunning:bool

var sensitivity:float = 0.06

onready var camera = $Camera


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED) 
	
	
func _process(delta):
	pass

func _physics_process(delta):
	var movementDirection = _getMovementDirection()
	
	#Checks if the player is currently on the ground
	if $floorCast.is_colliding() == true:
		isOnGround = true
	else:
		isOnGround = false
		
	print(currentlyWallRunning)
	#checks if the player is currently sprinting, sets FOV higher if true as well as movespeed
	if Input.is_action_pressed("sprint"):
		isHoldingSprint = true
		movementSpeed = baseMovementSpeed * 2 
		camera.fov = lerp(camera.fov, 105, 0.05)
	else:
		isHoldingSprint = false
		movementSpeed = baseMovementSpeed
		camera.fov = lerp(camera.fov, 90, 0.05)
		
		
	if Input.is_action_pressed("moveForwards"):
		currentlyMoving = true
	else:
		currentlyMoving = false
		
	#Jumping
	if Input.is_action_just_pressed("jump") && isOnGround:
		velocity.y = jumpHeight
	if Input.is_action_pressed("jump") && !isHoldingJump:
		isHoldingJump = true
	if Input.is_action_pressed("jump") && !currentlyMoving:
		bugJumpChargeTimer += delta
		if currentlyWallRunning && bugJumpChargeTimer >= 1.5 && !currentlyMoving:
			chargeBugJump = chargeBugJump + 0.5
			bugJumping = true
			if chargeBugJump >= 25: #sets max bug jump veloc
				chargeBugJump = 25
			print("bugged jump charging")
	elif Input.is_action_just_released("jump") && isHoldingJump:
		if currentlyWallRunning && bugJumping:
			velocity.y = velocity.y + chargeBugJump
			chargeBugJump = 0
			bugJumpChargeTimer = 0
		if currentlyWallRunning:
			velocity.y = velocity.y + 10
			chargeBugJump = 0
			bugJumpChargeTimer = 0
		isHoldingJump = false
			
		
	
	#If the player is holding sprint, jump, is not on the ground and close enough to a wall, wallrun.
	if isHoldingSprint && isHoldingJump && !isOnGround && $leftCast.is_colliding():
		currentlyWallRunning = true
		camera.rotation_degrees.z = lerp(camera.rotation_degrees.z, -25, 0.1)
		stamina -= delta
		wallRunDelay -= delta
	elif isHoldingSprint && isHoldingJump && !isOnGround && $rightCast.is_colliding():
		currentlyWallRunning = true
		camera.rotation_degrees.z = lerp(camera.rotation_degrees.z, 25, 0.1)
		stamina -= delta
		wallRunDelay -= delta
	else:
		currentlyWallRunning = false
		camera.rotation_degrees.z = lerp(camera.rotation_degrees.z, 0, 0.1)
		stamina = lerp(stamina, baseStamina, 0.01)
	
	if stamina > 0:
			outOfStamina = false
	else: 
		outOfStamina = false
	
	if currentlyWallRunning:
		if !outOfStamina:
			velocity.y = 0
		else:
			velocity.y += GRAVITY / 3 * delta
	else:
		velocity.y += GRAVITY * delta
		
	velocity.x = lerp(velocity.x,movementDirection.x * movementSpeed,acceleration * delta)
	velocity.z = lerp(velocity.z,movementDirection.z * movementSpeed,acceleration * delta)
	velocity = move_and_slide(velocity, Vector3.UP)
	
	
	
	
	#Controls movement direction
func _getMovementDirection():
	var direction = Vector3.DOWN
	if Input.is_action_pressed("moveForwards") and Input.is_action_pressed("moveBackwards"):
		direction = Vector3(0,0,0)
	elif Input.is_action_pressed("moveForwards"):
			direction -= transform.basis.z
	elif Input.is_action_pressed("moveBackwards"):
			direction += transform.basis.z
	
	if Input.is_action_pressed("moveLeft") and Input.is_action_pressed("moveRight"):
		direction = Vector3(0,0,0)
	elif Input.is_action_pressed("moveLeft"):
		direction -= transform.basis.x
	elif Input.is_action_pressed("moveRight"):
		direction += transform.basis.x
	return direction

#Camera rotation and clamping
func _input(event):
	if event is InputEventMouseMotion:
		var movement = event.relative
		camera.rotation.x -= deg2rad(movement.y*sensitivity)
		camera.rotation.x = clamp($Camera.rotation.x, deg2rad(-90), deg2rad(90))
		rotation.y += -deg2rad(movement.x*sensitivity)
