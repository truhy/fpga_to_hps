/*
	MIT License

	Copyright (c) 2023 Truong Hy
	
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
	Target   : For the DE10-Nano development kit board (Intel Cyclone V SoC FPGA)
	Version  : 20241019
	
	FPGA hardware logic design for sending data from FPGA to HPS using the
	FPGA-to-HPS SDRAM interface (F2S interface).
	
	Data is transferred from FPGA embedded RAM (as block RAM) to HPS SDRAM.
*/

module top(
	// FPGA clock
	input FPGA_CLK1_50,
	input FPGA_CLK2_50,
	input FPGA_CLK3_50,
	
	// FPGA ADC. FPGA pins wired to LTC2308 (SPI)
	output ADC_CONVST,
	output ADC_SCK,
	output ADC_SDI,
	input  ADC_SDO,
	
	// FPGA Arduino IO. FPGA pins wired to female headers
	inout [15:0] ARDUINO_IO,
	inout        ARDUINO_RESET_N,
	
	// FPGA GPIO. FPGA pins wired to 2x male headers
	inout [35:0] GPIO_0,
	inout [35:0] GPIO_1,
	
	// FPGA HDMI. FPGA pins to HDMI transmitter chip (Analog Devices ADV7513BSWZ)
	inout         HDMI_I2C_SCL,
	inout         HDMI_I2C_SDA,
	inout         HDMI_I2S,
	inout         HDMI_LRCLK,
	inout         HDMI_MCLK,
	inout         HDMI_SCLK,
	output        HDMI_TX_CLK,
	output [23:0] HDMI_TX_D,
	output        HDMI_TX_DE,
	output        HDMI_TX_HS,
	input         HDMI_TX_INT,
	output        HDMI_TX_VS,

	// FPGA push buttons, LEDs and slide switches
	input  [1:0] KEY,  // FPGA pins to tactile switches
	output [7:0] LED,  // FPGA pins to LEDs
	input  [3:0] SW,   // FPGA pins to slide switches
	
	// HPS user key and LED
	inout HPS_KEY,
	inout HPS_LED,

	// HPS DDR-3 SDRAM. HPS pins to DDR3 1GB = 2x512MB chips
	output [14:0] HPS_DDR3_ADDR,
	output [2:0]  HPS_DDR3_BA,
	output        HPS_DDR3_CAS_N,
	output        HPS_DDR3_CKE,
	output        HPS_DDR3_CK_N,
	output        HPS_DDR3_CK_P,
	output        HPS_DDR3_CS_N,
	output [3:0]  HPS_DDR3_DM,
	inout  [31:0] HPS_DDR3_DQ,
	inout  [3:0]  HPS_DDR3_DQS_N,
	inout  [3:0]  HPS_DDR3_DQS_P,
	output        HPS_DDR3_ODT,
	output        HPS_DDR3_RAS_N,
	output        HPS_DDR3_RESET_N,
	input         HPS_DDR3_RZQ,
	output        HPS_DDR3_WE_N,
	
	// HPS SD-CARD. HPS pins wired to micro SD card slot
	output      HPS_SD_CLK,
	inout       HPS_SD_CMD,
	inout [3:0] HPS_SD_DATA,

	// HPS UART (UART-USB). HPS pins wired to chip FTDI FT232R
	input  HPS_UART_RX,
	output HPS_UART_TX,
	inout  HPS_CONV_USB_N,
	
	// HPS USB OTG. HPS pins wired to the USB PHY chip (Microchip USB3300)
	input       HPS_USB_CLKOUT,
	inout [7:0] HPS_USB_DATA,
	input       HPS_USB_DIR,
	input       HPS_USB_NXT,
	output      HPS_USB_STP,
	
	// HPS EMAC. HPS pins wired to the gigabit ethernet PHY chip (Microchip KSZ9031RNX)
	output       HPS_ENET_GTX_CLK,
	output       HPS_ENET_MDC,
	inout        HPS_ENET_MDIO,
	input        HPS_ENET_RX_CLK,
	input  [3:0] HPS_ENET_RX_DATA,
	input        HPS_ENET_RX_DV,
	output [3:0] HPS_ENET_TX_DATA,
	output       HPS_ENET_TX_EN,
	inout        HPS_ENET_INT_N,

	// HPS SPI. HPS pins wired to the LTC 2x7 connector
	output HPS_SPIM_CLK,
	input  HPS_SPIM_MISO,
	output HPS_SPIM_MOSI,
	output HPS_SPIM_SS,

	// HPS GPIO. HPS pin wired to the LTC 2x7 connector (note, this cannot be used because the 0ohm resistor is not populated)
	//inout HPS_LTC_GPIO,
	
	// HPS I2C 1. HPS pins wired to the LTC 2x7 connector
	inout HPS_I2C1_SCLK,
	inout HPS_I2C1_SDAT,
	
	// HPS I2C 0. HPS pins wired to the ADXL345 accelerometer
	inout HPS_I2C0_SCLK,
	inout HPS_I2C0_SDAT,
	inout HPS_GSENSOR_INT  // ADXL345 interrupt 1 output (pin 9)
);
	`include "my_modules/axi_def.vh"

	// ================
	// HPS (SoC) module
	// ================
	
	// Local scope parameters
	localparam                           F2S_BIT_BUS_WIDTH  = 256;  // This should match the AXI FPGA-to-HPS SDRAM interface width in Platform Designer
	localparam                           F2S_BYTE_BUS_WIDTH = F2S_BIT_BUS_WIDTH / 8;
	localparam                           F2S_MAX_BURST_LEN  = 16;  // Valid range: 1 to 16
	localparam [2:0]                     F2S_BURST_SIZE     = (F2S_BIT_BUS_WIDTH == 256) ? `AXI_AXBURST_SIZE_256 : 
	                                                          (F2S_BIT_BUS_WIDTH == 128) ? `AXI_AXBURST_SIZE_128 : 
	                                                          (F2S_BIT_BUS_WIDTH == 64) ? `AXI_AXBURST_SIZE_64 : 
	                                                          `AXI_AXBURST_SIZE_32;
	localparam [F2S_BIT_BUS_WIDTH/8-1:0] F2S_WSTRB_SIZE     = (F2S_BIT_BUS_WIDTH == 256) ? `AXI_WSTRB_SIZE_256 :
	                                                          (F2S_BIT_BUS_WIDTH == 128) ? `AXI_WSTRB_SIZE_128 :
	                                                          (F2S_BIT_BUS_WIDTH == 64) ? `AXI_WSTRB_SIZE_64 : 
	                                                          `AXI_WSTRB_SIZE_32;

	// Wires for the PLL clock and reset
	wire pll0_clock0;
	wire hps_reset_n;
	wire master_reset_n = hps_reset_n;

	// Wires for the AXI FPGA-to-HPS SDRAM interface
  wire [31:0]                    f2s_axi_araddr;
  wire [3:0]                     f2s_axi_arlen;
  wire [7:0]                     f2s_axi_arid;
  wire [2:0]                     f2s_axi_arsize;
  wire [1:0]                     f2s_axi_arburst;
  wire [1:0]                     f2s_axi_arlock;
  wire [2:0]                     f2s_axi_arprot;
  wire                           f2s_axi_arvalid;
  wire [3:0]                     f2s_axi_arcache;
  wire [31:0]                    f2s_axi_awaddr;
  wire [3:0]                     f2s_axi_awlen;
  wire [7:0]                     f2s_axi_awid;
  wire [2:0]                     f2s_axi_awsize;
  wire [1:0]                     f2s_axi_awburst;
  wire [1:0]                     f2s_axi_awlock;
  wire [2:0]                     f2s_axi_awprot;
  wire                           f2s_axi_awvalid;
  wire [3:0]                     f2s_axi_awcache;
  wire [1:0]                     f2s_axi_bresp;
  wire [7:0]                     f2s_axi_bid;
  wire                           f2s_axi_bvalid;
  wire                           f2s_axi_bready;
  wire                           f2s_axi_arready;
  wire                           f2s_axi_awready;
  wire                           f2s_axi_rready;
  wire [F2S_BIT_BUS_WIDTH-1:0]   f2s_axi_rdata;
  wire [1:0]                     f2s_axi_rresp;
  wire                           f2s_axi_rlast;
  wire [7:0]                     f2s_axi_rid;
  wire                           f2s_axi_rvalid;
  wire                           f2s_axi_wlast;
  wire                           f2s_axi_wvalid;
  wire [F2S_BIT_BUS_WIDTH-1:0]   f2s_axi_wdata;
  wire [F2S_BIT_BUS_WIDTH/8-1:0] f2s_axi_wstrb;
  wire                           f2s_axi_wready;
  wire [7:0]                     f2s_axi_wid;
	
	wire [31:0] f2h_irq0;  // IRQs: 72 to 103
	wire [31:0] f2h_irq1;  // IRQs: 104 to 135
	
	// Wires for the PIO IP ports used for communication between FPGA and HPS
	wire [31:0] pio_s0_rdy_in;
	wire [31:0] pio_s0_rdy_out;
	wire [31:0] pio_s0_addr_in;
	wire [31:0] pio_s0_addr_out;
	wire [31:0] pio_s0_len_in;
	wire [31:0] pio_s0_len_out;
	
	// HPS (SoC) instance
	soc_system u0(
		// Clock
		.clk_clk(FPGA_CLK1_50),
		.clock_bridge_0_out_clk_clk(pll0_clock0),

		// HPS DDR-3 SDRAM pin connections
		.memory_mem_a(HPS_DDR3_ADDR),
		.memory_mem_ba(HPS_DDR3_BA),
		.memory_mem_ck(HPS_DDR3_CK_P),
		.memory_mem_ck_n(HPS_DDR3_CK_N),
		.memory_mem_cke(HPS_DDR3_CKE),
		.memory_mem_cs_n(HPS_DDR3_CS_N),
		.memory_mem_ras_n(HPS_DDR3_RAS_N),
		.memory_mem_cas_n(HPS_DDR3_CAS_N),
		.memory_mem_we_n(HPS_DDR3_WE_N),
		.memory_mem_reset_n(HPS_DDR3_RESET_N),
		.memory_mem_dq(HPS_DDR3_DQ),
		.memory_mem_dqs(HPS_DDR3_DQS_P),
		.memory_mem_dqs_n(HPS_DDR3_DQS_N),
		.memory_mem_odt(HPS_DDR3_ODT),
		.memory_mem_dm(HPS_DDR3_DM),
		.memory_oct_rzqin(HPS_DDR3_RZQ),
		
		// HPS SD-card pin connections
		.hps_io_hps_io_sdio_inst_CMD(HPS_SD_CMD),
		.hps_io_hps_io_sdio_inst_D0(HPS_SD_DATA[0]),
		.hps_io_hps_io_sdio_inst_D1(HPS_SD_DATA[1]),
		.hps_io_hps_io_sdio_inst_CLK(HPS_SD_CLK),
		.hps_io_hps_io_sdio_inst_D2(HPS_SD_DATA[2]),
		.hps_io_hps_io_sdio_inst_D3(HPS_SD_DATA[3]),
		
		// HPS UART0 (UART-USB) pin connections
		.hps_io_hps_io_uart0_inst_RX(HPS_UART_RX),
		.hps_io_hps_io_uart0_inst_TX(HPS_UART_TX),
		
		// HPS EMAC1 (Ethernet) pin connections
		.hps_io_hps_io_emac1_inst_TX_CLK(HPS_ENET_GTX_CLK),
		.hps_io_hps_io_emac1_inst_TXD0(HPS_ENET_TX_DATA[0]),
		.hps_io_hps_io_emac1_inst_TXD1(HPS_ENET_TX_DATA[1]),
		.hps_io_hps_io_emac1_inst_TXD2(HPS_ENET_TX_DATA[2]),
		.hps_io_hps_io_emac1_inst_TXD3(HPS_ENET_TX_DATA[3]),
		.hps_io_hps_io_emac1_inst_RXD0(HPS_ENET_RX_DATA[0]),
		.hps_io_hps_io_emac1_inst_MDIO(HPS_ENET_MDIO),
		.hps_io_hps_io_emac1_inst_MDC(HPS_ENET_MDC),
		.hps_io_hps_io_emac1_inst_RX_CTL(HPS_ENET_RX_DV),
		.hps_io_hps_io_emac1_inst_TX_CTL(HPS_ENET_TX_EN),
		.hps_io_hps_io_emac1_inst_RX_CLK(HPS_ENET_RX_CLK),
		.hps_io_hps_io_emac1_inst_RXD1(HPS_ENET_RX_DATA[1]),
		.hps_io_hps_io_emac1_inst_RXD2(HPS_ENET_RX_DATA[2]),
		.hps_io_hps_io_emac1_inst_RXD3(HPS_ENET_RX_DATA[3]),

		// HPS USB1 2.0 OTG pin connections
		.hps_io_hps_io_usb1_inst_D0(HPS_USB_DATA[0]),
		.hps_io_hps_io_usb1_inst_D1(HPS_USB_DATA[1]),
		.hps_io_hps_io_usb1_inst_D2(HPS_USB_DATA[2]),
		.hps_io_hps_io_usb1_inst_D3(HPS_USB_DATA[3]),
		.hps_io_hps_io_usb1_inst_D4(HPS_USB_DATA[4]),
		.hps_io_hps_io_usb1_inst_D5(HPS_USB_DATA[5]),
		.hps_io_hps_io_usb1_inst_D6(HPS_USB_DATA[6]),
		.hps_io_hps_io_usb1_inst_D7(HPS_USB_DATA[7]),
		.hps_io_hps_io_usb1_inst_CLK(HPS_USB_CLKOUT),
		.hps_io_hps_io_usb1_inst_STP(HPS_USB_STP),
		.hps_io_hps_io_usb1_inst_DIR(HPS_USB_DIR),
		.hps_io_hps_io_usb1_inst_NXT(HPS_USB_NXT),
		
		// HPS SPI1 pin connections
		.hps_io_hps_io_spim1_inst_CLK(HPS_SPIM_CLK),
		.hps_io_hps_io_spim1_inst_MOSI(HPS_SPIM_MOSI),
		.hps_io_hps_io_spim1_inst_MISO(HPS_SPIM_MISO),
		.hps_io_hps_io_spim1_inst_SS0(HPS_SPIM_SS),
		
		// HPS I2C0 pin connections
		.hps_io_hps_io_i2c0_inst_SDA(HPS_I2C0_SDAT),
		.hps_io_hps_io_i2c0_inst_SCL(HPS_I2C0_SCLK),
		
		// HPS I2C1 pin connections
		.hps_io_hps_io_i2c1_inst_SDA(HPS_I2C1_SDAT),
		.hps_io_hps_io_i2c1_inst_SCL(HPS_I2C1_SCLK),
		
		// HPS GPIO pin connections
		.hps_io_hps_io_gpio_inst_GPIO09(HPS_CONV_USB_N),
		.hps_io_hps_io_gpio_inst_GPIO35(HPS_ENET_INT_N),
		//.hps_io_hps_io_gpio_inst_GPIO40(HPS_LTC_GPIO),
		.hps_io_hps_io_gpio_inst_GPIO53(HPS_LED),
		.hps_io_hps_io_gpio_inst_GPIO54(HPS_KEY),
		.hps_io_hps_io_gpio_inst_GPIO61(HPS_GSENSOR_INT),
		
		// AXI FPGA-to-HPS SDRAM interface
		// Provides FPGA access to the HPS 3GB SDRAM address space via SDRAM Controller Subsystem.  Note only 1GB is installed on the DE10-Nano
		// See SDRAM Controller Subsystem Block Diagram in Cyclone V Tech Ref Man
		.f2h_sdram0_data_araddr(f2s_axi_araddr),
		.f2h_sdram0_data_arlen(f2s_axi_arlen),
		.f2h_sdram0_data_arid(f2s_axi_arid),
		.f2h_sdram0_data_arsize(f2s_axi_arsize),
		.f2h_sdram0_data_arburst(f2s_axi_arburst),
		.f2h_sdram0_data_arlock(f2s_axi_arlock),
		.f2h_sdram0_data_arprot(f2s_axi_arprot),
		.f2h_sdram0_data_arvalid(f2s_axi_arvalid),
		.f2h_sdram0_data_arcache(f2s_axi_arcache),
		.f2h_sdram0_data_awaddr(f2s_axi_awaddr),
		.f2h_sdram0_data_awlen(f2s_axi_awlen),
		.f2h_sdram0_data_awid(f2s_axi_awid),
		.f2h_sdram0_data_awsize(f2s_axi_awsize),
		.f2h_sdram0_data_awburst(f2s_axi_awburst),
		.f2h_sdram0_data_awlock(f2s_axi_awlock),
		.f2h_sdram0_data_awprot(f2s_axi_awprot),
		.f2h_sdram0_data_awvalid(f2s_axi_awvalid),
		.f2h_sdram0_data_awcache(f2s_axi_awcache),
		.f2h_sdram0_data_bresp(f2s_axi_bresp),
		.f2h_sdram0_data_bid(f2s_axi_bid),
		.f2h_sdram0_data_bvalid(f2s_axi_bvalid),
		.f2h_sdram0_data_bready(f2s_axi_bready),
		.f2h_sdram0_data_arready(f2s_axi_arready),
		.f2h_sdram0_data_awready(f2s_axi_awready),
		.f2h_sdram0_data_rready(f2s_axi_rready),
		.f2h_sdram0_data_rdata(f2s_axi_rdata),
		.f2h_sdram0_data_rresp(f2s_axi_rresp),
		.f2h_sdram0_data_rlast(f2s_axi_rlast),
		.f2h_sdram0_data_rid(f2s_axi_rid),
		.f2h_sdram0_data_rvalid(f2s_axi_rvalid),
		.f2h_sdram0_data_wlast(f2s_axi_wlast),
		.f2h_sdram0_data_wvalid(f2s_axi_wvalid),
		.f2h_sdram0_data_wdata(f2s_axi_wdata),
		.f2h_sdram0_data_wstrb(f2s_axi_wstrb),
		.f2h_sdram0_data_wready(f2s_axi_wready),
		.f2h_sdram0_data_wid(f2s_axi_wid),
		
		// FPGA-to-HPS interrupt receiver ports
		.hps_0_f2h_irq0_irq(f2h_irq0),  // IRQs 72 to 103
		.hps_0_f2h_irq1_irq(f2h_irq1),  // IRQs 104 to 135
		
		// PIO IP ports
		.pio_s0_rdy_external_connection_in_port(pio_s0_rdy_in),
		.pio_s0_rdy_external_connection_out_port(pio_s0_rdy_out),
		.pio_s0_addr_external_connection_in_port(pio_s0_addr_in),
		.pio_s0_addr_external_connection_out_port(pio_s0_addr_out),
		.pio_s0_len_external_connection_in_port(pio_s0_len_in),
		.pio_s0_len_external_connection_out_port(pio_s0_len_out),
		
		// Reset
		.hps_0_h2f_reset_reset_n(hps_reset_n),
		.reset_reset_n(hps_reset_n)
	);
	
	// ============
	// Push buttons
	// ============
	
	wire debounced_key0;
	wire debounced_key1;
	debounce #(
		.CLK_CNT_WIDTH(21),
		.SW_WIDTH(2)
	)
	debounce_0(
		.rst_n(master_reset_n),
		.clk(FPGA_CLK1_50),
		.div(1250000),
		.sw_in({ ~KEY[1], ~KEY[0] }),
		.sw_out({ debounced_key1, debounced_key0 })
	);
	
	// ==========
	// AXI Helper
	// ==========
	
	// Local scope parameters for AXI reader and writer helper
	localparam F2S_ARH_ID_WIDTH      = 8;
	localparam F2S_ARH_ADDR_WIDTH    = 32;
	localparam F2S_ARH_BUS_WIDTH     = F2S_BIT_BUS_WIDTH;
	localparam F2S_ARH_MAX_BURST_LEN = F2S_MAX_BURST_LEN;
	localparam F2S_AWH_ID_WIDTH      = 8;
	localparam F2S_AWH_ADDR_WIDTH    = 32;
	localparam F2S_AWH_BUS_WIDTH     = F2S_BIT_BUS_WIDTH;
	localparam F2S_AWH_MAX_BURST_LEN = F2S_MAX_BURST_LEN;
	
	wire                                               f2s_arh_enable;
	wire [F2S_ARH_ID_WIDTH-1:0]                        f2s_arh_id;
	wire [F2S_ARH_ADDR_WIDTH-1:0]                      f2s_arh_addr;
	wire [F2S_ARH_MAX_BURST_LEN*F2S_ARH_BUS_WIDTH-1:0] f2s_arh_data;
	wire [3:0]                                         f2s_arh_burst_len;
	wire [2:0]                                         f2s_arh_burst_size;
	wire [1:0]                                         f2s_arh_status;	
	// AXI reader helper instance
	axi_rd #(
		.AXI_RD_ID_WIDTH(F2S_ARH_ID_WIDTH),
		.AXI_RD_ADDR_WIDTH(F2S_ARH_ADDR_WIDTH),
		.AXI_RD_BUS_WIDTH(F2S_ARH_BUS_WIDTH),
		.AXI_RD_MAX_BURST_LEN(F2S_ARH_MAX_BURST_LEN)
	) f2s_arh_0(
		.clock(pll0_clock0),
		.reset_n(master_reset_n),
		
		.enable(f2s_arh_enable),
		.id(f2s_arh_id),
		.addr(f2s_arh_addr),
		.data(f2s_arh_data),
		.burst_len(f2s_arh_burst_len),
		.burst_size(f2s_arh_burst_size),
		.burst_type(`AXI_AXBURST_TYPE_INCR),  // Auto incrementing burst type
		.lock(`AXI_AXLOCK_NORMAL),            // Normal access
		
		// These don't seem to have any effect for F2S
		.cache(`AXI_AXCACHE_NONE),        // Outer cache attributes: no cache
		.prot(`AXI_AXPROT_D_SE_N),        // Protection attributes: data access, secure access, normal access
		.user(`AXI_AXUSER_SHARED_NM_NC),  // User attributes: shared, normal memory, non-cacheable
		
		.status(f2s_arh_status),

		.ar_id(f2s_axi_arid),
		.ar_addr(f2s_axi_araddr),
		.ar_len(f2s_axi_arlen),
		.ar_size(f2s_axi_arsize),
		.ar_burst(f2s_axi_arburst),
		.ar_lock(f2s_axi_arlock),
		.ar_cache(f2s_axi_arcache),
		.ar_prot(f2s_axi_arprot),
		.ar_user(f2s_axi_aruser),
		.ar_valid(f2s_axi_arvalid),
		.ar_ready(f2s_axi_arready),
		.r_id(f2s_axi_rid),
		.r_data(f2s_axi_rdata),
		.r_last(f2s_axi_rlast),
		.r_resp(f2s_axi_rresp),
		.r_valid(f2s_axi_rvalid),
		.r_ready(f2s_axi_rready)
	);

	wire                                               f2s_awh_enable;
	wire [F2S_AWH_ID_WIDTH-1:0]                        f2s_awh_id;
	wire [F2S_AWH_ADDR_WIDTH-1:0]                      f2s_awh_addr;
	wire [F2S_AWH_MAX_BURST_LEN*F2S_AWH_BUS_WIDTH-1:0] f2s_awh_data;
	wire [3:0]                                         f2s_awh_burst_len;
	wire [2:0]                                         f2s_awh_burst_size;
	wire [F2S_AWH_BUS_WIDTH/8-1:0]                     f2s_awh_strb;
	wire [1:0]                                         f2s_awh_status;
	// AXI writer helper instance
	axi_wr #(
		.AXI_WR_ID_WIDTH(F2S_AWH_ID_WIDTH),
		.AXI_WR_ADDR_WIDTH(F2S_AWH_ADDR_WIDTH),
		.AXI_WR_BUS_WIDTH(F2S_AWH_BUS_WIDTH),
		.AXI_WR_MAX_BURST_LEN(F2S_AWH_MAX_BURST_LEN)
	) f2s_awh_0(
		.clock(pll0_clock0),
		.reset_n(master_reset_n),
		
		.enable(f2s_awh_enable),
		.id(f2s_awh_id),
		.addr(f2s_awh_addr),
		.data(f2s_awh_data),
		.burst_len(f2s_awh_burst_len),
		.burst_size(f2s_awh_burst_size),
		.burst_type(`AXI_AXBURST_TYPE_INCR),  // Auto incrementing burst type
		.lock(`AXI_AXLOCK_NORMAL),            // Normal access
		
		// These don't seem to have any effect for F2S
		.cache(`AXI_AXCACHE_NONE),        // Outer cache attributes: no cache
		.prot(`AXI_AXPROT_D_SE_N),        // Protection attributes: data access, secure access, normal access
		.user(`AXI_AXUSER_SHARED_NM_NC),  // User attributes: shared, normal memory, non-cacheable
		
		.strb(f2s_awh_strb),
		.status(f2s_awh_status),
		
		.aw_id(f2s_axi_awid),
		.aw_addr(f2s_axi_awaddr),
		.aw_len(f2s_axi_awlen),
		.aw_size(f2s_axi_awsize),
		.aw_burst(f2s_axi_awburst),
		.aw_lock(f2s_axi_awlock),
		.aw_cache(f2s_axi_awcache),
		.aw_prot(f2s_axi_awprot),
		.aw_user(f2s_axi_awuser),
		.aw_valid(f2s_axi_awvalid),
		.aw_ready(f2s_axi_awready),
		.w_id(f2s_axi_wid),
		.w_data(f2s_axi_wdata),
		.w_strb(f2s_axi_wstrb),
		.w_last(f2s_axi_wlast),
		.w_valid(f2s_axi_wvalid),
		.w_ready(f2s_axi_wready),
		.b_id(f2s_axi_bid),
		.b_resp(f2s_axi_bresp),
		.b_valid(f2s_axi_bvalid),
		.b_ready(f2s_axi_bready)
	);
	
	// ============================================
	// AXI helper nets and registers for the master
	// ============================================
	
	// AXI helper reader signal wires
	reg                                                f2s_arh_enable_ram;
	reg  [F2S_ARH_ADDR_WIDTH-1:0]                      f2s_arh_addr_ram;
	wire [F2S_ARH_MAX_BURST_LEN*F2S_ARH_BUS_WIDTH-1:0] f2s_arh_data_ram;
	reg  [3:0]                                         f2s_arh_burst_len_ram;
	reg  [2:0]                                         f2s_arh_burst_size_ram;
	wire [1:0]                                         f2s_arh_status_ram;
	// AXI helper writer signal wires
	reg                                                f2s_awh_enable_ram;
	reg  [F2S_AWH_ADDR_WIDTH-1:0]                      f2s_awh_addr_ram;
	reg  [F2S_AWH_MAX_BURST_LEN*F2S_AWH_BUS_WIDTH-1:0] f2s_awh_data_ram;
	reg  [3:0]                                         f2s_awh_burst_len_ram;
	reg  [2:0]                                         f2s_awh_burst_size_ram;
	reg  [F2S_AWH_BUS_WIDTH/8-1:0]                     f2s_awh_strb_ram;
	wire [1:0]                                         f2s_awh_status_ram;
	
	// Connect with the helper
	assign f2s_arh_enable     = f2s_arh_enable_ram;
	assign f2s_arh_id         = 0;
	assign f2s_arh_addr       = f2s_arh_addr_ram;
	assign f2s_arh_data_ram   = f2s_arh_data;
	assign f2s_arh_burst_len  = f2s_arh_burst_len_ram;
	assign f2s_arh_burst_size = f2s_arh_burst_size_ram;
	assign f2s_arh_status_ram = f2s_arh_status;
	// Connect with the helper
	assign f2s_awh_enable     = f2s_awh_enable_ram;
	assign f2s_awh_id         = 0;
	assign f2s_awh_addr       = f2s_awh_addr_ram;
	assign f2s_awh_data       = f2s_awh_data_ram;
	assign f2s_awh_burst_len  = f2s_awh_burst_len_ram;
	assign f2s_awh_burst_size = f2s_awh_burst_size_ram;
	assign f2s_awh_strb       = f2s_awh_strb_ram;
	assign f2s_awh_status_ram = f2s_awh_status;
	
	// =========================================
	// Setup FPGA embedded memory as a Block RAM
	// =========================================
	
	// The Cyclone V SoCFPGA (5CSEBA6U23I7) has a total of 553 blocks of M10K
	// embedded memory, which gives a total memory of:
	// 553 * 10K = 553 * 10240 = 5662720 bits = 707840 bytes

	// To optimise the transfer, the embedded memory data width is set to:
	// M10K data width = AXI max burst length * AXI width
	// Since the max values of the F2S bridge are:
	// AXI burst length = 16 bursts
	// F2S bus width = 256 bits
	// This gives M10K data width as: 16 * 256 = 512 bytes
	
	// Memory usage with multiples of the max data width:
	// M10K_MEM_ADDR_WIDTH    M10K_MEM_DATA_WIDTH    Embedded block memory usage
	// (bits)                 (bits)                 (bytes)
	// -------------------------------------------------------------------------
	// 1                      16 * 256               2^1  * 512 = 1024
	// 2                      16 * 256               2^2  * 512 = 2048
	// 3                      16 * 256               2^3  * 512 = 4096
	// 4                      16 * 256               2^4  * 512 = 8192
	// 5                      16 * 256               2^5  * 512 = 16384
	// 6                      16 * 256               2^6  * 512 = 32768
	// 7                      16 * 256               2^7  * 512 = 65536
	// 8                      16 * 256               2^8  * 512 = 131072
	// 9                      16 * 256               2^9  * 512 = 262144
	// 10                     16 * 256               2^10 * 512 = 524288

	// User configurable parameters
	localparam M10K_MEM_ADDR_WIDTH = 10;  // Valid range: 1 to 10
	//localparam M10K_MEM_ADDR_WIDTH = 1;
	localparam M10K_MEM_DATA_WIDTH = F2S_MAX_BURST_LEN * F2S_BIT_BUS_WIDTH;
	
	// Calculated parameters
	localparam M10K_MEM_ADDR_LEN         = 2**M10K_MEM_ADDR_WIDTH;
	localparam M10K_MEM_DATA_WIDTH_BYTES = M10K_MEM_DATA_WIDTH / 8;
	localparam M10K_MEM_DATA_SIZE_BYTES  = M10K_MEM_DATA_WIDTH_BYTES * 2**M10K_MEM_ADDR_WIDTH;

	reg  [M10K_MEM_ADDR_WIDTH-1:0] mem_raddr;
	reg  [M10K_MEM_ADDR_WIDTH-1:0] mem_waddr;
	wire [M10K_MEM_DATA_WIDTH-1:0] mem_rdata;
	reg  [M10K_MEM_DATA_WIDTH-1:0] mem_wdata;
	reg                            mem_we;
	
	// FPGA embedded block memory
	m10k_mem #(
		.M10K_MEM_DATA_WIDTH(M10K_MEM_DATA_WIDTH),
		.M10K_MEM_ADDR_WIDTH(M10K_MEM_ADDR_WIDTH)
	) m10k_mem0(
		.wclk(pll0_clock0),
		.raddr(mem_raddr),
		.waddr(mem_waddr),
		.rdata(mem_rdata),
		.wdata(mem_wdata),
		.we(mem_we)
	);
	
	// =============================================================
	// State machine for copying FPGA embedded memory into HPS SDRAM
	// =============================================================

	reg         fpga_ready;
	reg         data_ready;
	reg         hps_ready_index;
	reg         irq_trigger;
	reg  [31:0] remain_len;
	wire [31:0] next_stream_addr;
	wire [31:0] next_remain_len;
	wire [3:0]  next_burst_len;
	
	reg [31:0] mem_wdata_width16_count;
	reg [15:0] mem_test_data;
	
	// ================
	// Continuous logic
	// ================
	
	// PIO are in viewpoint of the HPS so out = HPS output signal to FPGA, in = FPGA input signal to HPS
	assign pio_s0_rdy_in    = pio_s0_rdy_out;               // Loop back
	assign pio_s0_addr_in   = pio_s0_addr_out;              // Loop back
	assign pio_s0_len_in    = pio_s0_len_out;               // Loop back
	
	// Assign F2H interrupt receivers to triggers
	assign f2h_irq0         = { {31{1'b0}}, irq_trigger };  // Connect bit0 (IRQ ID 72) to PIO0 IRQ output signal, and the remaining IRQs to 0
	assign f2h_irq1         = 'b0;                          // Connect unused IRQs to 0
	
	// Note, I have not found a way to easily handle the AXI-3 autoincrement 4K (4096) boundary restriction, i.e. the autoincrement should not pass a 4K boundary
	// As a workaround, we will assume the starting address is always 4K aligned and each AXI transaction transfer length is less than 4K so that an AXI-3 transaction will not pass a boundary
	
	// Generate the next AXI write values
	assign next_stream_addr = (remain_len == 0) ? pio_s0_addr_out : f2s_awh_addr_ram + F2S_BYTE_BUS_WIDTH * (f2s_awh_burst_len_ram + 1);
	assign next_remain_len  = (remain_len == 0) ? pio_s0_len_out : remain_len - F2S_BYTE_BUS_WIDTH * (f2s_awh_burst_len_ram + 1);
	assign next_burst_len   = (next_remain_len >= F2S_BYTE_BUS_WIDTH * F2S_MAX_BURST_LEN) ? F2S_MAX_BURST_LEN - 1 : next_remain_len / F2S_BYTE_BUS_WIDTH - 1;
	
	// =============
	// Clocked logic
	// =============
	
	always @ (posedge pll0_clock0 or negedge master_reset_n) begin
		if(!master_reset_n) begin  // Is reset?
			f2s_arh_enable_ram <= 'b0;
			f2s_awh_enable_ram <= 'b0;
			f2s_awh_data_ram <= 'b0;
			f2s_awh_burst_size_ram <= F2S_BURST_SIZE;  // Transfer size of a burst
			f2s_awh_strb_ram <= F2S_WSTRB_SIZE;  // Write strobe
			
			mem_raddr <= 'b0;
			mem_waddr <= 'b0;
			mem_we <= 'b0;
			
			mem_wdata_width16_count <= 'b0;
			mem_test_data <= 'b0;
			
			fpga_ready <= 'b0;
			data_ready <= 'b0;
			hps_ready_index <= 'b0;
			irq_trigger <= 'b0;
			remain_len <= 'b0;
		end else begin
			// ====================================
			// Fills embedded memory with test data
			// ====================================
		
			if(data_ready == 0) begin
				// Put test data in embedded memory
				if(mem_we == 0) begin
						// Data
						mem_wdata[mem_wdata_width16_count*16 +: 16] <= mem_test_data;  // Body: 16-bit test data (a counter)
						mem_wdata_width16_count <= mem_wdata_width16_count + 1;
						mem_test_data <= mem_test_data + 1;
					
					// We write to the memory when we have a full width of memory data
					if((mem_wdata_width16_count + 1) * 2 >= M10K_MEM_DATA_WIDTH_BYTES) begin
						mem_we <= 1;
					end
				end
				
				// Check when data is ready
				if(mem_we == 1) begin
					mem_we <= 0;
					mem_waddr <= (mem_waddr + 1) % 2**M10K_MEM_ADDR_WIDTH;
					mem_wdata_width16_count <= 0;
					//mem_test_data <= 0;
					
					// No more space in the memory (the write address wrapped to zero)?
					if((mem_waddr + 1) % 2**M10K_MEM_ADDR_WIDTH == 0) begin
						data_ready <= 1;
					end
				end
			end
			
			// ==========================================================
			// Copies embedded memory (containing test data) to HPS SDRAM
			// ==========================================================
		
			// Wait for the HPS to assert the ready flag
			if(data_ready == 1 && fpga_ready == 0 && pio_s0_rdy_out[hps_ready_index] == 1) begin
				remain_len <= next_remain_len;
				
				f2s_awh_addr_ram <= next_stream_addr;
				f2s_awh_burst_len_ram <= next_burst_len;
				
				fpga_ready <= 1;
			end
	
			// Write data from embedded memory to HPS SDRAM using the FPGA-to-HPS SDRAM interface
			// Note, access to the SDRAM is not cache coherent using this data bus
			if(remain_len) begin
				case(f2s_awh_status_ram)
					// Start
					0: begin
						f2s_awh_data_ram <= mem_rdata;
						f2s_awh_enable_ram <= 1;
					end
					// Status success?
					2: begin
						f2s_awh_addr_ram <= next_stream_addr;
						f2s_awh_burst_len_ram <= next_burst_len;
						mem_raddr <= (mem_raddr + 1) % 2**M10K_MEM_ADDR_WIDTH;
						remain_len <= next_remain_len;
						
						if(next_remain_len == 0) begin  // Is the HPS SDRAM sample memory filled?
							f2s_awh_enable_ram <= 0;
							irq_trigger <= 1;  // Assert trigger to generate an IRQ
						end
					end
				endcase
			end
			
			// Wait for the HPS to deassert the ready flag (i.e. reset it)
			if(fpga_ready == 1 && pio_s0_rdy_out[hps_ready_index] == 0) begin
				irq_trigger <= 0;  // Deassert the IRQ trigger
				fpga_ready <= 0;
				hps_ready_index <= (hps_ready_index + 1) % 2;  // Increment the flag index (a 2-bit circular buffer index)
			end
		end
	end
endmodule
