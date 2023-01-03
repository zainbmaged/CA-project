`include "uart.v"
`include "apbmaster.v"

module uart_apb_prptocol(input PCLK,
               input PRESETn,
               input Transfer,
               input  Read_Write,
               input [31:0] apb_write_paddr,
	       input [31:0] apb_write_data,
	       input [31:0] apb_read_paddr,
               output [31:0] read_dataout
               );
               
    wire [31:0] PADDR;
    wire [31:0] PWDATA,PRDATA;
    wire PSEL1,PENABLE,PREADY,PWRITE, PSlavErr;
    wire tx_full, rx_empty,tx,rx
    
    apbmaster Design_master (PCLK , PRESETn,PREADY,Transfer, Read_Write, PSEL1, PENABLE, PADDR,
     PWRITE, PWDATA , read_dataout, PRDATA,  apb_write_data,
     apb_write_paddr, apb_read_paddr ,PSlavErr);
     
     uart_slave  Design_slave(PCLK,PRESETn,~PWRITE,PWRITE,PSEL1,read_dataout, tx_full,rx_empty,PREADY,apb_write_data);
    
  // rd_uart=~pwrite, wr_uart=pwrite, rx =Psel1, tx=Pready 
   //r-data=apb_write_data
   //w-data=read_dataout
  


  //  input wire rd_uart, wr_uart, rx,
    //input wire [7:0] w_data,
    //output wire tx_full, rx_empty, tx,
    //output wire [7:0] r_data
endmodule

