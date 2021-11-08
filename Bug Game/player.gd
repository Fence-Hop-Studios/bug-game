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
var isHoldingJump:bool #Checks if player is currently holding space
var isHoldingSprint:bool #Checks if player is sprinting
var isOnGround:bool #Checks if player is currently in the air or not
var currentlyMoving:bool #Used to check if moving
var currentlyWallRunning:bool #Used to check if wall running
var currentlySliding:bool #Used to check if sliding
var currentlyCrouching:bool #Used to check if crouching.
var slideTime:float #the length of time the player slides for
var slideDelay:float #just a timer for delaying slide
var slideReady:bool = true # set to true by default to make sure the player can actually slide
var movementLocked:bool #Used to lock movement of character, view and move

var damageTakenRecently:bool
var regenDelay:float
export var healthRegenEnabled:bool
export var healthEnabled:bool
var lastKnownHealth:float
var lastKnownHealthTimer:float

#Bug toggles
var slideFixEnable:bool
var crouchFixEnable:bool
var wallStaminaFixEnable:bool
var bugJumpFixEnable:bool
var jumpDelayFixEnable:bool
export var disableAllBugs:bool

var fallTimer:float
var fallDamageEnabled:bool

var sensitivity:float = 0.06
var toggleSprint:bool = true
var sprintToggled:bool

onready var camera = $Camera


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED) 
	
	if disableAllBugs:
		slideFixEnable = true
		crouchFixEnable = true
		wallStaminaFixEnable = true
		bugJumpFixEnable = true
		jumpDelayFixEnable = true
	
	
func _process(delta):
	
	if $rightCast.is_colliding() or $leftCast.is_colliding():
		leftOrRightCastColliding = true #Resets the fall timer to stop fov from getting stuck while wall running.
	else:
		leftOrRightCastColliding = false
	
	#used to check if player is moving, does not work below.
	if Input.is_action_pressed("moveForwards"):
		currentlyMoving = true
	else:
		currentlyMoving = false
		
		
	if !isOnGround && !currentlyWallRunning && fallTimer >= 2:
		camera.fov = lerp(camera.fov, 110, 0.0008)
		fallDamageEnabled = true
		
	if $floorCast.is_colliding() == true:
		if fallDamageEnabled:
			_damage(20 * fallTimer, "fuckyou")
			fallDamageEnabled = false
		isOnGround = true
		fallTimer = 0
	else:
		fallTimer += delta
		isOnGround = false
	
	#sets the fov to be higher when falling
	
	if healthEnabled:
		if healthRegenEnabled && !damageTakenRecently && regenDelay >= 5:
			if health <= baseHealth:
				health = health + 0.005
		if health < 100:
			lastKnownHealthTimer += delta
			if health < lastKnownHealth:
				damageTakenRecently = true
				regenDelay = 0
			if lastKnownHealth >= health:
				damageTakenRecently = false
				regenDelay += delta
			if lastKnownHealthTimer >= 4:
				lastKnownHealth = health
				lastKnownHealthTimer = 0
		if health >= 100:
			damageTakenRecently = false
			health = 100
		if health < 0:
			health = 0
	
	#controls slide delaying, implement toggling this for boss fight
	if slideFixEnable:
		if Input.is_action_just_released("crouch") && currentlySliding:
			slideTime = 0
			currentlySliding = false
			slideReady = false
			movementLocked = false

		if !slideReady:
			slideDelay += delta
		if !slideReady && slideDelay >= 1.5:
			slideReady = true
			slideDelay = 0

