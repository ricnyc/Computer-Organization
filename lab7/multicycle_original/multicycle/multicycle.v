// ---------------------------------------------------------------------
// Copyright (c) 2007 by University of Toronto ECE 243 development team 
// ---------------------------------------------------------------------
//
// Major Functions:	a simple processor which operates basic mathematical
//					operations as follow:
//					(1)loading, (2)storing, (3)adding, (4)subtracting,
//					(5)shifting, (6)oring, (7)branch if zero,
//					(8)branch if not zero, (9)branch if positive zero
//					 
// Input(s):		1. KEY0(reset): clear all values from registers,
//									reset flags condition, and reset
//									control FSM
//					2. KEY1(clock): manual clock controls FSM and all
//									synchronous components at every
//									positive clock edge
//
//
// Output(s):		1. HEX Display: if switches 16 and 17 are both zero, 
//									registers value K3 to K0 displayed
//									in hexadecimal format, else the PC, IR
//									and the last data read from memory
//									are displayed in hexadecimal format
//
//					** For more details, please refer to the document
//					   provided with this implementation
//
// ---------------------------------------------------------------------

module multicycle
(
SW, KEY, HEX0, HEX1, HEX2, HEX3,
HEX4, HEX5, HEX6, HEX7, LEDG, LEDR
);

// ------------------------ PORT declaration ------------------------ //
input	[3:0] KEY;
input	[17:0] SW;
output	[6:0] HEX0, HEX1, HEX2, HEX3;
output	[6:0] HEX4, HEX5, HEX6, HEX7;
output	[7:0] LEDG;
output	[17:0] LEDR;

// ------------------------- Registers/Wires ------------------------ //
wire	clock, reset;
wire	IRLoad, MDRLoad, MemRead, MemWrite, PCWrite, RegIn, AddrSel;
wire	ALU1, ALUOutWrite, FlagWrite, R1R2Load, R1Sel, RFWrite;
wire	[7:0] R2wire, PCwire, R1wire, RFout1wire, RFout2wire;
wire	[7:0] ALU1wire, ALU2wire, ALUwire, ALUOut, MDRwire, MEMwire;
wire	[7:0] IR, SE4wire, ZE5wire, ZE3wire, AddrWire, RegWire;
wire	[7:0] reg0, reg1, reg2, reg3;
wire	[7:0] constant;
wire	[2:0] ALUOp, ALU2;
wire	[1:0] R1_in;
wire	Nwire, Zwire;
reg		N, Z;

// ------------------------ Input Assignment ------------------------ //
assign	clock = KEY[1];
assign	reset =  ~KEY[0]; // KEY is active high


// ------------------- DE2 compatible HEX display ------------------- //
HEXs	HEX_display(
	.in0(|SW[17:16] ? PCwire : reg0),.in1(|SW[17:16] ? IR : reg1),.in2(|SW[17:16] ? 0 : reg2),.in3(|SW[17:16] ? MEMwire : reg3),
	.out0(HEX0),.out1(HEX1),.out2(HEX2),.out3(HEX3),
	.out4(HEX4),.out5(HEX5),.out6(HEX6),.out7(HEX7)
);
// ----------------- END DE2 compatible HEX display ----------------- //

/*
// ------------------- DE1 compatible HEX display ------------------- //
chooseHEXs	HEX_display(
	.in0(reg0),.in1(reg1),.in2(reg2),.in3(reg3),
	.out0(HEX0),.out1(HEX1),.select(SW[1:0])
);
// turn other HEX display off
assign HEX2 = 7'b1111111;
assign HEX3 = 7'b1111111;
assign HEX4 = 7'b1111111;
assign HEX5 = 7'b1111111;
assign HEX6 = 7'b1111111;
assign HEX7 = 7'b1111111;
// ----------------- END DE1 compatible HEX display ----------------- //
*/

FSM		Control(
	.reset(reset),.clock(clock),.N(N),.Z(Z),.instr(IR[3:0]),
	.PCwrite(PCWrite),.AddrSel(AddrSel),.MemRead(MemRead),.MemWrite(MemWrite),
	.IRload(IRLoad),.R1Sel(R1Sel),.MDRload(MDRLoad),.R1R2Load(R1R2Load),
	.ALU1(ALU1),.ALUOutWrite(ALUOutWrite),.RFWrite(RFWrite),.RegIn(RegIn),
	.FlagWrite(FlagWrite),.ALU2(ALU2),.ALUop(ALUOp)
);

