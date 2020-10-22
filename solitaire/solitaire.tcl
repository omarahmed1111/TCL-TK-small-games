package require Tk

################################################################
# proc loadImages {}--
#    Load the card images 
# Arguments
#   NONE
# 
# Results
#   The global array "concentration" is modified to include a 
#   list of card image names
# 
proc loadImages {} {
  global concentration
  
  # The card image fileNames are named as S_V.gif where 
  #  S is a single letter for suit (Hearts, Diamonds, Spades, Clubs)
  #  V is a 1 or 2 character descriptor of the suit - one of:
  #     a k q j 10 9 8 7 6 5 4 3 2
  #
  # glob returns a list of fileNames that match the pattern - *_*.gif 
  #  means all fileNames that have a underbar in the name, and a .gif extension.
  
  
  foreach fileName [glob *_*.gif] {
    # We discard the aces to leave 48 cards because that makes a 
    # 6x8 card display.
    puts $fileName
    if {($fileName ne "c_a.gif") &&
        ($fileName ne "h_a.gif") &&
	($fileName ne "d_a.gif") &&
	($fileName ne "s_a.gif")} {
    
      # split the card name (c_8) from the suffix (.gif)
      set card [lindex [split $fileName .] 0]
    
      # Create an image with the card name, using the file
      # and save it in a list of card images: concentration(cards)

      image create photo $card -file $fileName
      lappend concentration(cards) $card
    }
  }
  
  # Load the images to use for the card back and 
  #   for blank cards

  foreach fileName {blank.gif back.gif} {
      # split the card name from the suffix (.gif)
      set card [lindex [split $fileName .] 0]
    
      # Create the image
      image create photo $card -file $fileName
  }
}

################################################################
# proc randomizeList {}--
#    Change the order of the cards in the list
# Arguments
#   originalList	The list to be shuffled
# 
# Results
#   The concentration(cards) list is changed - no cards will be lost
#   of added, but the order will be random.
# 
proc randomizeList {originalList} {

  # How many cards are we playing with.
  set listLength [llength $originalList]
  
  # Initialize a new (random) list to be empty
  set newList {}
  
  # Loop for as many cards as are in the card list at the
  #   start.  We remove one card on each pass through the loop.
  for {set i $listLength} {$i > 0} {incr i -1} {

    # Select a random card from the remaining cards.
    set p1 [expr int(rand() * $i)]

    # Put that card onto the new list of cards
    lappend newList [lindex $originalList $p1]

    # Remove that card from the card list.
    set originalList [lreplace $originalList $p1 $p1]
  }
  
  # Replace the empty list of cards with the new list that's got all
  # the cards in it.
  return $newList
}

################################################################
# proc makeGameBoard {}--
#    Create the game board widgets - canvas and labels.
# Arguments
#   NONE
# 
# Results
#   New GUI widgets are created.
# 
proc makeGameBoard {} {
  # Create and grid the canvas that will hold the card images
  canvas .game -width 890 -height 724 -bg gray
  grid .game -row 1 -column 1 -columnspan 6
  
  # Create and grid the labels for turns and score
  label .lmyScoreLabel -text "My Score"
  label .lmyScore -textvariable concentration(player,score)
  label .lcompScoreLabel -text "Computer Score"
  label .lcompScore -textvariable concentration(computer,score)
  label .lturnLabel -text "Turn"
  label .lturn -textvariable concentration(turn)
  grid .lmyScoreLabel -row 0 -column 1 -sticky e
  grid .lmyScore -row 0 -column 2  -sticky w
  grid .lcompScoreLabel -row 0 -column 3 -sticky e
  grid .lcompScore -row 0 -column 4  -sticky w
  grid .lturnLabel -row 0 -column 5  -sticky e
  grid .lturn -row 0 -column 6  -sticky w
}

