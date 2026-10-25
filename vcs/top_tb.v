// top_tb.v

`timescale 1ns/10ps
/*module timeunit;
   initial $timeformat(-9,1," ns",10);
endmodule*/

// Here is the testbench proper:
module top_testbench ( ) ;

    // Test bench gets wires for all device under test (DUT) outputs:

   wire [7:0] BestDist;
   wire [3:0] motionX, motionY;

   // Regs for all DUT inputs:
   reg               clock;
   reg               start;
  
   reg [7:0]	    Rmem[0:255]; 
   reg [7:0]	    Smem[0:1023];
   //reg [3:0] Expected_motionX, Expected_motionY;
   integer Expected_motionX, Expected_motionY;
   integer 		i;
   integer 		j;
   integer signed x, y;
   wire [7:0] R, S1, S2;
	wire [7:0] AddressR;
	wire [9:0] AddressS1, AddressS2;
	wire completed;

//(dut means device under test)
   top dut (
   	.BestDist(BestDist [7:0]),
		.motionX(motionX [3:0]),
		.motionY(motionY [3:0]),
      .clock(clock),
		.start(start),
		.AddressR(AddressR),
		.AddressS1(AddressS1),
		.AddressS2(AddressS2),
		.R(R),
		.S1(S1),
		.S2(S2),
		.completed(completed),
		.VDD(1'b1),
		.VSS(1'b0));

//Referesen and search memories

	ROM_R memR_u(.clock(clock), .AddressR(AddressR), .R(R));

	ROM_S memS_u(.clock(clock), .AddressS1(AddressS1), .AddressS2(AddressS2), .S1(S1), .S2(S2));


  // Setup clock to automatically strobe with a period of 20.
   always #10 clock = ~clock;

   initial
     begin
     	$vcdpluson;
     	$fsdbDumpvars;
        // First setup up to monitor all inputs and outputs
        $monitor ("time=%5d ns, clock =%b, start =%b, BestDist =%b, motionX =%d, motionY =%d, count =%d", $time, clock, start , BestDist[7:0], motionX[3:0], motionY[3:0], dut.ctl_u.count[12:0]);
	

	//randomize Smem
	foreach (Smem[i]) begin
		Smem[i] = $urandom_range(0,255);
	end

	//randomize expected motionX and motionY
	Expected_motionX = $urandom_range(0,15)-8;	
	Expected_motionY = $urandom_range(0,15)-8;
	
	//extract Rmem from Smem for Expected_motionX and Expected_motionY

	foreach (Rmem[i]) begin
			Rmem[i] = Smem[32*8+8+(((i/16)+Expected_motionY)*32)+((i%16)+Expected_motionX)];
			//if(i==0) Rmem[i] = Rmem[i] +1; //to puturb pixle 0
		end	

	//initilize memories

	foreach (memR_u.Rmem[i]) begin
				memR_u.Rmem[i]= Rmem[i];
			end
	foreach (memS_u.Smem[i]) begin
				memS_u.Smem[i]= Smem[i];
			end		
        // First initialize all registers
	//$readmemh("ref.txt", memR_u.Rmem);
	//$readmemh("search.txt", memS_u.Smem);
	clock = 1'b0;
	start = 1'b0;
	//completed = 1'b1;

	@(posedge clock);#10;
	start = 1'b1;
	//completed = 1'b0;
	
	for(i=0;i<4112;i=i+1)
		begin
		  
                  if (dut.comp_u.newBest == 1'b1) 
		    begin
                      $display("New Result Coming!");
		    end
		    @(posedge clock);#10;
		end

	start = 1'b0;
	//completed = 1'b1;

	@(posedge clock);#10;

        if (motionX >= 8)
	 x = motionX - 16;
	else
	 x = motionX;

	if (motionY >= 8)
	  y = motionY - 16;
        else
	  y = motionY;
	
	//print memory contnet
	$display("Reference Memory content:");
	foreach (Rmem[i]) begin
		if(i%16 == 0) $display("  ");
		$write("%h  ",Rmem[i]);
		if(i == 255) $display("  ");
	end

$display("Search Memory content:");
foreach (Smem[i]) begin
		if(i%32 == 0) $display("  ");
		$write("%h  ",Smem[i]);
		if(i == 1023) $display("  ");
	end


//print test results

	if (BestDist == 8'b11111111)
		$display("Reference Memory Not Found in the Search Window!");
	else
	    begin
	        if (BestDist == 8'b00000000)
		    $display("Perfect Match Foudn for Reference Memory in the Search Window : BestDist = %d, motionX  = %d , motionY =  %d Expected motionX  = %d , Expected motionY =  %d ", BestDist, x , y, Expected_motionX, Expected_motionY);
		else
		    $display("Non-perfect Match Found the Reference Memory in the Search Window : BestDist = %d, motionX  = %d , motionY =  %d Expected motionX  = %d , Expected motionY =  %d ", BestDist, x, y, Expected_motionX, Expected_motionY);
	    end

	if (x == Expected_motionX && y == Expected_motionY) begin
	 $display("DUT motion outputs Do match expected motions: DUT motionX = %d DUT motionY = %d Expected_motionX = %d Expected_motionY = %d",x, y, Expected_motionX, Expected_motionY);
	 end
	 else begin
	 	$display("DUT motion outputs DO NOT match expected motions: DUT motionX = %d DUT motionY = %d Expected_motionX = %d Expected_motionY = %d",x, y, Expected_motionX, Expected_motionY);
	 end


	$display("All tests completed\n\n");

        $finish;
     end

   // This is to create a dump file for offline viewing.
   initial
     begin
        $dumpfile ("top.dump");
        $dumpvars (0, top_testbench);
     end 

endmodule // top_testbench
