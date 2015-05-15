`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    20:25:17 06/03/2014 
// Design Name: 
// Module Name:    packet_gen 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
//(* tristate2logic = "no" *)

`include "commands.vh"
module packet_gen#(
	parameter DATAP = 8,
	parameter ADDRP = 16,
	parameter EXPIRE_AFTER = 31'h6000
)
(	
	input  Clk,
	input  Rst,
	input  [DATAP-1:0] RX_byte,
	input  REceived,
	input  IS_receiving,
	input  IS_transmitting,
	input  REcv_error,
	input  [DATAP-1:0] Ram_dout,
	input  [7:0] Status,

	output reg [DATAP-1:0] TX_byte,
	output wire Transmit,
	output wire [ADDRP-1:0] Ram_addr,
	output reg Ram_we,
	output reg [DATAP-1:0] Ram_din,
	output reg [DATAP-1:0] Command,
	output [31:0] Module_status
);

			
/*********************************************************************************
			packet generator(pg) States
*********************************************************************************/
	parameter [7:0]
	IDLE 		    = 8'h01,
	CHK_HEAD 	 = 8'h02,
	WR_COMMAND 	 = 8'h03,
	SND_PKT  	 = 8'h04,
	SND_HEAD  	 = 8'h05,
	TRANS 	 	 = 8'h06,
	CALC_LnA 	 = 8'h07,
	WR_MEMORY 	 = 8'h08,
	RD_MEMORY	 = 8'h09,
	SNT_LnA		 = 8'h0a,
	DEFAULT 		 = 8'hf0;
	
//********************************************************************************			
	reg  [7:0] module_status1;
	reg  [7:0]  pg_state;
	reg  [7:0]  head;
	reg  [15:0] pkt_len;
	reg  [15:0] pkt_addr;
	reg  [7:0]  len1;
	reg  [7:0]  addr1;
	reg  [ADDRP-1:0]  addr2;
	reg  [1:0]  lna_count;
	reg  [ADDRP-1:0] data_count;
	reg  [31:0] waTCHDOG;
	reg  [ADDRP-1:0] Ram_addr_i;	
	reg  Transmit1;
//********************************************************************************			
	initial begin
		Ram_we 		<= 1'b0;
		Ram_addr_i 	<= 15'h0000;
		Transmit1 	<= 1'b0;
		TX_byte 		<= 8'h00;
		head			<= 8'h00;
		lna_count	<= 2'b00;
		pg_state 	<= IDLE;
		waTCHDOG    <= 0;
		module_status1 <= 0;
	end
	assign Transmit = Transmit1 & !IS_transmitting;
	assign Module_status = {pkt_len,head,module_status1};
	assign Ram_addr = Ram_we ? (Ram_addr_i - 1) : Ram_addr_i;	
	
//*******************************--FSM--******************************************			
	always@(posedge Clk or posedge Rst)
	begin : PKT_FSM
		if(Rst)	begin 
			pg_state <= IDLE;
		end
		else	begin