memory	DataMem(
	.MemRead(MemRead),.wren(MemWrite),.clock(clock),
	.address(AddrWire),.data(R1wire),.q(MEMwire)
);

ALU		ALU(
	.in1(ALU1wire),.in2(ALU2wire),.out(ALUwire),
	.ALUOp(ALUOp),.N(Nwire),.Z(Zwire)
);

RF		RF_block(
	.clock(clock),.reset(reset),.RFWrite(RFWrite),
	.dataw(RegWire),.reg1(R1_in),.reg2(IR[5:4]),
	.regw(R1_in),.data1(RFout1wire),.data2(RFout2wire),
	.r0(reg0),.r1(reg1),.r2(reg2),.r3(reg3)
);

registers	IR_reg(
	.clock(clock),.aclr(reset),.enable(IRLoad),
	.data(MEMwire),.q(IR)
);

registers	MDR_reg(
	.clock(clock),.aclr(reset),.enable(MDRLoad),
	.data(MEMwire),.q(MDRwire)
);

registers	PC(
	.clock(clock),.aclr(reset),.enable(PCWrite),
	.data(ALUwire),.q(PCwire)
);

registers	R1(
	.clock(clock),.aclr(reset),.enable(R1R2Load),
	.data(RFout1wire),.q(R1wire)
);

registers	R2(
	.clock(clock),.aclr(reset),.enable(R1R2Load),
	.data(RFout2wire),.q(R2wire)
);

registers	ALUOut_reg(
	.clock(clock),.aclr(reset),.enable(ALUOutWrite),
	.data(ALUwire),.q(ALUOut)
);

mux2o1s		R1Sel_mux(
	.data0x(IR[7:6]),.data1x(constant[1:0]),
	.sel(R1Sel),.result(R1_in)
);

mux2to1		AddrSel_mux(
	.data0x(R2wire),.data1x(PCwire),
	.sel(AddrSel),.result(AddrWire)
);

mux2to1		RegMux(
	.data0x(ALUOut),.data1x(MDRwire),
	.sel(RegIn),.result(RegWire)
);

mux2to1		ALU1_mux(
	.data0x(PCwire),.data1x(R1wire),
	.sel(ALU1),.result(ALU1wire)
);

mux5to1		ALU2_mux(
	.data0x(R2wire),.data1x(constant),.data2x(SE4wire),
	.data3x(ZE5wire),.data4x(ZE3wire),.sel(ALU2),.result(ALU2wire)
);

sExtend		SE4(.in(IR[7:4]),.out(SE4wire));
zExtend		ZE3(.in(IR[5:3]),.out(ZE3wire));
zExtend		ZE5(.in(IR[7:3]),.out(ZE5wire));
// define parameter for the data size to be extended
defparam	SE4.n = 4;
defparam	ZE3.n = 3;
defparam	ZE5.n = 5;

always@(posedge clock or posedge reset)
begin
if (reset)
	begin
	N <= 0;
	Z <= 0;
	end
else
if (FlagWrite)
	begin
	N <= Nwire;
	Z <= Zwire;
	end
end

// ------------------------ Assign Constant 1 ----------------------- //
assign	constant = 1;

// ------------------------- LEDs Indicator ------------------------- //
assign	LEDR[17] = PCWrite;
assign	LEDR[16] = AddrSel;
assign	LEDR[15] = MemRead;
assign	LEDR[14] = MemWrite;
assign	LEDR[13] = IRLoad;
assign	LEDR[12] = R1Sel;
assign	LEDR[11] = MDRLoad;
assign	LEDR[10] = R1R2Load;
assign	LEDR[9] = ALU1;
assign	LEDR[2] = ALUOutWrite;
assign	LEDR[1] = RFWrite;
assign	LEDR[0] = RegIn;
assign	LEDR[8:6] = ALU2[2:0];
assign	LEDR[5:3] = ALUOp[2:0];
assign	LEDG[6:2] = constant[7:3];
assign	LEDG[7] = FlagWrite;
assign	LEDG[1] = N;
assign	LEDG[0] = Z;

endmodule
