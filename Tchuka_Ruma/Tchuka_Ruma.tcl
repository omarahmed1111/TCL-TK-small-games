################################################################
# proc moveBeans {binNumber}--
#    moves beans from one bin to successive bins.
#    If there are N beans in a bin, One bean will be placed
#    into each of N bins after the start bin.
#    Each time a bean goes into bin 4, it goes out of play.
#    If there are no beans in play (8 beans are in bin 4), 
#    the player wins.
#    If the last bean goes into an empty bin, the player loses.
# Arguments
#   binNumber	The number of the bin to take beans from.
# 
# Results
#   The global variable bins is modified.  
#   The buttons -text option is configured to reflect the number of
#   beans in the bins.

proc moveBeans {binNumber} {
  global board
  
  # Save the number of beans we'll be moving.
  set beanCount $board($binNumber)

  # Empty this bin
  set board($binNumber) 0

  # Put the beans into the bins after this bin.

  for {set i $beanCount} {$i > 0} {incr i -1} {
    incr binNumber 
    
    # If we've reached the end of the board, 
    # go back to the beginning.
    if {$binNumber > 4} {
      set binNumber 0
    }

    # If this is the last bin, update the "goal" bin
    #  Check to see if the player has won.

    if {$binNumber == 4} {
      incr board(goal)
      if {$board(goal) == 8} {
        tk_messageBox -type ok -message "You just Won!"
	exit
      }
    } else {
      # Last bean can't go into an empty bin
      if {($i == 1) && ($board($binNumber) == 0)} {
        tk_messageBox -type ok -message "You just lost"
	exit
      }
      # Put this bean in a bin.
      incr board($binNumber)
    }
  }
  showBeans
}

################################################################
# proc showBeans {}--
#    Make the GUI reflect the contents of the board array
# Arguments
#   None
# 
# Results
#   Updates the GUI
# 
proc showBeans {} {
  global board

  # Update all the canvases to reflact the number of beans
  # in their bin.

  for {set i 0} {$i < 4} {incr i} {
    .c_$i delete beans
    for {set j 0} {$j < $board($i)} {incr j} {
       # Calculate a position for the upper left corner of this
       #  oval (bean).  
       set x1 [expr int (rand()*8) + 20 + ($j*14)]
       set y1 [expr int(rand()*20 + 22)]
       set x2 [expr $x1 + 12]
       set y2 [expr $y1 + 8]
       .c_$i create oval $x1 $y1 $x2 $y2 -fill brown -tag beans
    }
  }
    .c_goal delete beans

    for {set j 0} {$j < $board(goal)} {incr j} {
       set x1 [expr int(rand()*10 + 20 + ($j*20))]
       set y1 [expr int(rand()*20 + 22)]
       set x2 [expr $x1 + 12]
       set y2 [expr $y1 + 8]
       .c_goal create oval $x1 $y1 $x2 $y2 -fill brown -tag beans
    }
}

################################################################
# proc initializeGame {}--
#    initializes the game variables.
# Arguments
#   NONE
# 
# Results
#   Modifies the global variable "board"
# 
proc initializeGame {} {
  global board
  # Put beans into the first 4 bins.

  for {set i 0} {$i < 4} {incr i} {
    set board($i) 2
  }

  # Make sure there are no beans in the last bin
  set board(goal) 0
}

################################################################
# proc buildBoard --
#    Creates the GUI
# Arguments
#   NONE
# 
# Results
#   Modifies the screen.  Creates widgets
# 
proc buildBoard {} {
  global board
  
  # We have 4 canvases that act like buttons, and
  # one larger canvas to be the goal.

  # Build the 4 canvases that hold the beans when the game starts

  for {set i 0} {$i < 4} {incr i} {

    # Create and grid the canvas

    canvas .c_$i -width 100 -height 80
    grid .c_$i -row 1 -column $i 

    # Bind the Left ButtonRelease Event to make this
    # canvas act like a button

    bind .c_$i <ButtonRelease-1> "moveBeans $i"
    
    # Create an oval to be the bin on this canvas
    .c_$i create oval 10 10 90 70 -fill gold
  }
  
  # Create and grid the goal canvas and put a larger
  # oval in it for the destination bin.

  canvas .c_goal -width 180 -height 80
  .c_goal create oval 10 10 170 70 -fill gold
  grid  .c_goal -row 1 -column 4 -sticky news 
}

initializeGame
buildBoard
showBeans