/*			waTCHDOG <= waTCHDOG - 1;
			if (waTCHDOG == 0) begin
				pg_state <= IDLE;
			end
*/		
			case (pg_state)
				IDLE: begin	
					module_status1 <= IDLE;					
					Ram_we <= 1'b0;
					Ram_addr_i <= 16'h0000;					
					if (!IS_transmitting) begin
						if (!Transmit1)
							TX_byte <= 8'h00;
					end
					else begin
						Transmit1 <= 1'b0;
					end
					head <= 8'h00;
					if(REceived && (RX_byte == `PKT_START))	begin
						waTCHDOG <= EXPIRE_AFTER;
						pg_state <= CHK_HEAD;
					end
				end
					
				CHK_HEAD: begin	
					module_status1 <= CHK_HEAD;
					if(REceived) begin
						head <= RX_byte;
						case (RX_byte)
							`WR_CMND:	begin
								pg_state <= WR_COMMAND;
								waTCHDOG <= EXPIRE_AFTER;
							end
							`RD_STAT: begin
								pg_state <= SND_PKT;	
								waTCHDOG <= EXPIRE_AFTER;
							end
							
							`WR_MEM: begin
								lna_count <= 2'b00;
								waTCHDOG <= EXPIRE_AFTER;
								pg_state <= CALC_LnA; 	
							end
							`RD_MEM: begin
								lna_count <= 2'b00;
								waTCHDOG <= EXPIRE_AFTER;
								pg_state <= CALC_LnA; 	
							end
							default:	pg_state <= IDLE;
						endcase
					end
				end

				WR_COMMAND: begin
					module_status1 <= WR_COMMAND;
					if(REceived) begin
						Command <= RX_byte;
						waTCHDOG <= EXPIRE_AFTER;
						pg_state <= SND_PKT; 
					end
				end

				SND_PKT: begin
					module_status1 <= SND_PKT;
					if (!IS_transmitting)
					begin		
						if (Transmit1 == 1'b0) begin
							Transmit1 <= 1'b1;	
							TX_byte <= `PKT_START;
							waTCHDOG <= EXPIRE_AFTER;
							pg_state <= SND_HEAD;
						end
					end
					else begin
						Transmit1 <= 1'b0;
					end
				end
				
				SND_HEAD: begin
					module_status1 <= SND_HEAD;
					if (!IS_transmitting)
					begin
						if (Transmit1 == 1'b0 ) begin
							Transmit1 <= 1'b1;	
							TX_byte <= head;
							waTCHDOG <= EXPIRE_AFTER;
							pg_state <= TRANS;
						end
					end
					else begin
						Transmit1 <= 1'b0;
					end
				end
				
				TRANS: begin		
					module_status1 <= TRANS;
					if (!IS_transmitting)
					begin		
						case (head)
							`RD_STAT: begin
								if (Transmit1 == 1'b0) begin
									TX_byte <= Status;
									Transmit1 <= 1'b1;
									waTCHDOG <= EXPIRE_AFTER;
									pg_state <= IDLE;
								end
							end
							`WR_CMND: begin		
								if (Transmit1 == 1'b0) begin						
									TX_byte <= Command;
									Transmit1 <= 1'b1;
									waTCHDOG <= EXPIRE_AFTER;
									pg_state <= IDLE;
								end
							end
							`RD_MEM: begin								
								pg_state <= SNT_LnA;
								lna_count <= 2'b00;
								waTCHDOG <= EXPIRE_AFTER;
								Transmit1 <= 1'b0;
							end
							`WR_MEM: begin								
								pg_state <= SNT_LnA;
								lna_count <= 2'b00;
								waTCHDOG <= EXPIRE_AFTER;
								Transmit1 <= 1'b0;
							end
							default: pg_state <= IDLE;
						endcase
					end
					else begin
						Transmit1 <= 1'b0;
					end
				end

				CALC_LnA: begin
					module_status1 <= CALC_LnA;
					if(REceived) begin					
						waTCHDOG <= EXPIRE_AFTER;
						case (lna_count)
							2'b00: begin
								len1 <= RX_byte;
								lna_count <= 2'b01;
							end
							2'b01: begin
								pkt_len <= {len1,RX_byte};
								lna_count <= 2'b10;
							end
							2'b10: begin
								addr1 <= RX_byte;
								data_count <= pkt_len + 1;
								lna_count <= 2'b11;
							end
							2'b11: begin
								Ram_addr_i <= {addr1,RX_byte};
								addr2 <= {addr1,RX_byte};
								case (head)
									`RD_MEM: pg_state <= SND_PKT;
									`WR_MEM: pg_state <= WR_MEMORY;
									default: pg_state <= IDLE;
								endcase
							end
						endcase
					end
				end

				SNT_LnA: begin
					module_status1 <= SNT_LnA;
					if (!IS_transmitting)
					begin				
						if (!Transmit1) begin
							waTCHDOG <= EXPIRE_AFTER;
							Transmit1 <= 1'b1;				
							case (lna_count)
								2'b00: begin
									TX_byte <= pkt_len[15:8];
									lna_count <= 2'b01;
								end
								2'b01: begin
									TX_byte <= pkt_len[7:0];
									lna_count <= 2'b10;
								end
								2'b10: begin
									TX_byte <= addr2[15:8];
									lna_count <= 2'b11;
								end
								2'b11: begin
									TX_byte <= addr2[7:0];
									if(head == `RD_MEM)			begin
										data_count <= pkt_len  + 1;			
										pg_state <= RD_MEMORY;	end
									else
										pg_state <= IDLE;
								end
							endcase
						end
					end
					else begin
						Transmit1 <= 1'b0;
					end
				end
				
				RD_MEMORY: begin
					module_status1 <= RD_MEMORY;
					if (!IS_transmitting)
					begin				
						if (!Transmit1) begin	
							waTCHDOG <= EXPIRE_AFTER;				
							if(data_count != 0) begin	
								Transmit1 <= 1'b1;				
								Ram_we <= 1'b0;	
								TX_byte <= Ram_dout;
								Ram_addr_i <= Ram_addr_i + 1'b1;
								data_count <= data_count - 1'b1;	
							end
							else if(data_count == 0) begin						
								Ram_we <= 1'b0;						
								Ram_addr_i <= 16'h0000;
								TX_byte <= 8'h00;
								Transmit1 <= 1'b0;
								pg_state <= IDLE;	
							end
						end
					end
					else begin
						Transmit1 <= 1'b0;
					end
				end

				WR_MEMORY: begin
					module_status1 <= WR_MEMORY;
					if(data_count != 0) begin
						if(REceived) begin
							waTCHDOG <= EXPIRE_AFTER;
							Ram_din <= RX_byte;
							Ram_we <= 1'b1;
							Ram_addr_i <= Ram_addr_i + 1'b1;
							data_count <= data_count - 1'b1;
						end
						else begin
							Ram_we <= 1'b0;
						end
					end
					else if(data_count == 0) begin
						Ram_we <= 1'b0;
						Ram_din <= 8'h00;
						pg_state <= SND_PKT;
					end
				end
				
				default: begin
					pg_state <= IDLE;
					module_status1 <= DEFAULT;
				end
						
			endcase	
		end
	end	
		
//********************************************************************************
endmodule 