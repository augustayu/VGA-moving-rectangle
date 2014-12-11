VGA-moving-rectangle
====================
using xilinx ISE
Nexys 3 Spartan 6 
language verilog
Because the rectangle is animating in both the x- and y-directions, it will move at a 45 degree angle relative to the display’s axes.Finally the rectangle must not animate past the edges of the drawable region of the display. Another set of comparators is utilized to check the rectangle boundaries against the drawable region boundaries. When they collide, the velocity register values need to be updated to reverse the x- or y-motion of the rectangle so that it does not animate past that particular boundary. Since only one velocity will be reversed at a time (unless the box collides exactly with the corner of the display) this behavior will cause the box to change its direction of motion 90 degrees when a collision occurs (180 if it’s a corner collision).
