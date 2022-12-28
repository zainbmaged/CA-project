//`include " uart .v"
`include "gpio.v"
`include "apbmaster.v"

module apb_prptocol(input PCLK,
               input PRESETn,
               input Transfer,
               input [1:0] Wr_Rd,
               input [31:0] apb_write_paddr,
		           input [31:0] apb_write_data,
		           input [31:0] apb_read_paddr,
              output [31:0] read_data);
               
  
    wire [32:0] PADDR;
    wire [31:0] PWDATA,PRDATA;
    wire PSELx,PENABLE,PWRITE,PREADY;
	
    apbmaster Design_master (Transfer,Wr_Rd [1:0],Address,write_data,read_data,PCLK,
    PRESETn,PREADY,PRDATA,PSLVERR,PADDR,PSELx,PENABLE,PWRITE,PWDATA);
    gpio_slave Design_slave(PCLK,PRESETn,PADDR,PSELx,PENABLE,PWRITE,PWDATA,PREADY,PRDATA);
endmodule

