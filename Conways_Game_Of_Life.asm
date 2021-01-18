#;	Assignment 13
#;	Author: Matthew Kale
#;	Section: 1003
#;	Date Last Modified: 11/26/20
#;	This program implements Conway's Game of Life on a wraparound board

.data
#;	System Service Codes
	SYSTEM_EXIT = 10
	SYSTEM_PRINT_INTEGER = 1
	SYSTEM_PRINT_STRING = 4
	SYSTEM_READ_INTEGER = 5
	
#;	Board Parameters
	MAXIMUM_WIDTH = 80
	MINIMUM_WIDTH = 5
	MAXIMUM_HEIGHT = 40
	MINIMUM_HEIGHT = 5
	MINIMUM_GENERATIONS = 1
	WORD_SIZE = 4
	gameBoard: .space MAXIMUM_WIDTH * MAXIMUM_HEIGHT * WORD_SIZE
	
#;	Strings
	heightPrompt: .asciiz "Board Height: "
	widthPrompt: .asciiz "Board Width: "
	generationsPrompt: .asciiz "Generations to Simulate: "
	errorWidth: .asciiz "Board width must be between 5 and 80.\n"
	errorHeight: .asciiz "Board height must be between 5 and 40.\n"
	errorGenerations: .asciiz "Generation count must be at least 1.\n"
	initialGenerationLabel: .asciiz "Initial Generation\n"
	generationLabel: .asciiz "Generation #"
	newLine: .asciiz "\n"
	livingCell: .asciiz "¤"
	deadCell: .asciiz "•"
	
	widthValue: .word 0
	heightValue: .word 0
	totalGenerationNumber: .word 0
	currentGeneration: .word 0
.text
.globl main
.ent main
main:

	getWidth:
		# Ask for width of gameboard
		li $v0, SYSTEM_PRINT_STRING
		la $a0, widthPrompt
		syscall

		# Get input from user
		li $v0, SYSTEM_READ_INTEGER
		syscall
		sw $v0, widthValue

		# Check that width is within specified bounds
		bgeu $v0, MINIMUM_WIDTH, checkWidthMax
			li $v0, SYSTEM_PRINT_STRING
			la $a0, errorWidth
			syscall
		b getWidth

		checkWidthMax:
		bleu $v0, MAXIMUM_WIDTH, getHeight
			li $v0, SYSTEM_PRINT_STRING
			la $a0, errorWidth
			syscall
		b getWidth
	
	getHeight:
		# Ask for height of gameboard
		li $v0, SYSTEM_PRINT_STRING
		la $a0, heightPrompt
		syscall

		# Get input from user
		li $v0, SYSTEM_READ_INTEGER
		syscall
		sw $v0, heightValue

		# Check that height is within specified bounds
		bgeu $v0, MINIMUM_HEIGHT, checkHeightMax
			li $v0, SYSTEM_PRINT_STRING
			la $a0, errorHeight
			syscall
		b getHeight

		checkHeightMax:
		bleu $v0, MAXIMUM_HEIGHT, initializeBoard
			li $v0, SYSTEM_PRINT_STRING
			la $a0, errorHeight
			syscall
		b getHeight

	# Initialize Board Elements to 0
	initializeBoard:
	lw $s0, widthValue
	lw $s1, heightValue
	mul $t0, $s0, $s1

	li $t7, 0
	li $a0, 0
	la $a1, gameBoard
	loopInitializeBoard:
		mul $t1, $a0, 32
		add $t1, $a1, $t1
		sw $t7, ($t1)

		add $a0, $a0 , 1
		sub $t0, $t0, 1

	bnez $t0, loopInitializeBoard

	# Insert Glider at 2,2
	la $a0, gameBoard
	move $a1, $s0
	li $a2, 2
	li $a3, 2
	jal insertGlider
	
	# Ask for generations to calculate
	getGenerations:
		# Ask for generations to simulate
	 	li $v0, SYSTEM_PRINT_STRING
	 	la $a0, generationsPrompt
	 	syscall

		# Get input from user
		li $v0, SYSTEM_READ_INTEGER
		syscall
		sw $v0, totalGenerationNumber

		# Ensure # of generations is positive
	 	bgeu $v0, MINIMUM_GENERATIONS, generationsValid
	 		li $v0, SYSTEM_PRINT_STRING
	 		la $a0, errorGenerations
	 		syscall
	 	b getGenerations

	generationsValid:

	# Print New Line
	li $v0, SYSTEM_PRINT_STRING
	la $a0, newLine
	syscall

	# Print Initial Board Label
	li $v0, SYSTEM_PRINT_STRING
	la $a0, initialGenerationLabel
	syscall

	# Print Board
	la $a0, gameBoard
	lw $a1, widthValue
	lw $a2, heightValue
	jal printGameBoard

	# Print New Line
	li $v0, SYSTEM_PRINT_STRING
	la $a0, newLine
	syscall

	loopPlayTurn:
		# Add Current Generation
		lw $t1, currentGeneration
		add $t1, $t1, 1
		sw $t1, currentGeneration
	
		# Play Turn
		la $a0, gameBoard
		lw $a1, widthValue
		lw $a2, heightValue
		jal playTurn
		
		# Print Generation#
		li $v0, SYSTEM_PRINT_STRING
		la $a0, generationLabel
		syscall

		li $v0, SYSTEM_PRINT_INTEGER
		lw $a0, currentGeneration
		syscall

		# Print New Line
		li $v0, SYSTEM_PRINT_STRING
		la $a0, newLine
		syscall

		# Print Gameboard
		la $a0, gameBoard
		lw $a1, widthValue
		lw $a2, heightValue
		jal printGameBoard

		# Print New Line
		li $v0, SYSTEM_PRINT_STRING
		la $a0, newLine
		syscall

		# Decrement total generations for loop
		lw $t0, totalGenerationNumber
		sub $t0, $t0, 1
		sw $t0, totalGenerationNumber

	bnez $t0, loopPlayTurn
			
	endProgram:
	li $v0, SYSTEM_EXIT
	syscall
