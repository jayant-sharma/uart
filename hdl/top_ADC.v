`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/09/2014 02:39:41 PM
// Design Name: 
// Module Name: top_ADC
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "commands.vh"   

module top_ADC (
	input rst,
	input clk,
    input  vp,
    input  vn,	
    input [`UART_WIDTH-1:0] command,
	output reg ram_we,
    output reg [`ADC_WIDTH-1:0] ram_din,
    output reg [`ADDR-1:0] ram_addr,
    output reg [`UART_WIDTH-1:0] status
);

wire dwe, den;
wire busy, drdy, eoc, eos, jtaglocked;
wire [4:0] channel;
wire [6:0] daddr;
wire [16-1:0] dout, din;

wire rd, wr, valid;
wire [6:0] addr;
wire [`ADC_WIDTH+3:0] data_out, data_in;

assign rd = (command == `STRT_ADC) ? 1'b1 : 1'b0;
 
initial begin
    ram_din <= 0;
    ram_we <= 1'b0;
    ram_addr <= 0;
    status <= 8'h00;
end

always@(posedge clk) begin
    if(valid) begin
        ram_din <= data_out[`ADC_WIDTH+3:4];
        ram_we <= 1'b1;
        ram_addr <= ram_addr + 1;
        if(ram_addr == 2*`SAMPLES-1) begin
             ram_we <= 1'b0;
             ram_din <= 0;
             ram_addr <= 0;
             status <= `ADC_RD;
        end
    end
end

//---------------------------------------------------------
fsm_ADC fsm_adcUUT 
(
// User Interface
	.clk			(clk),
	.rst			(rst),
	.rd				(rd),
	.wr				(wr),
	.addr			(addr),
	.data_in		(data_in),
	.data_out		(data_out),
	.valid			(valid),
// XADC ports
    .jtaglocked     (),
	.busy			(busy),
	.drdy			(drdy),
	.eoc			(eoc),
	.eos			(eos),
	.channel		(channel),
	.dout			(dout),
	.dwe			(dwe),
	.den			(den),
	.daddr			(daddr),
	.din			(din)
);

//---------------------------------------------------------
xadc_temp ADC_12bit 
(
	.daddr_in		({2'b00,channel}),
	.dclk_in		(clk),
	.den_in			(den),
	.di_in			(din),
	.dwe_in			(dwe),
	.reset_in		(rst),
	.busy_out		(busy),
	.channel_out	(channel),
	.do_out			(dout),
	.drdy_out		(drdy),
	.eoc_out		(eoc),
	.eos_out		(eos),
//	.ot_out			(),
	.alarm_out		(),
	.vp_in			(vp),
	.vn_in			(vn)
);

endmodule