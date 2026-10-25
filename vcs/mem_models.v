/* Testbench-side memory models (moved out of top.v; not part of the synthesized design) */

/* Module For Reference Block (Memory) */
module ROM_R (clock, AddressR, R);
	input clock;
	input [7:0] AddressR;
	output [7:0] R;
	
	reg [7:0] R;
	reg [7:0] Rmem[0:255];
    

	//always @(posedge clock) R <= Rmem[AddressR];
	always @(*) R = Rmem[AddressR];

endmodule

/* Module For Search Block (Memory) */
module ROM_S (clock, AddressS1, AddressS2, S1, S2);
	input clock;
	input	[9:0]	AddressS1, AddressS2;
	output	[7:0]	S1, S2;

	reg	[7:0]	S1, S2;
	reg	[7:0]	Smem[0:1023];
        
	/*always @(posedge clock) 
	 begin
		S1 <= Smem[AddressS1];
		S2 <= Smem[AddressS2];
	 end*/

	always @(*) 
	 begin
		S1 = Smem[AddressS1];
		S2 = Smem[AddressS2];
	 end

endmodule