.end main

#;  Insert Glider Pattern
#;	••¤
#;	¤•¤
#;	•¤¤
#;	0,0 is in the top left of the gameboard
#;	Assume all cells are dead in the 3x3 space to start with.
#;	Argument 1: Address of Game Board
#;	Argument 2: Width of Game Board
#;	Argument 3: X Position of Top Left Square of Glider "•"
#;	Argument 4: Y Position of Top Left Square of Glider "•"
.globl insertGlider
.ent insertGlider
insertGlider:
	# Get starting spot
	mul $t0, $a3, $a1
	add $t0, $t0, $a2
	mul $t0, $t0, 32
	add $a0, $a0, $t0
	li $t7, 1

	# Calculate [0][2] address
	add $s0, $a0, 64  
	sw $t7, ($s0)

	# Calculate [1][0] address
	mul $t0, $a1, 32
	add $s0, $a0, $t0 
	sw $t7, ($s0) 

	# Calculate [1][2] address
	add $t0, $a1, 2
	mul $t0, $t0, 32
	add $s0, $a0, $t0 
	sw $t7, ($s0)

	# Calculate [2][1] address
	mul $t0, $a1, 2
	add $t0, $t0, 1
	mul $t0, $t0, 32 
	add $s0, $a0, $t0 
	sw $t7, ($s0)

	# Calculate [2][2] address
	mul $t0, $a1, 2
	add $t0, $t0, 2
	mul $t0, $t0, 32 
	add $s0, $a0, $t0 
	sw $t7, ($s0)	

	jr $ra
.end insertGlider

