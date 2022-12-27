module gpio_apb(
         input PCLK,PRESETn,// system clock and reset signal
         input PSEL,PENABLE,PWRITE,//control signals input to apb
         input [31:0]PADDR,PWDATA,//adress and data to write input from apb to gpio
        output [31:0]PRDATA1,// output data read from memory to apb
        output reg PREADY );
    
     reg [31:0]reg_address; //register to save address
     reg [31:0] mem [0:279]; 

    assign PRDATA1 =  mem[reg_address];

    always @(*)//always combinational
       begin
         if(!PRESETn)//rest
              PREADY = 0;
          else
	  if(PSEL && !PENABLE && !PWRITE)
	     begin PREADY = 0; end
	         
	  else if(PSEL && PENABLE && !PWRITE)
	     begin  PREADY = 1;
                    reg_address =  PADDR; //read adress
	       end
          else if(PSEL && !PENABLE && PWRITE)
	     begin  PREADY = 0; end

	  else if(PSEL && PENABLE && PWRITE)//write to memory 
	     begin  PREADY = 1;
	            mem[PADDR] = PWDATA; end 

           else PREADY = 0;
        end
    endmodule
        
