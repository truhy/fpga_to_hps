/*
	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
	
	Developer: Truong Hy
	Version  : 20240408
	
	Creates a block RAM register with inferred RAM synthesis attribute, which
	tells Quartus to implement it using M10K FPGA embedded RAM.
	
	References:
	https://www.intel.com/content/www/us/en/programmable/quartushelp/current/index.htm#hdl/vlog/vlog_file_dir_ram.htm
*/

module m10k_mem #(
	parameter M10K_MEM_DATA_WIDTH = 8,
	parameter M10K_MEM_ADDR_WIDTH = 19
)( 
	input                            wclk,
	input  [M10K_MEM_ADDR_WIDTH-1:0] raddr,
	input  [M10K_MEM_ADDR_WIDTH-1:0] waddr,
	output [M10K_MEM_DATA_WIDTH-1:0] rdata,
	input  [M10K_MEM_DATA_WIDTH-1:0] wdata,
	input                            we
);
	(* ramstyle = "no_rw_check, M10K" *) reg [M10K_MEM_DATA_WIDTH-1:0] mem[2**M10K_MEM_ADDR_WIDTH-1:0];
	
	always @ (posedge wclk) begin
		if(we) begin
			mem[waddr] <= wdata;
		end
	end
	
	assign rdata = mem[raddr];
endmodule