func _physics_process(delta):
	var movementDirection = _getMovementDirection()
	
	#checks if the player is currently sprinting, sets FOV higher if true as well as movespeed
	if Input.is_action_pressed("sprint") && !toggleSprint:
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
		if isOnGround:
			camera.fov = lerp(camera.fov, 90, 0.05)
	#Handles sprint but toggled
	if toggleSprint:
		if Input.is_action_just_pressed("sprint") && toggleSprint && !sprintToggled && !currentlyCrouching:
			sprintToggled = true
		elif Input.is_action_just_pressed("sprint") && toggleSprint && sprintToggled:
			sprintToggled = false
			
		if sprintToggled:
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
			if isOnGround:
				camera.fov = lerp(camera.fov, 90, 0.05)
		
	#Jumping
	if Input.is_action_just_pressed("jump") && isOnGround:
		velocity.y = jumpHeight
	if Input.is_action_pressed("jump") && !isHoldingJump:
		isHoldingJump = true
		
	if Input.is_action_pressed("jump") && !currentlyMoving && !bugJumpFixEnable: #Disable this to disable bug jumping
		bugJumpChargeTimer += delta
		if currentlyWallRunning && bugJumpChargeTimer >= 1.5 && !currentlyMoving:
			chargeBugJump = chargeBugJump + 0.5
			bugJumping = true
			if chargeBugJump >= 25: #sets max bug jump veloc
				chargeBugJump = 25
	
	if Input.is_action_just_released("jump") && isHoldingJump:
		if currentlyWallRunning && bugJumping:
			velocity.y = velocity.y + chargeBugJump
			chargeBugJump = 0
			bugJumpChargeTimer = 0
		if currentlyWallRunning && !jumpDelayFixEnable:
			velocity.y = velocity.y + 10
			chargeBugJump = 0
			bugJumpChargeTimer = 0
		if currentlyWallRunning && wallJumpDelay <= 0 && jumpDelayFixEnable:
			velocity.y = velocity.y + 10
			chargeBugJump = 0
			wallJumpDelay = 1
			bugJumpChargeTimer = 0
		isHoldingJump = false
			
	#crouch system
	if Input.is_action_pressed("crouch") && !isHoldingSprint:
		camera.translation = lerp(camera.translation, Vector3(0,0.05,0), 0.1)
		if crouchFixEnable:
			currentlyCrouching = true
	elif Input.is_action_pressed("crouch") && isHoldingSprint && !currentlyMoving:
		camera.translation = lerp(camera.translation, Vector3(0,0.05,0), 0.1)
		isHoldingSprint = false
		sprintToggled = false
		if crouchFixEnable:
			currentlyCrouching = true
	else:
		camera.translation = lerp(camera.translation, Vector3(0,0.65,0), 0.1)
		currentlyCrouching = false
	
	#Slide system
	if !slideFixEnable:
		if isHoldingSprint && Input.is_action_just_pressed("crouch") && !currentlyCrouching && !currentlySliding:
			currentlySliding = true
		if currentlySliding:
			slideTime += delta
			camera.translation = lerp(camera.translation, Vector3(0,-0.3,0), 0.1)
			camera.fov = lerp(camera.fov, 115, 0.09)
			velocity.x = movementDirection.x * movementSpeed * 2.5
			velocity.z = movementDirection.z * movementSpeed * 2.5
			velocity.y = 0
			if slideTime >= 0.5:
				slideTime = 0
				currentlySliding = false
				movementLocked = false
	#"fixed" slide system
	if slideFixEnable:
		if isHoldingSprint && Input.is_action_just_pressed("crouch") && !currentlyCrouching && !currentlySliding && isOnGround && slideReady && currentlyMoving:
			movementLocked = true
			currentlySliding = true
		if currentlySliding:
			slideTime += delta
			camera.translation = lerp(camera.translation, Vector3(0,-0.3,0), 0.1)
			velocity.x = movementDirection.x * movementSpeed * 2.5
			velocity.z = movementDirection.z * movementSpeed * 2.5
			if slideTime >= 0.5:
				slideTime = 0
				currentlySliding = false
				movementLocked = false
	
	
	#If the player is holding sprint, jump, is not on the ground and close enough to a wall, wallrun.
	if isHoldingSprint && isHoldingJump && !isOnGround && $leftCast.is_colliding():
		currentlyWallRunning = true
		camera.rotation_degrees.z = lerp(camera.rotation_degrees.z, -25, 0.1)
		stamina -= delta
		wallJumpDelay -= delta 
	elif isHoldingSprint && isHoldingJump && !isOnGround && $rightCast.is_colliding(): #There are two of these to control the camera tilting right or left.
		currentlyWallRunning = true
		camera.rotation_degrees.z = lerp(camera.rotation_degrees.z, 25, 0.1)
		stamina -= delta
		wallJumpDelay -= delta
	else:
		currentlyWallRunning = false
		camera.rotation_degrees.z = lerp(camera.rotation_degrees.z, 0, 0.1)
		stamina = lerp(stamina, baseStamina, 0.01)
	
	if stamina > 0:
			outOfStamina = false
	elif wallStaminaFixEnable: 
		outOfStamina = true
	else:
		outOfStamina = false
	
	if currentlyWallRunning:
		fallTimer = 0
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
	if Input.is_action_pressed("moveForwards") and Input.is_action_pressed("moveBackwards") && !movementLocked:
		direction = Vector3(0,0,0)
	elif Input.is_action_pressed("moveForwards"):
			direction -= transform.basis.z
	elif Input.is_action_pressed("moveBackwards") && !movementLocked:
			direction += transform.basis.z
	
	if Input.is_action_pressed("moveLeft") and Input.is_action_pressed("moveRight") && !movementLocked:
		direction = Vector3(0,0,0)
	elif Input.is_action_pressed("moveLeft") && !movementLocked:
		direction -= transform.basis.x
	elif Input.is_action_pressed("moveRight") && !movementLocked:
		direction += transform.basis.x
	return direction

#Camera rotation and clamping
func _input(event):
	if event is InputEventMouseMotion && !movementLocked:
		var movement = event.relative
		camera.rotation.x -= deg2rad(movement.y*sensitivity)
		camera.rotation.x = clamp($Camera.rotation.x, deg2rad(-90), deg2rad(90))
		rotation.y += -deg2rad(movement.x*sensitivity)

func _damage(damageAmount:float, damageType:String):
	health = health - damageAmount
	