#;	Updates the state of the gameboard
#;	For each Cell:
#;	Living: 2-3 Living Neighbors -> Stay Alive, otherwise Change to Dead
#;	Dead: Exactly 3 Living Neighbors -> Change to Alive 
#;	Cell States:
#;		0: Currently Dead, Stay Dead (00b)
#;		1: Currently Living, Change to Dead (01b)
#;		2: Currently Dead, Change to Living (10b)
#;		3: Currently Living, Stay Living (11b)
#;	Right Bit: Current State
#;	Left Bit: Next State
#;	All cells must maintain their current state until all next states have been determined.
#;	Argument 1: Address of Game Board
#;	Argument 2: Width of Game Board
#;	Argument 3: Height of Game Board
.globl playTurn
.ent playTurn
playTurn:
	# Board size to loop
	mul $s0, $a1, $a2
	# sub $s0, $s0, 1

	li $t0, 0		# Current Row
	li $t1, 0		# Current Column
	li $t7, 32		# Data Size
	checkCells:
		li $s1, 0	# Number of alive adjacents

		# top left
		topLeft:
			sub $t2, $t0, 1		# Subtract Row
			sub $t3, $t1, 1		# Subtract Column

			# get adjusted values
			# adjustedX = (width + xIndex) % width
			add $t3, $t3, $a1
			rem $t3, $t3, $a1
			# adjustedY = (height + yIndex) % height
			add $t2, $t2, $a2
			rem $t2, $t2, $a2

			# baseAddress + (x + (y * rowWidth)) * dataSize
			mul $t4, $t2, $a1
			add $t4, $t4, $t3  
			mul $t4, $t4, $t7
			add $t4, $t4, $a0

			# Check if currently living
			lw $t5, ($t4)
			rem $t5, $t5, 2
			bne $t5, 1, topMiddle
				add $s1, $s1, 1


		# top middle
		topMiddle:
			sub $t2, $t0, 1		# Subtract Row
			move $t3, $t1
			# get adjusted values
			# adjustedX = (width + xIndex) % width
			add $t3, $t1, $a1
			rem $t3, $t3, $a1
			# adjustedY = (height + yIndex) % height
			add $t2, $t2, $a2
			rem $t2, $t2, $a2

			# baseAddress + (x + (y * rowWidth)) * dataSize
			mul $t4, $t2, $a1
			add $t4, $t4, $t3  
			mul $t4, $t4, $t7
			add $t4, $t4, $a0

			# Check if currently living
			lw $t5, ($t4)
			rem $t5, $t5, 2
			bne $t5, 1, topRight
				add $s1, $s1, 1


		# top right
		topRight:
			sub $t2, $t0, 1		# Subtract Row
			add $t3, $t1, 1		# Add Column

			# get adjusted values
			# adjustedX = (width + xIndex) % width
			add $t3, $t3, $a1
			rem $t3, $t3, $a1
			# adjustedY = (height + yIndex) % height
			add $t2, $t2, $a2
			rem $t2, $t2, $a2

			# baseAddress + (x + (y * rowWidth)) * dataSize
			mul $t4, $t2, $a1
			add $t4, $t4, $t3  
			mul $t4, $t4, $t7
			add $t4, $t4, $a0

			# Check if currently living
			lw $t5, ($t4)
			rem $t5, $t5, 2
			bne $t5, 1, middleLeft
				add $s1, $s1, 1

		# middle left
		middleLeft:
			move $t2, $t0
			sub $t3, $t1, 1		# Subtract Column

			# get adjusted values
			# adjustedX = (width + xIndex) % width
			add $t3, $t3, $a1
			rem $t3, $t3, $a1
			# adjustedY = (height + yIndex) % height
			add $t2, $t2, $a2
			rem $t2, $t2, $a2

			# baseAddress + (x + (y * rowWidth)) * dataSize
			mul $t4, $t2, $a1
			add $t4, $t4, $t3  
			mul $t4, $t4, $t7
			add $t4, $t4, $a0

			# Check if currently living
			lw $t5, ($t4)
			rem $t5, $t5, 2
			bne $t5, 1, middleRight
				add $s1, $s1, 1
		# middle right
		middleRight:
			move $t2, $t0
			add $t3, $t1, 1		# Add Column

			# get adjusted values
			# adjustedX = (width + xIndex) % width
			add $t3, $t3, $a1
			rem $t3, $t3, $a1
			# adjustedY = (height + yIndex) % height
			add $t2, $t2, $a2
			rem $t2, $t2, $a2

			# baseAddress + (x + (y * rowWidth)) * dataSize
			mul $t4, $t2, $a1
			add $t4, $t4, $t3  
			mul $t4, $t4, $t7
			add $t4, $t4, $a0

			# Check if currently living
			lw $t5, ($t4)
			rem $t5, $t5, 2
			bne $t5, 1, bottomLeft
				add $s1, $s1, 1

		# bottom left
		bottomLeft:
			add $t2, $t0, 1		# Add Row
			sub $t3, $t1, 1		# Subtract Column

			# get adjusted values
			# adjustedX = (width + xIndex) % width
			add $t3, $t3, $a1
			rem $t3, $t3, $a1
			# adjustedY = (height + yIndex) % height
			add $t2, $t2, $a2
			rem $t2, $t2, $a2

			# baseAddress + (x + (y * rowWidth)) * dataSize
			mul $t4, $t2, $a1
			add $t4, $t4, $t3  
			mul $t4, $t4, $t7
			add $t4, $t4, $a0

			# Check if currently living
			lw $t5, ($t4)
			rem $t5, $t5, 2
			bne $t5, 1, bottomMiddle
				add $s1, $s1, 1

		# bottom middle
		bottomMiddle:
			add $t2, $t0, 1		# Add Row
			move $t3, $t1

			# get adjusted values
			# adjustedX = (width + xIndex) % width
			add $t3, $t3, $a1
			rem $t3, $t3, $a1
			# adjustedY = (height + yIndex) % height
			add $t2, $t2, $a2
			rem $t2, $t2, $a2

			# baseAddress + (x + (y * rowWidth)) * dataSize
			mul $t4, $t2, $a1
			add $t4, $t4, $t3  
			mul $t4, $t4, $t7
			add $t4, $t4, $a0

			# Check if currently living
			lw $t5, ($t4)
			rem $t5, $t5, 2
			bne $t5, 1, bottomRight
				add $s1, $s1, 1
		# bottom right
		bottomRight:
			add $t2, $t0, 1		# Add Row
			add $t3, $t1, 1		# Add Column

			# get adjusted values
			# adjustedX = (width + xIndex) % width
			add $t3, $t3, $a1
			rem $t3, $t3, $a1
			# adjustedY = (height + yIndex) % height
			add $t2, $t2, $a2
			rem $t2, $t2, $a2

			# baseAddress + (x + (y * rowWidth)) * dataSize
			mul $t4, $t2, $a1
			add $t4, $t4, $t3  
			mul $t4, $t4, $t7
			add $t4, $t4, $a0

			# Check if currently living
			lw $t5, ($t4)
			rem $t5, $t5, 2
			bne $t5, 1, checkNextCellState
				add $s1, $s1, 1


		checkNextCellState:
			# Check current cell state
			# get adjusted values
			# adjustedX = (width + xIndex) % width
			add $t1, $t1, $a1
			rem $t1, $t1, $a1
			# adjustedY = (height + yIndex) % height
			add $t0, $t0, $a2
			rem $t0, $t0, $a2

			# baseAddress + (x + (y * rowWidth)) * dataSize
			mul $t4, $t0, $a1
			add $t4, $t4, $t1  
			mul $t4, $t4, $t7
			add $t4, $t4, $a0

			# Check if currently living
			lw $t5, ($t4)
			rem $t5, $t5, 2

			bne $t5, 1, cellDead
				# Currently Alive
				bgt $s1, 3, nextCellDead
				blt $s1, 2, nextCellDead
					# Next Cell Alive
					li $t6, 3
					sw $t6, ($t4)
					j nextCell
				nextCellDead:
					# Next Cell Dead
					li $t6, 1
					sw $t6, ($t4)
					j nextCell

			cellDead:
				# Currently Dead
				bne, $s1, 3, cellDeadNextCellDead
					# Next Cell Alive
					li $t6, 2
					sw $t6, ($t4)
					j nextCell
				cellDeadNextCellDead:
					# Next Cell Dead
					li $t6, 0
					sw $t6, ($t4)

			nextCell:
		# Check for New Line
		add $t1, $t1, 1
		bne $t1, $a1, notNextLine
			add $t0, $t0, 1
			li $t1, 0
		notNextLine:

		# Decrement loop size
		sub $s0, 1
	bnez $s0, checkCells

	# Update cells for next turn
	updateGameBoard:
		move $s2, $a0
		li $s3, 0				# index
		mul $s4, $a1, $a2		# total size

		loopUpdateGameBoard:
			# Get address
			mul $t0, $s3, 32 
			add $t1, $s2, $t0

			# Get value
			lw $t2, ($t1)

			# Divide value by 2
			divu $t2, $t2, 2

			# Store value
			sw $t2, ($t1)

			# Add to the address and update loop variable
			add $s3, $s3, 1
			sub $s4, $s4, 1
		bnez $s4, loopUpdateGameBoard
	jr $ra