################################################################
# proc startGame {}--
#    Actually start a game running
# Arguments
#   NONE
# 
# Results
#   initializes per-game indices in the global array "concentration"
#   The card list is randomized
#   The GUI is modified.
# 
proc startGame {} {
  global concentration
  set concentration(player,score) 0
  set concentration(computer,score) 0
  set concentration(turn) 0
  set concentration(selected,rank) {}
  set concentration(known) {}

  set concentration(computer,x) 2
  set concentration(computer,y) 2

  set concentration(player,x) 800
  set concentration(player,y) 2

  set concentration(cards) [randomizeList $concentration(cards)]
  
  # Save the height and width of the cards to make the code easier
  #  to read.
  set height [image height [lindex $concentration(cards) 0]]
  set width [image width  [lindex $concentration(cards) 0]]

  # Leave spaces between cards.

  incr width
  incr height
  
  # Remove any existing items on the canvas
  .game delete all
  
  # Start in the upper left hand corner
  set x 90
  set y 2
  
  # Step through the list of cards
  
  for {set pos 0} {$pos < [llength $concentration(cards)]} {incr pos} {
    # Place the back-of-a-card image on the board
    # to simulate a card that is face-down.

    .game create image $x $y -image back  -anchor nw -tag card_$pos
    
    # Add a binding on the card back to react 
    #  to a player left-clicking the back.

    .game bind card_$pos <ButtonRelease-1> "playerTurn $pos"
    
    # Step to the next column (the width of a card)
    incr x $width

    # If we've put up 8 columns of cards, reset X to the
    #   far left, and step down one row.
    if {$x >= [expr 90 + ($width * 8)] } {
      set x 90
      incr y $height
    }
  }
}

################################################################
# proc flipImageX {canvas canvasID start end background}--
#    Makes it appear that an image object on a canvas is being flipped
# Arguments
#   canvas	The canvas holding the image
#   canvasID	The identifier for this canvas item
#   start	The initial image being displayed
#   end		The final  image to display
#   background  The color to show behind the image being flipped.
#               This is probably the canvas background color
# 
# Results
#   configuration for the canvas item is modified.
# 
proc flipImageX {canvas canvasID start end background} {
  global concentration
  
  # Get the height/width of the image we'll be using
  set height [image height $start]
  set width  [image width  $start]
  
  # The image will rotate around the X axis
  # Calculate and save the center, since we'll be using it a lot
  set centerX [expr $width  / 2]
  
  # Create a new temp image that we'll be modifying.
  image create photo temp -height $height -width $width
  
  # Copy the initial image into our temp image, and configure the
  # canvas to show our temp image, instead of the original image
  # in this location.
  temp copy $start
  $canvas itemconfigure $canvasID -image temp
  update idle
  after 25

  # copy the start image into the temp with greater
  #   subsampling (making it appear like more and more of an
  #   edge view of the image).  
  # Move the start of the image to the center on each pass
  #  through the loop
  for {set i 2} {$i < 8} {incr i} {
    set left [expr $centerX - $width / (2 * $i)]
    set right [expr $centerX + $width / (2 * $i)]
    temp put $background -to 0 0 $width $height
    temp copy -to $left 0 $right $height -subsample $i 1 $start
    update idle
    after 10
  }

  # copy the end image into the temp with less and less
  #   subsampling (making it appear like less and less of an
  #   edge view of the image).  
  # Move the start of the image away from thecenter on each pass
  #  through the loop
  for {set i 8} {$i > 1} {incr i -1} {
    set left [expr $centerX - $width / (2 * $i)]
    set right [expr $centerX + $width / (2 * $i)]
    temp put $background -to 0 0 $width $height
    temp copy -to $left 0 $right $height -subsample $i 1 $end
    update idle
    after 10
  }
  # configure the canvas to show the final image, and
  # delete our temporary image
  $canvas itemconfigure $canvasID -image $end
  image delete temp
}

################################################################
# proc removeKnownCard {}--
#    Remove a pair of known cards from the known card list
# Arguments
#   card1	a card value like d_4
#   card2	a card value like d_4
# 
# Results
#   State index known is modified if the cards were known
# 
proc removeKnownCard {cardID} {
  global concentration
      set p [lsearch $concentration(known) $cardID]
      if {$p >= 0} { 
        set concentration(known) \
	    [lreplace $concentration(known) $p [expr $p + 1]]
      }
}

