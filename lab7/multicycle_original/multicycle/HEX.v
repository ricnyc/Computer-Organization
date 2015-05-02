// ---------------------------------------------------------------------
// Copyright (c) 2007 by University of Toronto ECE 243 development team 
// ---------------------------------------------------------------------
//
// Major Functions:	Three modules included: HEX, HEXs, chooseHEXs
//
//					HEX:	decode a four-bit input value into
//							7-segment HEX display signals (0 to F)
//					HEXs:	decode four 8-bit inputs to eight 7-segment
//							HEX display signals (not compatible with DE1)
//					chooseHEXs:	decode four 8-bit inputs to a single
//								selected 7-segment HEX display singnals
//								(compatible with both DE1 and DE2)
//
// Input(s):		HEX
//						 in: 4-bit input (HEX: 0 to F)
//					HEXs
//						 in0 - in4: four 8-bit input (HEX: 00 to FF)
//					chooseHEXs
//						 in0-in4: four 8-bit input (HEX: 00 to FF)
//						 select: two-bit input controlling output decoded
//								 signals
//
// Output(s):		HEX/HEXs/chooseHEXs
//						 out: seven-segment display decoded value(s) 
//
// ---------------------------------------------------------------------

module chooseHEXs
(
in0, in1, in2, in3, in4, in5, in6,
select, out3, out2, out1, out0
);
input 	[7:0] in0, in1, in2, in3, in4, in5, in6;
input		[1:0] select;
output 	[6:0] out0, out1, out2, out3;

reg		[7:0] temp_in0, temp_in1;

always@(*)
begin
	if( select == 0 )
	begin
		temp_in0 = in0;
		temp_in1 = in1;
	end
	else if( select == 1 )
	begin
		temp_in0 = in2;
		temp_in1 = in3;
	end
	else if( select == 2 )
	begin
		temp_in0 = in4;
		temp_in1 = in5;
	end
	else
	begin
		temp_in0 = in6;
		temp_in1 = 8'h00;
	end
end

HEX hex3 ( temp_in1[7:4], out3 );
HEX hex2 ( temp_in1[3:0], out2 );

HEX hex1 ( temp_in0[7:4], out1 );
HEX hex0 ( temp_in0[3:0], out0 );

endmodule

module HEXs
(
in0, in1, in2, in3,
in4, in5, in6,
select,
out0, out1, out2, out3,
out4, out5, out6, out7
);
input 	[7:0] in0, in1, in2, in3, in4, in5, in6;
input		[1:0] select;
output 	[6:0] out0, out1, out2, out3;
output 	[6:0] out4, out5, out6, out7;

reg		[7:0] temp_in0, temp_in1, temp_in2, temp_in3;

always@(*)
begin
	if( select == 0 )
	begin
		temp_in0 = in0;
		temp_in1 = in1;
		temp_in2 = in2;
		temp_in3 = in3;
	end
	else
	begin
		temp_in0 = in4;
		temp_in1 = in5;
		temp_in2 = 8'h00;
		temp_in3 = in6;
	end
end

HEX hex0 ( temp_in0[7:4], out7 );
HEX hex1 ( temp_in0[3:0], out6 );
HEX hex2 ( temp_in1[7:4], out5 );
HEX hex3 ( temp_in1[3:0], out4 );
HEX hex4 ( temp_in2[7:4], out3 );
HEX hex5 ( temp_in2[3:0], out2 );
HEX hex6 ( temp_in3[7:4], out1 );
HEX hex7 ( temp_in3[3:0], out0 );

endmodule

module HEX (in, out);
input 	[3:0] in;
output 	[6:0] out;

reg [6:0] out;

always @(in)
begin
	case (in)
		0: out = 7'b1000000;
		1: out = 7'b1111001;
		2: out = 7'b0100100;
		3: out = 7'b0110000;
		4: out = 7'b0011001;
		5: out = 7'b0010010;
		6: out = 7'b0000010;
		7: out = 7'b1111000;
		8: out = 7'b0000000;
		9: out = 7'b0010000;
		10: out = 7'b0001000;
		11: out = 7'b0000011;
		12: out = 7'b1000110;
		13: out = 7'b0100001;
		14: out = 7'b0000110;
		15: out = 7'b0001110;
	endcase
end

endmodule
