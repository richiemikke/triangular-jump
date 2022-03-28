pragma circom 2.0.0;

include "../circomlib/bitify.circom";
include "../circomlib/mimcsponge.circom";

/*

    This circuit will verify that the movement of a player  from coordinates A->B->C is correct 
    and the coordinates b and c are in the boundry of the play circle.

*/



//  Checking if x-y coordinate is inside the boundary of the play circle.
template Boundary() {
    signal input x;
    signal input y;
    signal input r;
    signal output out;

    component comp = LessThan(32);
    signal xSq;
    signal ySq;
    signal rSq;
    xSq <== x * x;
    ySq <== y * y;
    rSq <== r * r;
    comp.in[0] <== xSq + ySq;
    comp.in[1] <== rSq;
    out <== comp.out;
}




/* 
  Check that player has enough energy to hop from A->B, where A=(x1,y1) and B=(x2,y2)
*/
template Hop() {
  signal input x1;
  signal input y1;
  signal input x2;
  signal input y2;
  signal input energy;
  signal output out;


  signal diffX;
  signal diffY;
  diffX <== x1 - x2;
  diffY <== y1 - y2;

  component comp = LessEqThan(32);
  signal diffXSq;
  signal diffYSq;
  diffXSq <== diffX * diffX;
  diffYSq <== diffY * diffY;
  comp.in[0] <== diffXSq + diffYSq;
  comp.in[1] <== energy * energy;
  out <== comp.out;
}

template Main() {
  signal input x1;
  signal input y1;
  signal input x2;
  signal input y2;
  signal input x3;
  signal input y3;
  signal input r;
  signal input energy;
  signal output new_location;

  // Checking to see if the coordinates b and c are in the boundary.

  component boundaryB = Boundary();
  boundaryB.x <== x2;
  boundaryB.y <== y2;
  boundaryB.r <== r;
  boundaryB.out === 1;

  component boundaryC = Boundary();
  boundaryC.x <== x3;
  boundaryC.y <== y3;
  boundaryC.r <== r;
  boundaryC.out === 1;

  // A->B->C move should lie on a triangle: Check that the area formed by these 3 points is not 0.
  
  component triangle = GreaterThan(32); 
  signal a1;
  signal a2;
  signal a3;
  a1 <== x1 * (y2 - y3);
  a2 <== x2 * (y3 - y1);
  a3 <== x3 * (y1 - y2);
  triangle.in[0] <== a1 + a2 + a3;
  triangle.in[1] <== 0;
  triangle.out === 1;

  // Making sure that A->B distance is within the energy bounds
  

  component hopAB = Hop();
  hopAB.x1 <== x1;
  hopAB.y1 <== y1;
  hopAB.x2 <== x2;
  hopAB.y2 <== y2;
  hopAB.energy <== energy;
  hopAB.out === 1;

  // Making sure that B->C distance is within the energy bounds
  
  // Since we only perform a check on the distance from A->B with the energy value 
  // and energy is not deducted for the hop, the energy reamins at initial value (ie. regenerated) 
  component hopBC = Hop();
  hopBC.x1 <== x2;
  hopBC.y1 <== y2;
  hopBC.x2 <== x3;
  hopBC.y2 <== y3;
  hopBC.energy <== energy;
  hopBC.out === 1;

  // hashing the location coordinates to store as commitment.
  component mimc = MiMCSponge(2, 220, 1);
  mimc.ins[0] <== x1;
  mimc.ins[1] <== y1;
  mimc.k <== 0;
  new_location <== mimc.outs[0];
}

component main = Main();