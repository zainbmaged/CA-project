`include "gpio.v"
`include "apbmaster.v"

module apb_prptocol(input PCLK,
               input PRESETn,
               input Transfer,
               input  Read_Write,
               input [31:0] apb_write_paddr,
	       input [31:0] apb_write_data,
	       input [31:0] apb_read_paddr,
               output [31:0] read_dataout);
               
    wire [31:0] PADDR;
    wire [31:0] PWDATA,PRDATA;
    wire PSEL1,PENABLE,PWRITE,PREADY, PSlavErr;
    
    apbmaster Design_master (PCLK , PRESETn,PREADY,Transfer, Read_Write, PSELx, PENABLE, PADDR,
     PWRITE, PWDATA , read_dataout, PRDATA,  apb_write_data,
     apb_write_paddr, apb_read_paddr ,PSlavErr);
     
     gpio_slave  Design_slave(PCLK,PRESETn, PADDR, PSEL1,PENABLE,PWRITE,
    PWDATA, PREADY ,PRDATA , PSlavErr);
    
endmodule

