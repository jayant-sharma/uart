`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:01:29 06/16/2014 
// Design Name: 
// Module Name:    TOP_UART_SMA 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 	 This module instantiates aurora, RAM, uart, packet_gen and SMA IN & OUT FSMs
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////
`include "commands.vh"

module top_UART (					
	input  clk,
	input  rst,
    input  [`UART_WIDTH-1:0] status, 
    input  [`UART_WIDTH-1:0] ram_dout,
    input  rx,
    output tx, 
    output ram_we,
    output [`UART_WIDTH-1:0] ram_din, 
    output [`ADDR-1:0] ram_addr,	
    output [`UART_WIDTH-1:0] command    				
);

wire transmit,received,is_receiving,is_transmitting,recv_error;
wire [`UART_WIDTH-1:0]  rx_byte;
wire [`UART_WIDTH-1:0]  tx_byte;
	 
packet_gen pkt_gen (
	//	INPUTS
	 .Clk					(clk), 
	 .Rst					(rst), 
	 .RX_byte				(rx_byte), 
	 .REceived				(received), 
	 .IS_receiving			(is_receiving), 
	 .IS_transmitting		(is_transmitting), 
	 .REcv_error			(recv_error), 
	 .Ram_dout				(ram_dout), 
	 .Status				(status), 
	//	OUTPUTS
	 .TX_byte				(tx_byte), 
	 .Transmit				(transmit), 
	 .Ram_addr				(ram_addr), 
	 .Ram_we				(ram_we), 
	 .Ram_din				(ram_din), 
	 .Command				(command), 
	 .Module_status		    ()
	 );		 
	 defparam pkt_gen.DATAP 	= `UART_WIDTH;
	 defparam pkt_gen.ADDRP 	= `ADDR;	
	 defparam pkt_gen.EXPIRE_AFTER = 31'h6000;
	 
uart uartUUT (
	 .clk					(clk), 
	 .rst					(0), 
	 .rx					(rx), 
	 .tx					(tx), 
	 .transmit				(transmit), 
	 .tx_byte				(tx_byte), 
	 .received				(received), 
	 .rx_byte				(rx_byte), 
	 .is_receiving			(is_receiving), 
	 .is_transmitting		(is_transmitting), 
	 .recv_error			(recv_error)
	 );
	 
endmodule
