module apbmaster(
input 		pclk,preset,pready,
input 	[1:0]	Read_write,//01-read,11-write
output reg	psel,
output reg	penable,
output 	  [31:0]paddr,
output 		pwrite,
output 		[31:0]pwdata,
input  		[31:0]prdata
    );
    

reg [31:0]cur_pwrite,nex_pwrite,cur_prdata,nex_prdata;
reg [1:0] cur_s,nex_s;
parameter idle = 2'b00,setup = 2'b01,access = 2'b10;

always @(posedge pclk)
begin
	if(~preset)
	begin
		cur_s <= idle;
		cur_pwrite <= 32'b0;
		cur_prdata <= 32'b0;
		end
	else
	begin
		cur_s <= nex_s;
		cur_pwrite <= nex_pwrite;
		cur_prdata <= nex_prdata;
	end
end 

always @(cur_s or Read_write)
begin
	case(cur_s)
	idle:begin
			if(Read_write[0])
			begin
			nex_s = setup;
			nex_pwrite = Read_write[1];
			end
			else
			nex_s = idle;
			end
	setup:begin
				psel = 1;
				penable = 0;
				nex_s = access;
			end
	access:begin
				psel = 1;
				penable = 1;
				if(pready)
				begin
				if(~cur_pwrite)
				begin
				nex_prdata = prdata;
				nex_s = idle;
				end
				end
				else
				nex_s = access;
			end
	default:begin
	psel = 0;
	penable = 0;
	nex_s = idle;
	nex_prdata = cur_prdata;
	nex_pwrite = cur_pwrite;
	end
	endcase
end

assign paddr = (cur_s == access)?32'h32:32'h0000;
assign pwrite = cur_pwrite;
assign pwdata = (cur_s == access)?cur_prdata:32'b0;


endmodule
    

