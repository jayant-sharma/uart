//Packet Headers
`define PKT_START		8'h70		//p
`define WR_CMND		    8'h63		//c
`define RD_STAT		    8'h73		//s
`define WR_MEM			8'h77		//w
`define RD_MEM			8'h72		//r
//packet
//PKT START //HEAD //LEN(2) //ADDRESS(2)// DATA(LEN)

//Commands
`define RESET			8'h52		//R
`define STRT_ADC 		8'h53		//S	

//Status
`define ADC_RD		    8'h41		//A
`define ADC_CONV		8'h42       //B

//parameters
`define SAMPLES         16
`define ADC_WIDTH       16
`define UART_WIDTH      8
`define ADDR            16 //`CLOG2(`SAMPLES*2)
 
`define CLOG2(x)      \
    (x <= 2)    ? 1  : \
    (x <= 4)    ? 2  : \
    (x <= 8)    ? 3  : \
    (x <= 16)   ? 4  : \
    (x <= 32)   ? 5  : \
    (x <= 64)   ? 6  : \
    (x <= 128)  ? 7  : \
    (x <= 256)  ? 8  : \
    (x <= 512)  ? 9  : \
    (x <= 1024) ? 10 : \
    -1
 
  

