`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/12/2015 11:20:45 AM
// Design Name: 
// Module Name: TOP_UART_ADC
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

module TOP_UART_ADC(
    input  clkp,
    input  clkn,
    input  vp,
    input  vn,
    inout  rx,
    inout  tx    
);

wire clk200; 
wire UART_we;
wire [`ADDR-1:0]        UART_addr;
wire [`UART_WIDTH-1:0]  UART_din;
wire [`UART_WIDTH-1:0]  UART_dout;
wire [`ADC_WIDTH-1:0]   dout1;  
wire [`UART_WIDTH-1:0]  command;

wire dwe, den;
wire busy, drdy, eoc, eos, jtaglocked;
wire [4:0] channel;
wire [6:0] daddr;
wire [16-1:0] dout, din;
wire rd, wr, valid;
wire [6:0] addr;
wire [`ADC_WIDTH+3:0] data_out, data_in;
 
reg ADC_we;
reg [`ADC_WIDTH-1:0] ADC_din;
reg [`ADDR-1:0] ADC_addr;
reg [`UART_WIDTH-1:0] status;
reg [1:0] state;
parameter   FIRST = 0,
            SECOND = 1,
            HOLD = 2;
            
assign rst = (command == `RESET) ? 1'b1 : 1'b0;
assign rd = (command == `STRT_ADC) ? 1'b1 : 1'b0;
 
initial begin
    state <= FIRST;     
    ADC_din <= 0;
    ADC_we <= 1'b0;
    ADC_addr <= 0;
    status <= 8'h00;
end

always@(posedge clk200 or posedge rst) begin
    if(rst)
        state <= FIRST;
    else begin
        case(state)
            FIRST: begin
                if(valid) begin
                    ADC_din <= data_out[11:4];
                    ADC_we <= 1'b1;
                    ADC_addr <= ADC_addr + 1;
                    state <= SECOND;
                    status <= `ADC_CONV;
                end
                if(ADC_addr == 4*`SAMPLES-1) 
                    state <= HOLD;
            end
            SECOND: begin
                ADC_din <= {4'h99, data_out[15:12]};
                ADC_addr <= ADC_addr + 1;
                state <= FIRST;
            end
            HOLD: begin
                 ADC_we <= 1'b0;
                 ADC_din <= 0;
                 ADC_addr <= 0;
                 status <= `ADC_RD;
            end
        endcase
    end
end

//---------------------------------------------------------------------------
IBUFGDS #(
	 .DIFF_TERM  	("FALSE"),    // Differential Termination
	 .IBUF_LOW_PWR  ("TRUE"),  // Low power="TRUE", Highest performance="FALSE"
	 .IOSTANDARD    ("DEFAULT")  // Specify the input I/O standard
	 ) 
buf200 (
	 .O 			(clk200),  
	 .I 			(clkp),  
	 .IB			(clkn) 
);

//---------------------------------------------------------
fsm_ADC fsm_adcUUT 
(
// User Interface
	.clk			(clk200),
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
	.dclk_in		(clk200),
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
//---------------------------------------------------------------------------
dpram MEM (
	.clka     	(clk200),    	
	.wea      	(ADC_we),
	.addra    	(ADC_addr),
	.dina     	(ADC_din),  
	.douta    	(),  

	.clkb     	(clk200),  
	.web      	(UART_we),  
	.addrb    	(UART_addr),  
	.dinb     	({0,UART_din}),    
	.doutb    	(dout1)
);
defparam MEM.DATA	= `ADC_WIDTH;
defparam MEM.ADDR	= `ADDR;

//---------------------------------------------------------------------------
assign UART_dout = dout1[`UART_WIDTH-1:0];

 top_UART UART (
   .rst            (rst),
   .clk            (clk200),
   .rx             (rx),
   .tx             (tx),    
   .command        (command),
   .ram_we         (UART_we),
   .ram_din        (UART_din),
   .ram_dout       (UART_dout),
   .ram_addr       (UART_addr),
   .status         (status)
);

endmodule
