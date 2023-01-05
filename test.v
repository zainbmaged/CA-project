`timescale 1ns/100ps // delay unit is 1ns with percesion step 100ps

module APB_tb;
  //declaring test bench variables
    reg PCLK, PRESETn, Transfer, Wr_Rd; 
    reg [31:0] Address; 
    reg [31:0] write_data; 
    wire [31:0] read_data; 
  
    
    initial begin
        PCLK = 0; //intializing clk
        forever begin
            #5 PCLK = ~PCLK; // toggle clk each 5ns
        end
    end
    
    integer i;
    
    initial begin
      Address = 32'b00000;//begin with adress0
      for(i=0; i<10;i=i+1)begin
        PRESETn  = 1;
        Transfer = 1;
        $display("current loop %d & current address %b ",i,Address);
        //Write Operation 1
        Address = Address;
        
        #10
        Wr_Rd      = 1;
        write_data = 32'hABCDABCD;
        #10
        
        //Write Operation 2
        Address = Address +32'b00001;//begin with adress1
        Wr_Rd      = 1;
        write_data = 32'hCAFECAFE;
        #30
        //write_data = 32'hx;
        #10
        Transfer     = 0;
        #15 Transfer = 1;

        //Read Operation 1
        Wr_Rd   = 0;
        Address = Address;
        
        //Read Operation 2
        #20
        Address = Address -32'b00001;
        #5 Transfer = 1;
        #20
        #5 Transfer = 0;
        Address = Address +32'b00001;//increment adress
        if(i == 9 )begin
         $display("lasttime value %h ",write_data);
         if(write_data==32'hCAFECAFE)
           $display("test sucess ");
         end
       end
         $stop; //system task terminate current simulation at the end
      end
       
      
    
      //instance of interfacing module
    apb_prptocol DUT (PCLK,PRESETn,Transfer,Wr_Rd,Address,write_data,read_data);
    
   /* initial begin
        $dumpfile("APB_wave.vcd");
        $dumpvars;
    end */
    
  
endmodule