proc addKnownCard  {card pos} {
  global concentration
puts "add Known $card $pos"
  set p [lsearch $concentration(known) $card]
  if {$p < 0} {
    lappend concentration(known) $card $pos
  }
}
################################################################
# proc playerTurn {position}--
#    Selects a card for comparison, or checks the current
#    card against a previous selection.
# Arguments
# position 	The position of this card in the deck.
#
# Results
#     The selection fields of the global array "concentration"
#     are modified.
#     The GUI is modified.
# 
proc playerTurn {position} {
  global concentration
  
  set card [lindex $concentration(cards) $position]
  flipImageX .game card_$position back $card gray
  
  addKnownCard $card $position
  
  set rank [lindex [split $card _] 1]

  # If concentration(selected,rank) is empty, this is the first
  #   part of a turn.  Mark this card as selected and we're done.
  if {{} eq $concentration(selected,rank)} {
      # Increment the turn counter
    incr concentration(turn)

    set concentration(selected,rank) $rank
    set concentration(selected,position) $position
    set concentration(selected,card) $card
  } else {
    # If we're here, then this is the second part of a turn.
    # Compare the rank of this card to the previously saved rank.
    
    if {$position == $concentration(selected,position)} {
      return
    }

    # Update the screen *NOW* (to show the card), and pause for one second.
    update idle
    after 1000
  
    # If the ranks are identical, handle the match condition
    if {$rank eq $concentration(selected,rank)} {

      removeKnownCard $card 
      removeKnownCard $concentration(selected,card)

      # set foundMatch to TRUE to mark that we keep playing
      set foundMatch TRUE

      # Increase the score by one
      incr concentration(player,score)

      # Remove the two cards and their backs from the board
      # .game itemconfigure card_$position -image blank 
      # .game itemconfigure card_$concentration(selected,position) -image blank
      .game bind card_$position <ButtonRelease-1> ""
      .game bind card_$concentration(selected,position) <ButtonRelease-1> ""
      
      moveCards card_$position \
          card_$concentration(selected,position) player
      
      # Check to see if we've won yet.
      if {[checkForFinished]} {
        endGame
      }
    } else {
      # If we're here, the cards were not a match.
      # flip the cards to back up (turn the cards face down)

      # set foundMatch to FALSE to mark that the computer goes next
      set foundMatch FALSE

       flipImageX .game card_$position $card back gray
       flipImageX .game card_$concentration(selected,position) \
         $concentration(selected,card) back gray
    }
    
    # Whether or not we had a match, reset the concentration(selected,rank)
    # to an empty string so that the next click will be a select.
    set concentration(selected,rank) {}
    
    # The computer might play after our second card (or it might not)
    if {$foundMatch eq "FALSE"} {
      computerTurn
    }
  }
}

################################################################
# proc chooseRandomPair {}--
#    Choose two random face-down cards from the board
# Arguments
#   NONE
# 
# Results
#   No Side Effects
# 
proc chooseRandomPair {} {
  global concentration
  
  # Look at everything on the canvas.  If it's a 'back' image
  # it's a card that's still in play.
  # The tag associated with the canvas item will be something like
  # card_NUMBER where number is the position in the list of cards
  # that this canvas item is related to.

  foreach item [.game find all] {
    if {[.game itemcget $item -image] eq "back"} {
      # Tag is something like card_#, where # is the
      #  index of this card in concentration(cards)
      set tag [lindex [.game itemcget $item -tag] 0]
      lappend cards [lindex [split $tag _] 1]
    }
  }

  # The length of the list is the number of cards still in play

  set availableCount [llength $cards]

  # Choose any card to start with - this is an index into
  # the list of cards in play
  set guess1 [expr int(rand() * $availableCount)]

  # Make sure the second guess is not the same as the first.
  #   keep changing guess2 until it's not equal to guess1
  # Start by setting the second card equal to the first - 
  #   this forces it make at least one pass through the loop.


  for {set guess2 $guess1} {$guess2 == $guess1} \
      { set guess2 [expr int(rand() * $availableCount)]} {
  }
puts "RTN: $guess1 $guess2 -> [list [lindex $cards $guess1] [lindex $cards $guess2]]"
  return [list [lindex $cards $guess1] [lindex $cards $guess2]]
}

################################################################
# proc findKnownPair {}--
#    Return a pair of cards that will match, 
#    Return an empty list if no known match available.
#
# Arguments
#   NONE
# 
# Results
#   No Side Effect
# 

proc findKnownPair {} {
  global concentration
  
  # concentration(known) is a list of 
  # suit_rank1 position1 suit_rank2 position2 ...
  # Start searching from just after the current position

  set currentPosition 1

  foreach {card1 pos1} $concentration(known) {
    foreach {suit rank} [split $card1 _] {break;}

    # Look for a card with the same rank in the list
    set p [lsearch -start $currentPosition $concentration(known) "*_$rank"]
    if {$p >= 0} {
      # If here, we found a match.  
      set card2 [lindex $concentration(known) $p]
      incr p
      set pos2 [lindex $concentration(known) $p]
      return [list $pos1 $pos2]
    }
    incr currentPosition 2
  }
  return {}
}

