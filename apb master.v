
`timescale 1ns/1ns
	 

module apbmaster(
input 		pclk,preset,pready,transfer,
input 		Read_write,//0-read,1-write
output   	psel,
output reg	penable,
output reg [32:0] paddr,
output reg	pwrite,
output reg [31:0]   pwdata,
output reg [31:0]  readOut,
input [31:0]    prdata,write_data,
input [32:0]    write_addr,read_addr,
output          PSlavErr // for errors
);


reg invalid_setup_error,setup_error,invalid_read_paddr,invalid_write_paddr,invalid_write_data; 
reg [1:0] cur_s,nex_s;
parameter idle = 2'b00,setup = 2'b01,access = 2'b10;

  
always @(posedge pclk)
begin
	if(~preset)
		cur_s <= idle;
	else
		cur_s <= nex_s;
end 
	
	
always @(cur_s or transfer or pready)
begin
	if(!preset)
	  nex_s = idle;
	else
      begin
           pwrite = ~Read_write;
	
	case(cur_s)
	idle: begin
		penable=0;
		if(!transfer) 
			nex_s = idle;
		else
			nex_s = setup;
	       end 
	
	setup:begin
		penable=0;		
		 if(Read_write) 
			
	                       begin   paddr = read_addr; end
			    else 
			      begin   
			        
                                  paddr = write_addr;
				  pwdata = write_data;  end
			    
			    if(transfer && !PSlavErr)
			      nex_s = access;
		            else
           	              nex_s = idle;
		  end
		
	access:begin 
	         if(psel)  penable = 1;
		 if(transfer &!PSlavErr)
		      begin
			if(pready)
			  begin 
			        if(!Read_write)
				begin
				nex_s = setup; end
			
				else  begin
				nex_s = setup;
			        readOut =prdata;	
			              end
		                end
			        else 
				  nex_s = access;
			    end 
				else
					nex_s = idle;
		end
	
		
	default: nex_s = idle;
               	endcase
         end
        end
	
		assign psel = ((cur_s != idle) ? (paddr[32] ? 1'b0 : 1'b1) : 1'd0);

  //for errors
  
  always @(*)
       begin
        if(!preset)
	    begin 
	     setup_error =0;
	     invalid_read_paddr = 0;
	     invalid_write_paddr = 0;
	     invalid_write_paddr =0 ;
	    end 
        else
	 begin	
          begin
	if(cur_s == idle && nex_s == access)
   	  setup_error = 1;
	  else setup_error = 0;
          end
          begin
          if((write_data===8'dx) && (!Read_write) && (cur_s==setup || cur_s==access))
		  invalid_write_data =1;
	  else invalid_write_data = 0;
          end
          begin
	 if((write_addr===33'dx) && Read_write && (cur_s==setup || cur_s==access))
		  invalid_read_paddr = 1;
	  else  invalid_read_paddr = 0;
          end
          begin
         if((write_addr===33'dx) && (!Read_write) && (cur_s==setup || cur_s==access))
		  invalid_write_paddr =1;
          else invalid_write_paddr =0;
          end
          begin
		  if(cur_s == setup)
            begin
		    if(pwrite)
                     begin
			      if(paddr==write_addr && pwdata==write_data)
                              setup_error=1'b0;
                         else
                               setup_error=1'b1;
                       end
                 else 
                       begin
			       if (paddr==read_addr)
                                 setup_error=1'b0;
                          else
                                 setup_error=1'b1;
                       end    
              end 
          
         else setup_error=1'b0;
         end 
       end
       invalid_setup_error = setup_error ||  invalid_read_paddr || invalid_write_data || invalid_write_paddr  ;
    end 

   assign PSlavErr =  invalid_setup_error ;

	

 endmodule
