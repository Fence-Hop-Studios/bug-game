extends KinematicBody

const GRAVITY = -15


var velocity = Vector3.ZERO
var baseMovementSpeed = 3
var movementSpeed
var acceleration:float = 6.0
var jumpHeight = 7

var baseHealth:float = 100
var health:float = baseHealth
var baseStamina:float = 4
var stamina:float = baseStamina
var outOfStamina:bool
var wallJumpDelay:float = 1
var readyToWallRun:bool

#bug jump
var bugJumping:bool
var chargeBugJump:float
var bugJumpChargeTimer:float

var leftOrRightCastColliding:bool #Used to shorten code that doesn't need right or left specifics.
var isHoldingJump:bool
var isHoldingSprint:bool
var isOnGround:bool
var currentlyMoving:bool
var currentlyWallRunning:bool
var currentlySliding:bool
var currentlyCrouching:bool

var fallTimer:float

var sensitivity:float = 0.06

onready var camera = $Camera


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED) 
	
	
func _process(delta):
	
	if $rightCast.is_colliding() or $leftCast.is_colliding():
		leftOrRightCastColliding = true
		fallTimer = 0 #Resets the fall timer to stop fov from getting stuck while wall running.
	
	print(fallTimer)
	
	
	#used to check if player is moving, does not work below.
	if Input.is_action_pressed("moveForwards"):
		currentlyMoving = true
	else:
		currentlyMoving = false
		
	if $floorCast.is_colliding() == true:
		isOnGround = true
		fallTimer = 0
	else:
		fallTimer += delta
		isOnGround = false
	
	if !isOnGround && !leftOrRightCastColliding && fallTimer >= 2:
		camera.fov = lerp(camera.fov, 115, 0.07)

func _physics_process(delta):
	var movementDirection = _getMovementDirection()

	#checks if the player is currently sprinting, sets FOV higher if true as well as movespeed
	if Input.is_action_pressed("sprint"):
		isHoldingSprint = true
		movementSpeed = baseMovementSpeed * 2 
		if currentlyMoving:
			camera.fov = lerp(camera.fov, 105, 0.09)
		elif isOnGround:
			camera.fov = lerp(camera.fov, 90, 0.05)
	elif currentlyCrouching:
		isHoldingSprint = false
		movementSpeed = baseMovementSpeed / 2
		camera.fov = lerp(camera.fov, 90, 0.05)
	else:
		isHoldingSprint = false
		movementSpeed = baseMovementSpeed
		camera.fov = lerp(camera.fov, 90, 0.05)
		
	#Jumping
	if Input.is_action_just_pressed("jump") && isOnGround:
		velocity.y = jumpHeight
	if Input.is_action_pressed("jump") && !isHoldingJump:
		isHoldingJump = true
	if Input.is_action_pressed("jump") && !currentlyMoving: #Disable this to disable bug jumping
		bugJumpChargeTimer += delta
		if currentlyWallRunning && bugJumpChargeTimer >= 1.5 && !currentlyMoving:
			chargeBugJump = chargeBugJump + 0.5
			bugJumping = true
			if chargeBugJump >= 25: #sets max bug jump veloc
				chargeBugJump = 25
	elif Input.is_action_just_released("jump") && isHoldingJump:
		if currentlyWallRunning && bugJumping:
			velocity.y = velocity.y + chargeBugJump
			chargeBugJump = 0
			bugJumpChargeTimer = 0
		if currentlyWallRunning: #&& wallJumpDelay <= 0: #Remove comment to fix jump delay
			velocity.y = velocity.y + 10
			chargeBugJump = 0
			#wallJumpDelay = 1
			bugJumpChargeTimer = 0
		isHoldingJump = false
			
	print(camera.translation)
	if Input.is_action_pressed("crouch") && !isHoldingSprint:
		camera.translation = lerp(camera.translation, Vector3(0,0.05,0), 0.1)
		currentlyCrouching = false #This is an intentional bug that means move speed isn't halved when crouching
	else:
		camera.translation = lerp(camera.translation, Vector3(0,0.65,0), 0.1)
		currentlyCrouching = false
	
	
	
	#If the player is holding sprint, jump, is not on the ground and close enough to a wall, wallrun.
	if isHoldingSprint && isHoldingJump && !isOnGround && $leftCast.is_colliding():
		currentlyWallRunning = true
		fallTimer = 0 #Linked to changing the FOV when falling.
		camera.rotation_degrees.z = lerp(camera.rotation_degrees.z, -25, 0.1)
		stamina -= delta
		wallJumpDelay -= delta 
	elif isHoldingSprint && isHoldingJump && !isOnGround && $rightCast.is_colliding(): #There are two of these to control the camera tilting right or left.
		currentlyWallRunning = true
		fallTimer = 0 #Linked to changing the FOV when falling.
		camera.rotation_degrees.z = lerp(camera.rotation_degrees.z, 25, 0.1)
		stamina -= delta
		wallJumpDelay -= delta
	else:
		currentlyWallRunning = false
		camera.rotation_degrees.z = lerp(camera.rotation_degrees.z, 0, 0.1)
		stamina = lerp(stamina, baseStamina, 0.01)
	
	if stamina > 0:
			outOfStamina = false
	else: 
		outOfStamina = false #Set this to true to enable stamina.
	
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
