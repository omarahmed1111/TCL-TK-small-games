package require Tk

label .info1 -text "I've got a secret number."
label .info2 -text "Can you guess it?"
grid .info1 .info2
button .win -text "1" -command {tk_messageBox -type ok -message "You Win"}
button .lose -text "2" -command {tk_messageBox -type ok -message "You Lose"}
grid .win .lose