.end playTurn

#;	Prints the array using the specified dimensions
#;	For values of 1, print as a livingCell "¤"
#;	For values of 0, print as a deadCell "•"
#;	Argument 1: Address of Array ($a0)
#;	Argument 2: Width of Array ($a1)
#;	Argument 3: Height of Array ($a2)
.globl printGameBoard
.ent printGameBoard
printGameBoard:
	move $s1, $a0
	li $a3, 0				# index
	mul $s0, $a1, $a2		# total size
			
	printLoop:
		# Get value from address
		mul $t0, $a3, 32 
		add $t1, $s1, $t0
		lw $t1, ($t1)

		# Get current value
		remu $t1, $t1, 2

		# Print out for dead cell
		bne $t1, 0, cellLiving
			li $v0, SYSTEM_PRINT_STRING
			la $a0, deadCell
			syscall
		j printNextCell

		# Print out for living cell
		cellLiving:
			li $v0, SYSTEM_PRINT_STRING
			la $a0, livingCell
			syscall

		printNextCell:
			# Add to index
			add $a3, $a3, 1

			# Check for new line
			rem $t2, $a3, $a1
			bne $t2, 0, printNotNextLine
				# Print new line if needed
				li $v0, SYSTEM_PRINT_STRING
				la $a0, newLine
				syscall

			# Decrement loop variable
			printNotNextLine:
				sub $s0, $s0, 1
	bnez $s0, printLoop

	jr $ra
.end printGameBoard