################################################################
# proc computerTurn {}--
#    The computer takes a turn
# Arguments
#   NONE
# 
# Results
#   GUI can be modified.
#   concentration(computer,score) may be modified.  Game may end.
# 
proc computerTurn {} {
  global concentration
  
  set pair [findKnownPair]

  if {[llength $pair] != 2} {
    set pair [chooseRandomPair]
  }

  set pos1 [lindex $pair 0]
  set pos2 [lindex $pair 1]

  # Get the images from the list of card images
  set image1 [lindex $concentration(cards) $pos1]
  set image2 [lindex $concentration(cards) $pos2]
  
  # Add the cards to the known list.
  addKnownCard  $image1 $pos1
  addKnownCard  $image2 $pos2

  # Split the card image name into the suit and rank.
  # save the rank.
  set rank1 [lindex [split $image1 _] 1]
  set rank2 [lindex [split $image2 _] 1]

  # Flip the cards to show the front side.

  flipImageX .game card_$pos1 back $image1 gray
  flipImageX .game card_$pos2 back $image2 gray

  # update the screen and wait a couple seconds for the 
  # human player to see what's showing.

  update idle;
  after 2000
  
  if {$rank1 eq $rank2} {
    removeKnownCard $image1 
    removeKnownCard $image2

    # If we're here, then the ranks are the same:
    #   The computer found a match!
    #   Increment the score, 
    #   Move the cards to the computer stack.
    #   check to see we just got the last pair
    #   if not time to exit, we get to play again.

    incr concentration(computer,score) 1
    moveCards card_$pos1 card_$pos2 computer
    if {[checkForFinished]} {
      endGame
      return
    }
    computerTurn
  } else {
    # If we're here, the computer didn't find a match
    # flip the cards to be face down again

    flipImageX .game card_$pos1 $image1 back gray
    flipImageX .game card_$pos2 $image2 back gray
  }
}

################################################################
# proc moveCards {cvs id1 id2 prefix}--
#    moves Cards from their current location to the
#  score pile for 
# Arguments
#   id1		An identifier for a canvas item
#   id2		An identifier for a canvas item
#   prefix	Identifier for which location should get the card
# 
# Results
#   
# 
proc moveCards {id1 id2 prefix} {
  global concentration

  .game raise $id1 
  .game raise $id2
  
  # Get the X and Y coordinates  for the two cards

  foreach {c1x c1y} [.game coords $id1] {break}
  foreach {c2x c2y} [.game coords $id2] {break}
  
  # Calculate the distance that this card is from where
  # it needs to go.  Do this for both the X and Y dimensions.
  # Do it for both cards.

  set d1x [expr $concentration($prefix,x) - $c1x ]
  set d1y [expr $concentration($prefix,y) - $c1y ]

  set d2x [expr $concentration($prefix,x) - $c2x ]
  set d2y [expr $concentration($prefix,y) - $c2y ]
  
  # We'll take 10 steps to move the cards to the new location.
  # Figure out 1/10 the distance to the score pile for each card.

  set step1x [expr $d1x / 10]
  set step1y [expr $d1y / 10]

  set step2x [expr $d2x / 10]
  set step2y [expr $d2y / 10]
  
  # Loop 10 times, moving the card 1/10'th the distance to the
  # new location.  Pause 1/10 of a second (100 ms) between movements.
  # It will take 1 second to move a card from the current location to
  # the desired location.

  for {set i 0} {$i < 10} {incr i} {
    .game move $id1 $step1x $step1y
    .game move $id2 $step2x $step2y
    update idle
    after 100
  }
  
  # Set the matched card location to stack the next card 
  # a bit lower than the previous cards.
  incr concentration($prefix,y) 30
}

################################################################
# proc checkForFinished {}--
#    checks to see if the game is won.  Returns true/false
# Arguments
#   
# 
# Results
#   
# 
proc checkForFinished {} {
  global concentration

  if { [expr $concentration(player,score) + $concentration(computer,score)] \
      == 24} {
    return TRUE
  } else {
    return FALSE
  }
}

################################################################
# proc endGame {}--
#    Provide end of game display and ask about a new game
# Arguments
#   NONE
# 
# Results
#   GUI is modified
# 
proc endGame {} {
  global concentration
    
  set position 0
  foreach card $concentration(cards) {
    .game itemconfigure card_$position -image $card
    incr position
  }
    
  # Update the screen *NOW*, and pause for 2 seconds
  update idle;
  after 2000
    
  .game create rectangle 250 250 450 400 -fill blue \
      -stipple gray50 -width 3 -outline gray  

  button .again -text "Play Again" -command { 
      destroy .again
      destroy .quit
      startGame
  }

  button .quit -text "Quit" -command "exit"

  .game create window 350 300 -window .again
  .game create window 350 350 -window .quit
}
loadImages
makeGameBoard
startGame