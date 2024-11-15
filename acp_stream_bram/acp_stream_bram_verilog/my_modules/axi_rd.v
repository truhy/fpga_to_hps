/*
	MIT License

	Copyright (c) 2020 Truong Hy
	
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
	HDL      : Verilog
	Version  : 20230921
	
	Description:
		Helper module providing a simpler interface to read from an AXI-3 slave (ARM AMBA interconnect interface).
	
	User parameter ports:
		enable = 0 = idle, 1 = enable AXI transactions
		id = read transaction ID (this will set the Read Address ID and Read ID)
		addr = starting address to read from AXI
		data = the data read from AXI
		burst_len = number of data transfers (number of reads) per AXI transaction, and is a value between 0 to 15:
			burst_len = number of transfer(s)
			0 = 1
			1 = 2
			2 = 3
			...
			14 = 15
			15 = 16
		burst_size = size of each data transfer, encoded as 2^burst_size, and is a value between 0 to 7:
			burst_size = bytes per transfer
			0 = 1
			1 = 2
			2 = 4
			3 = 8
			4 = 16
			5 = 32
			6 = 64
			7 = 128
		status = 0 = ready, 1 = wait, 2 = completed ok, 3 = error
	
	AXI spec notes:
		aw_len = number of bursts (aka blocks) to transfer.  Formula: actual_length = aw_len + 1
		aw_size = size of a burst (aka block) transfer.  Formula: size_bytes = 2^aw_size
		The parameter AXI_WR_MAX_BURST_LEN is the maximum burst length allowed (number of burst
		transfers), set to a value within the range 1 to 16 (AXI-3).
		
	References:
		AXI specifications:
			https://www.arm.com/architecture/system-architectures/amba/amba-specifications
		Version B is AXI-3:
			https://developer.arm.com/documentation/ihi0022/b
*/
module axi_rd #(
	parameter AXI_RD_ID_WIDTH = 8,
	parameter AXI_RD_ADDR_WIDTH = 32,
	parameter AXI_RD_BUS_WIDTH = 32,
	parameter AXI_RD_MAX_BURST_LEN = 1
)(
	input clock,
	input reset_n,
	
	input enable,
	input [AXI_RD_ID_WIDTH-1:0] id,
	input [AXI_RD_ADDR_WIDTH-1:0] addr,
	output reg [AXI_RD_MAX_BURST_LEN*AXI_RD_BUS_WIDTH-1:0] data,
	input [3:0] burst_len,
	input [2:0] burst_size,
	input [1:0] burst_type,
	input [1:0] lock,
	input [3:0] cache,
	input [2:0] prot,
	input [4:0] user,
	output reg [1:0] status,  // 0 = ready, 1 = wait, 2 = completed ok, 3 = error
	
	// Connection to the AXI interface slave..
	// Address read channel registers
	output [AXI_RD_ID_WIDTH-1:0] ar_id,
	output [AXI_RD_ADDR_WIDTH-1:0] ar_addr,
	output [3:0] ar_len,
	output [2:0] ar_size,
	output [1:0] ar_burst,
	output [1:0] ar_lock,
	output [3:0] ar_cache,
	output [2:0] ar_prot,
	output [4:0] ar_user,
	output reg ar_valid,
	input ar_ready,
	// Read data channel registers
	input [AXI_RD_ID_WIDTH-1:0] r_id,
	input [AXI_RD_BUS_WIDTH-1:0] r_data,
	input r_last,
	input [1:0] r_resp,
	input r_valid,
	output reg r_ready
);
	`include "axi_def.vh"

	reg [3:0] burst_count;
	reg error;

	// Assign AXI master signals to slave signals
	assign ar_id = id;                         // Read transaction ID tag
	assign ar_addr = addr;                     // Starting read address
	assign ar_len = burst_len;                 // Number of transfers: burst_len = number_of_transfers - 1
	assign ar_size = burst_size;               // Transfer size: transfer_size = 2^burst_size (in bytes)
	assign ar_burst = burst_type;
	assign ar_lock = lock;
	assign ar_cache = cache;
	assign ar_prot = prot;
	assign ar_user = user;

	always @ (posedge clock or negedge reset_n) begin
		if(!reset_n) begin
			//data <= 'b0;  // { (AXI_RD_MAX_BURST_LEN*AXI_RD_BUS_WIDTH){1'b0} };
			ar_valid <= 0;
			r_ready <= 0;
			status <= 0;
		end
		else begin

			// ===============================
			// Address read transaction: start
			// ===============================

			if(enable && !status) begin
				//data <= 'b0;  // { (AXI_RD_MAX_BURST_LEN*AXI_RD_BUS_WIDTH){1'b0} };
				burst_count <= 0;
				error <= 0;
				status <= 1;
				ar_valid <= 1;  // Master asserts arvalid to indicate the address value is valid and can be transferred
			end

			// ========================================
			// Address read transaction: wait for ready
			// Read transaction: start
			// ========================================

			if(ar_valid && ar_ready) begin  // Wait for the slave to assert arready, which indicates it is ready to receive the address value
				ar_valid <= 0;
				r_ready <= 1;  // Master asserts rready to indicate it is ready (waiting) to receive the data value
			end

			// ===============================
			// Read transaction: transfer data
			// ===============================
		
			// No need to check r_id, leave that to an arbiter to handle
			//if(r_id == id && r_ready && r_valid) begin
			if(r_ready && r_valid) begin  // Wait for the slave to assert rvalid, which indicates data is valid and can be transferred
				// Store a burst transfer to a register at the correct index
				data[burst_count*AXI_RD_BUS_WIDTH +: AXI_RD_BUS_WIDTH] <= r_data;
				
				// Burst transfers completed? (i.e. no more data to read?) Note AXI-3 doesn't allow early burst termination
				if(r_last || burst_count >= ar_len) begin  // Check also burst_count incase AXI slaves don't implement r_last properly
					// Stop the read operation
					status <= (r_resp >= `AXI_RRESP_SLVERR || error) ? 3 : 2;  // Check for error. Set 3 = error, 2 = ok
					r_ready <= 0;
				end
				else begin
					// Continue to read the next data
					if(r_resp >= `AXI_RRESP_SLVERR) error <= 1;  // Check for error
				end

				burst_count <= burst_count + 1;
			end
		
			// ==================
			// When done, restart
			// ==================

			if(status >= 2) begin
				status <= 0;
			end
		end
	end
endmodule
