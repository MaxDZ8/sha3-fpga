`timescale 1 ns / 1 ps

	module sha3scanner_v0_1_S00_AXI #
	(
		// Users to add parameters here
		parameter STYLE = "fully-unrolled-fully-parallel",
		parameter FEEDBACK_MUX_STYLE = "fabric",
		parameter PROPER_SHA3 = 1,
		// User parameters ends
		// Do not modify the parameters beyond this line

		// Width of S_AXI data bus
		parameter integer C_S_AXI_DATA_WIDTH	= 32,
		// Width of S_AXI address bus
		parameter integer C_S_AXI_ADDR_WIDTH	= 9
	)
	(
		// Users to add ports here
		
    // While we produce results we might be multi-cycle and waiting for them to pour out.
    // In that case, we would evaluate only once every few cycles.
    // When we are not dispatching and not waiting for any result we are idle.
    // Idle also means "ready to start a new scan".
    output wire idle,
		// True if we are actively scanning. 
    output wire dispatching,
    // Pulses high 1 clock when a result is being evaluated for difficulty = we got a result
    output wire evaluating,
    // True if at least one resulting hash is good enough.
    output wire found,

		// User ports ends
		// Do not modify the ports beyond this line

		// Global Clock Signal
		input wire  S_AXI_ACLK,
		// Global Reset Signal. This Signal is Active LOW
		input wire  S_AXI_ARESETN,
		// Write address (issued by master, acceped by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
		// Write channel Protection type. This signal indicates the
    		// privilege and security level of the transaction, and whether
    		// the transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_AWPROT,
		// Write address valid. This signal indicates that the master signaling
    		// valid write address and control information.
		input wire  S_AXI_AWVALID,
		// Write address ready. This signal indicates that the slave is ready
    		// to accept an address and associated control signals.
		output wire  S_AXI_AWREADY,
		// Write data (issued by master, acceped by Slave) 
		input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
		// Write strobes. This signal indicates which byte lanes hold
    		// valid data. There is one write strobe bit for each eight
    		// bits of the write data bus.    
		input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
		// Write valid. This signal indicates that valid write
    		// data and strobes are available.
		input wire  S_AXI_WVALID,
		// Write ready. This signal indicates that the slave
    		// can accept the write data.
		output wire  S_AXI_WREADY,
		// Write response. This signal indicates the status
    		// of the write transaction.
		output wire [1 : 0] S_AXI_BRESP,
		// Write response valid. This signal indicates that the channel
    		// is signaling a valid write response.
		output wire  S_AXI_BVALID,
		// Response ready. This signal indicates that the master
    		// can accept a write response.
		input wire  S_AXI_BREADY,
		// Read address (issued by master, acceped by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
		// Protection type. This signal indicates the privilege
    		// and security level of the transaction, and whether the
    		// transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_ARPROT,
		// Read address valid. This signal indicates that the channel
    		// is signaling valid read address and control information.
		input wire  S_AXI_ARVALID,
		// Read address ready. This signal indicates that the slave is
    		// ready to accept an address and associated control signals.
		output wire  S_AXI_ARREADY,
		// Read data (issued by slave)
		output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
		// Read response. This signal indicates the status of the
    		// read transfer.
		output wire [1 : 0] S_AXI_RRESP,
		// Read valid. This signal indicates that the channel is
    		// signaling the required read data.
		output wire  S_AXI_RVALID,
		// Read ready. This signal indicates that the master can
    		// accept the read data and response information.
		input wire  S_AXI_RREADY
	);

	// AXI4LITE signals
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
	reg  	axi_awready;
	reg  	axi_wready;
	reg [1 : 0] 	axi_bresp;
	reg  	axi_bvalid;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
	reg  	axi_arready;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] 	axi_rdata;
	reg [1 : 0] 	axi_rresp;
	reg  	axi_rvalid;

	// Example-specific design signals
	// local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
	// ADDR_LSB is used for addressing 32/64 bit registers/memories
	// ADDR_LSB = 2 for 32 bits (n downto 2)
	// ADDR_LSB = 3 for 64 bits (n downto 3)
	localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
	localparam integer OPT_MEM_ADDR_BITS = 6;
	
	//--------------------------------------------------------------------------------------------
	//-- Input registers. You can RW those.
	//--------------------------------------------------------------------------------------------
	
	// The 'block template' is what builds up to the initial SHA3 state we'll scan.
	// In general this is just an opaque blob from the mining logic but element [20] is special.
	// It turns out bits blktemplate[20] is the scan_start. This value is somewhat special
	// as the nonce we effectively test is scan_start + iterator.
	// The remaining bits of the SHA3 state are built internally. 
	// AXI logical addressing: 0..23
	int unsigned blktemplate[24];
	
	// Often called "difficulty target", an hash is good enough if its 0-th ulong element is less than this.
	// Or more, depending on how you think your endianess.
	// AXI logical addressing: 24..25
	longint unsigned threshold;
	
	//----------------------------------------------
	//-- Output registers. Writing them is NOP.
	//------------------------------------------------
	
	// Iterator value producing an hash good enough. Because of how the pipeline works you're better pull this
	// only when both dispatching and evaluating have settled low otherwise - in the nearly zero chance another good nonce
	// is found by the pending pipelined values - this might be overwritten and be incoherent with interesting_hash.
	// It is also important you don't fiddle too much with the blktemplate as it contains scan_start information.
	// Only meaningful if .found is high.
	// AXI logical addressing: 26
	wire [31:0]	promising_nonce;
	
	// Legacy miners usually don't bother much with value correctness; they sometimes do some mumbo-jumbo with the difficulty
	// bits to guess if we were good enough or anything.
	// Here, I mantain the full hash for you to evaluate.
	// Only meaningful is .found is high.
	// AXI logical addressing: 27..76
	wire [31:0]	interesting_hash[50];
	
	// The hardware suggests you a scan count to keep it busy enough.
	// OFC the hardware doesn't know how much you clock it for now so that's a wild guess;
	// it is suggested you reserve this amount of nonces to orchestrator, for each scan operation,
	// the hardware will test this amount of nonces.
	// AXI logical addressing: 77
	wire [31:0] scan_count; 
	
	//----------------------------------------------
	//-- Special registers. Writing them might cause special things to happen.
	//------------------------------------------------
	
	// Control register. Does not really exist, listing there as it is part of logical addressing.
	// READING:
	//   bit[0] tracks .dispatching output
	//   bit[1] tracks .evaluating output
	//   bit[2] tracks .found output
	//   Other bits undefined.
	// WRITING:
	//   if at least one of .dispatching or .evaluating is high, writing is NOP
	//   Otherwise, blktemplate and threshold are assumed populated. Their values are captured and scanning starts again.
	//   As a result, .found will go low, .dispatching will go high. At some point .evaluating will go high.
	// ADDRESSING: 7'b1111111 = 7'h7F = 127
	
	wire	 slv_reg_rden;
	wire	 slv_reg_wren;
	reg [C_S_AXI_DATA_WIDTH-1:0]	 reg_data_out;
	integer	 byte_index;
	reg	 aw_en;

	// I/O Connections assignments

	assign S_AXI_AWREADY	= axi_awready;
	assign S_AXI_WREADY	= axi_wready;
	assign S_AXI_BRESP	= axi_bresp;
	assign S_AXI_BVALID	= axi_bvalid;
	assign S_AXI_ARREADY	= axi_arready;
	assign S_AXI_RDATA	= axi_rdata;
	assign S_AXI_RRESP	= axi_rresp;
	assign S_AXI_RVALID	= axi_rvalid;
	// Implement axi_awready generation
	// axi_awready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
	// de-asserted when reset is low.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awready <= 1'b0;
	      aw_en <= 1'b1;
	    end 
	  else
	    begin    
	      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
	        begin
	          // slave is ready to accept write address when 
	          // there is a valid write address and write data
	          // on the write address and data bus. This design 
	          // expects no outstanding transactions. 
	          axi_awready <= 1'b1;
	          aw_en <= 1'b0;
	        end
	        else if (S_AXI_BREADY && axi_bvalid)
	            begin
	              aw_en <= 1'b1;
	              axi_awready <= 1'b0;
	            end
	      else           
	        begin
	          axi_awready <= 1'b0;
	        end
	    end 
	end       

	// Implement axi_awaddr latching
	// This process is used to latch the address when both 
	// S_AXI_AWVALID and S_AXI_WVALID are valid. 

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awaddr <= 0;
	    end 
	  else
	    begin    
	      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
	        begin
	          // Write Address latching 
	          axi_awaddr <= S_AXI_AWADDR;
	        end
	    end 
	end       

	// Implement axi_wready generation
	// axi_wready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is 
	// de-asserted when reset is low. 

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_wready <= 1'b0;
	    end 
	  else
	    begin    
	      if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en )
	        begin
	          // slave is ready to accept write data when 
	          // there is a valid write address and write data
	          // on the write address and data bus. This design 
	          // expects no outstanding transactions. 
	          axi_wready <= 1'b1;
	        end
	      else
	        begin
	          axi_wready <= 1'b0;
	        end
	    end 
	end       

	// Implement memory mapped register select and write logic generation
	// The write data is accepted and written to memory mapped registers when
	// axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
	// select byte enables of slave registers while writing.
	// These registers are cleared when reset (active low) is applied.
	// Slave register write enable is asserted when valid address and data are available
	// and the slave is ready to accept the write address and write data.
	assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      blktemplate[ 0] <= 32'b0;    blktemplate[ 1] <= 32'b0;
	      blktemplate[ 2] <= 32'b0;    blktemplate[ 3] <= 32'b0;
	      blktemplate[ 4] <= 32'b0;    blktemplate[ 5] <= 32'b0;
	      blktemplate[ 6] <= 32'b0;    blktemplate[ 7] <= 32'b0;
	      blktemplate[ 8] <= 32'b0;    blktemplate[ 9] <= 32'b0;
	      blktemplate[10] <= 32'b0;    blktemplate[11] <= 32'b0;
	      blktemplate[12] <= 32'b0;    blktemplate[13] <= 32'b0;
	      blktemplate[14] <= 32'b0;    blktemplate[15] <= 32'b0;
	      blktemplate[16] <= 32'b0;    blktemplate[17] <= 32'b0;
	      blktemplate[18] <= 32'b0;    blktemplate[19] <= 32'b0;
	      blktemplate[20] <= 32'b0;    blktemplate[21] <= 32'b0;
	      blktemplate[22] <= 32'b0;    blktemplate[23] <= 32'b0;
	      threshold <= 64'b0;
	    end 
	  else begin
	    if (slv_reg_wren)
	      begin
	        case ( axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
	          7'h00:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 0
	                blktemplate[0][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          7'h01:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 1
	                blktemplate[1][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          7'h02:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 2
	                blktemplate[2][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          7'h03:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 3
	                blktemplate[3][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          7'h04:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 4
	                blktemplate[4][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          7'h05:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 5
	                blktemplate[5][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          7'h06:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 6
	                blktemplate[6][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          7'h07:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 7
	                blktemplate[7][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          7'h08:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 8
	                blktemplate[8][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          7'h09:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 9
	                blktemplate[9][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          7'h0A:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 10
	                blktemplate[10][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          7'h0B:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 11
	                blktemplate[11][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          7'h0C:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 12
	                blktemplate[12][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          7'h0D:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 13
	                blktemplate[13][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          7'h0E:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 14
	                blktemplate[14][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          7'h0F:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 15
	                blktemplate[15][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          7'h10:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 16
	                blktemplate[16][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          7'h11:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 17
	                blktemplate[17][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          7'h12:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 18
	                blktemplate[18][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end   
	          7'h13:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 19
	                blktemplate[19][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end   
	          7'h14:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 20
	                blktemplate[20][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end   
	          7'h15:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 21
	                blktemplate[21][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          7'h16:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 22
	                blktemplate[22][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          7'h17:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 23
	                blktemplate[23][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          7'h18: // Register 24
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) threshold[( 0 + (byte_index*8)) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	          7'h19: // Register 25
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) threshold[(32 + (byte_index*8)) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	          default : begin
	                      blktemplate[ 0] <= blktemplate[ 0];
	                      blktemplate[ 1] <= blktemplate[ 1];
	                      blktemplate[ 2] <= blktemplate[ 2];
	                      blktemplate[ 3] <= blktemplate[ 3];
	                      blktemplate[ 4] <= blktemplate[ 4];
	                      blktemplate[ 5] <= blktemplate[ 5];
	                      blktemplate[ 6] <= blktemplate[ 6];
	                      blktemplate[ 7] <= blktemplate[ 7];
	                      blktemplate[ 8] <= blktemplate[ 8];
	                      blktemplate[ 9] <= blktemplate[ 9];
	                      blktemplate[10] <= blktemplate[10];
	                      blktemplate[11] <= blktemplate[11];
	                      blktemplate[12] <= blktemplate[12];
	                      blktemplate[13] <= blktemplate[13];
	                      blktemplate[14] <= blktemplate[14];
	                      blktemplate[15] <= blktemplate[15];
	                      blktemplate[16] <= blktemplate[16];
	                      blktemplate[17] <= blktemplate[17];
	                      blktemplate[18] <= blktemplate[18];
	                      blktemplate[19] <= blktemplate[19];
	                      blktemplate[20] <= blktemplate[20];
	                      blktemplate[21] <= blktemplate[21];
	                      blktemplate[22] <= blktemplate[22];
	                      blktemplate[23] <= blktemplate[23];
	                      threshold <= threshold;
	                    end
	        endcase
	      end
	  end
	end    

	// Implement write response logic generation
	// The write response and response valid signals are asserted by the slave 
	// when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.  
	// This marks the acceptance of address and indicates the status of 
	// write transaction.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_bvalid  <= 0;
	      axi_bresp   <= 2'b0;
	    end 
	  else
	    begin    
	      if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
	        begin
	          // indicates a valid write response is available
	          axi_bvalid <= 1'b1;
	          axi_bresp  <= 2'b0; // 'OKAY' response 
	        end                   // work error responses in future
	      else
	        begin
	          if (S_AXI_BREADY && axi_bvalid) 
	            //check if bready is asserted while bvalid is high) 
	            //(there is a possibility that bready is always asserted high)   
	            begin
	              axi_bvalid <= 1'b0; 
	            end  
	        end
	    end
	end   

	// Implement axi_arready generation
	// axi_arready is asserted for one S_AXI_ACLK clock cycle when
	// S_AXI_ARVALID is asserted. axi_awready is 
	// de-asserted when reset (active low) is asserted. 
	// The read address is also latched when S_AXI_ARVALID is 
	// asserted. axi_araddr is reset to zero on reset assertion.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_arready <= 1'b0;
	      axi_araddr  <= 32'b0;
	    end 
	  else
	    begin    
	      if (~axi_arready && S_AXI_ARVALID)
	        begin
	          // indicates that the slave has acceped the valid read address
	          axi_arready <= 1'b1;
	          // Read address latching
	          axi_araddr  <= S_AXI_ARADDR;
	        end
	      else
	        begin
	          axi_arready <= 1'b0;
	        end
	    end 
	end       

	// Implement axi_arvalid generation
	// axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both 
	// S_AXI_ARVALID and axi_arready are asserted. The slave registers 
	// data are available on the axi_rdata bus at this instance. The 
	// assertion of axi_rvalid marks the validity of read data on the 
	// bus and axi_rresp indicates the status of read transaction.axi_rvalid 
	// is deasserted on reset (active low). axi_rresp and axi_rdata are 
	// cleared to zero on reset (active low).  
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_rvalid <= 0;
	      axi_rresp  <= 0;
	    end 
	  else
	    begin    
	      if (axi_arready && S_AXI_ARVALID && ~axi_rvalid)
	        begin
	          // Valid read data is available at the read data bus
	          axi_rvalid <= 1'b1;
	          axi_rresp  <= 2'b0; // 'OKAY' response
	        end   
	      else if (axi_rvalid && S_AXI_RREADY)
	        begin
	          // Read data is accepted by the master
	          axi_rvalid <= 1'b0;
	        end                
	    end
	end    

	// Implement memory mapped register select and read logic generation
	// Slave register read enable is asserted when valid address is available
	// and the slave is ready to accept the read address.
	assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;
	always @(*)
	begin
	      // Address decoding for reading registers
	      case ( axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
	        7'h00   : reg_data_out <= blktemplate[ 0];
	        7'h01   : reg_data_out <= blktemplate[ 1];
	        7'h02   : reg_data_out <= blktemplate[ 2];
	        7'h03   : reg_data_out <= blktemplate[ 3];
	        7'h04   : reg_data_out <= blktemplate[ 4];
	        7'h05   : reg_data_out <= blktemplate[ 5];
	        7'h06   : reg_data_out <= blktemplate[ 6];
	        7'h07   : reg_data_out <= blktemplate[ 7];
	        7'h08   : reg_data_out <= blktemplate[ 8];
	        7'h09   : reg_data_out <= blktemplate[ 9];
	        7'h0A   : reg_data_out <= blktemplate[10];
	        7'h0B   : reg_data_out <= blktemplate[11];
	        7'h0C   : reg_data_out <= blktemplate[12];
	        7'h0D   : reg_data_out <= blktemplate[13];
	        7'h0E   : reg_data_out <= blktemplate[14];
	        7'h0F   : reg_data_out <= blktemplate[15];
	        7'h10   : reg_data_out <= blktemplate[16];
	        7'h11   : reg_data_out <= blktemplate[17];
	        7'h12   : reg_data_out <= blktemplate[18];
	        7'h13   : reg_data_out <= blktemplate[19];
	        7'h14   : reg_data_out <= blktemplate[20];
	        7'h15   : reg_data_out <= blktemplate[21];
	        7'h16   : reg_data_out <= blktemplate[22];
	        7'h17   : reg_data_out <= blktemplate[23];
	        7'h18   : reg_data_out <= threshold[31: 0];
	        7'h19   : reg_data_out <= threshold[63:32];
	        
	        7'h1A   : reg_data_out <= promising_nonce;
	        7'h1B   : reg_data_out <= interesting_hash[ 0];
	        7'h1C   : reg_data_out <= interesting_hash[ 1];
	        7'h1D   : reg_data_out <= interesting_hash[ 2];
	        7'h1E   : reg_data_out <= interesting_hash[ 3];
	        7'h1F   : reg_data_out <= interesting_hash[ 4];
	        7'h20   : reg_data_out <= interesting_hash[ 5];
	        7'h21   : reg_data_out <= interesting_hash[ 6];
	        7'h22   : reg_data_out <= interesting_hash[ 7];
	        7'h23   : reg_data_out <= interesting_hash[ 8];
	        7'h24   : reg_data_out <= interesting_hash[ 9];
	        7'h25   : reg_data_out <= interesting_hash[10];
	        7'h26   : reg_data_out <= interesting_hash[11];
	        7'h27   : reg_data_out <= interesting_hash[12];
	        7'h28   : reg_data_out <= interesting_hash[13];
	        7'h29   : reg_data_out <= interesting_hash[14];
	        7'h2A   : reg_data_out <= interesting_hash[15];
	        7'h2B   : reg_data_out <= interesting_hash[16];
	        7'h2C   : reg_data_out <= interesting_hash[17];
	        7'h2D   : reg_data_out <= interesting_hash[18];
	        7'h2E   : reg_data_out <= interesting_hash[19];
	        7'h2F   : reg_data_out <= interesting_hash[20];
	        7'h30   : reg_data_out <= interesting_hash[21];
	        7'h31   : reg_data_out <= interesting_hash[22];
	        7'h32   : reg_data_out <= interesting_hash[23];
	        7'h33   : reg_data_out <= interesting_hash[24];
	        7'h34   : reg_data_out <= interesting_hash[25];
	        7'h35   : reg_data_out <= interesting_hash[26];
	        7'h36   : reg_data_out <= interesting_hash[27];
	        7'h37   : reg_data_out <= interesting_hash[28];
	        7'h38   : reg_data_out <= interesting_hash[29];
	        7'h39   : reg_data_out <= interesting_hash[30];
	        7'h3A   : reg_data_out <= interesting_hash[31];
	        7'h3B   : reg_data_out <= interesting_hash[32];
	        7'h3C   : reg_data_out <= interesting_hash[33];
	        7'h3D   : reg_data_out <= interesting_hash[34];
	        7'h3E   : reg_data_out <= interesting_hash[35];
	        7'h3F   : reg_data_out <= interesting_hash[36];
	        7'h40   : reg_data_out <= interesting_hash[37];
	        7'h41   : reg_data_out <= interesting_hash[38];
	        7'h42   : reg_data_out <= interesting_hash[39];
	        7'h43   : reg_data_out <= interesting_hash[40];
	        7'h44   : reg_data_out <= interesting_hash[41];
	        7'h45   : reg_data_out <= interesting_hash[42];
	        7'h46   : reg_data_out <= interesting_hash[43];
	        7'h47   : reg_data_out <= interesting_hash[44];
	        7'h48   : reg_data_out <= interesting_hash[45];
	        7'h49   : reg_data_out <= interesting_hash[46];
	        7'h4A   : reg_data_out <= interesting_hash[47];
	        7'h4B   : reg_data_out <= interesting_hash[48];
	        7'h4C   : reg_data_out <= interesting_hash[49];
	        
	        7'h4D   : reg_data_out <= scan_count;
	        
	        7'h7F   : reg_data_out <= { (PROPER_SHA3 ? 1'b1 : 1'b0), 27'b0, found, idle, evaluating, dispatching };
	        default : reg_data_out <= 0;
	      endcase
	end

	// Output register or memory read data
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_rdata  <= 0;
	    end 
	  else
	    begin    
	      // When there is a valid read address (S_AXI_ARVALID) with 
	      // acceptance of read address by the slave (axi_arready), 
	      // output the read dada 
	      if (slv_reg_rden)
	        begin
	          axi_rdata <= reg_data_out;     // register read data
	        end   
	    end
	end    

	// Add user logic here

  wire writing_control = slv_reg_wren & axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == $unsigned(7'h7F);
	wire start = idle & writing_control;
	wire[63:0] wide_hash[25];
	
	wire[31:0] into_scanner[PROPER_SHA3 ? 20 : 24];
	if (PROPER_SHA3) begin : proper 
	    assign into_scanner = '{
	        blktemplate[ 0], blktemplate[ 1], blktemplate[ 2], blktemplate[ 3],
	        blktemplate[ 4], blktemplate[ 5], blktemplate[ 6], blktemplate[ 7],
	        blktemplate[ 8], blktemplate[ 9], blktemplate[10], blktemplate[11],
	        blktemplate[12], blktemplate[13], blktemplate[14], blktemplate[15],
	        blktemplate[16], blktemplate[17], blktemplate[18], blktemplate[19]
	    };
	end
	else begin : quirky
	    assign into_scanner = '{
          blktemplate[ 0], blktemplate[ 1], blktemplate[ 2], blktemplate[ 3],
          blktemplate[ 4], blktemplate[ 5], blktemplate[ 6], blktemplate[ 7],
          blktemplate[ 8], blktemplate[ 9], blktemplate[10], blktemplate[11],
          blktemplate[12], blktemplate[13], blktemplate[14], blktemplate[15],
          blktemplate[16], blktemplate[17], blktemplate[18], blktemplate[19],
          blktemplate[20], blktemplate[21], blktemplate[22], blktemplate[23]
      };
  end
	
	sha3_scanner_instantiator #(
	    .STYLE(STYLE),
	    .FEEDBACK_MUX_STYLE(FEEDBACK_MUX_STYLE),
	    .PROPER(PROPER_SHA3)
	) thing (
      .clk(S_AXI_ACLK), .rst(~S_AXI_ARESETN),
      .ready(idle),
      .start(start), .dispatching(dispatching), .evaluating(evaluating), .found(found),
      .threshold(threshold),
      
      .blobby(into_scanner),  .nonce(promising_nonce),
      .hash(wide_hash),
      
      .scan_count(scan_count)
	);
	
	for (genvar loop = 0; loop < 25; loop++) begin : cp
	    assign interesting_hash[loop * 2 + 1] = wide_hash[loop][63:32];
	    assign interesting_hash[loop * 2 + 0] = wide_hash[loop][31: 0];
	end
	
	// User logic ends

	endmodule
