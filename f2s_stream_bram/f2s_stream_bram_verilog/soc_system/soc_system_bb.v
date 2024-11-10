
module soc_system (
	clk_clk,
	clock_bridge_0_out_clk_clk,
	f2h_sdram0_data_araddr,
	f2h_sdram0_data_arlen,
	f2h_sdram0_data_arid,
	f2h_sdram0_data_arsize,
	f2h_sdram0_data_arburst,
	f2h_sdram0_data_arlock,
	f2h_sdram0_data_arprot,
	f2h_sdram0_data_arvalid,
	f2h_sdram0_data_arcache,
	f2h_sdram0_data_awaddr,
	f2h_sdram0_data_awlen,
	f2h_sdram0_data_awid,
	f2h_sdram0_data_awsize,
	f2h_sdram0_data_awburst,
	f2h_sdram0_data_awlock,
	f2h_sdram0_data_awprot,
	f2h_sdram0_data_awvalid,
	f2h_sdram0_data_awcache,
	f2h_sdram0_data_bresp,
	f2h_sdram0_data_bid,
	f2h_sdram0_data_bvalid,
	f2h_sdram0_data_bready,
	f2h_sdram0_data_arready,
	f2h_sdram0_data_awready,
	f2h_sdram0_data_rready,
	f2h_sdram0_data_rdata,
	f2h_sdram0_data_rresp,
	f2h_sdram0_data_rlast,
	f2h_sdram0_data_rid,
	f2h_sdram0_data_rvalid,
	f2h_sdram0_data_wlast,
	f2h_sdram0_data_wvalid,
	f2h_sdram0_data_wdata,
	f2h_sdram0_data_wstrb,
	f2h_sdram0_data_wready,
	f2h_sdram0_data_wid,
	hps_0_f2h_irq0_irq,
	hps_0_f2h_irq1_irq,
	hps_0_h2f_reset_reset_n,
	hps_io_hps_io_emac1_inst_TX_CLK,
	hps_io_hps_io_emac1_inst_TXD0,
	hps_io_hps_io_emac1_inst_TXD1,
	hps_io_hps_io_emac1_inst_TXD2,
	hps_io_hps_io_emac1_inst_TXD3,
	hps_io_hps_io_emac1_inst_RXD0,
	hps_io_hps_io_emac1_inst_MDIO,
	hps_io_hps_io_emac1_inst_MDC,
	hps_io_hps_io_emac1_inst_RX_CTL,
	hps_io_hps_io_emac1_inst_TX_CTL,
	hps_io_hps_io_emac1_inst_RX_CLK,
	hps_io_hps_io_emac1_inst_RXD1,
	hps_io_hps_io_emac1_inst_RXD2,
	hps_io_hps_io_emac1_inst_RXD3,
	hps_io_hps_io_sdio_inst_CMD,
	hps_io_hps_io_sdio_inst_D0,
	hps_io_hps_io_sdio_inst_D1,
	hps_io_hps_io_sdio_inst_CLK,
	hps_io_hps_io_sdio_inst_D2,
	hps_io_hps_io_sdio_inst_D3,
	hps_io_hps_io_usb1_inst_D0,
	hps_io_hps_io_usb1_inst_D1,
	hps_io_hps_io_usb1_inst_D2,
	hps_io_hps_io_usb1_inst_D3,
	hps_io_hps_io_usb1_inst_D4,
	hps_io_hps_io_usb1_inst_D5,
	hps_io_hps_io_usb1_inst_D6,
	hps_io_hps_io_usb1_inst_D7,
	hps_io_hps_io_usb1_inst_CLK,
	hps_io_hps_io_usb1_inst_STP,
	hps_io_hps_io_usb1_inst_DIR,
	hps_io_hps_io_usb1_inst_NXT,
	hps_io_hps_io_spim1_inst_CLK,
	hps_io_hps_io_spim1_inst_MOSI,
	hps_io_hps_io_spim1_inst_MISO,
	hps_io_hps_io_spim1_inst_SS0,
	hps_io_hps_io_uart0_inst_RX,
	hps_io_hps_io_uart0_inst_TX,
	hps_io_hps_io_i2c0_inst_SDA,
	hps_io_hps_io_i2c0_inst_SCL,
	hps_io_hps_io_i2c1_inst_SDA,
	hps_io_hps_io_i2c1_inst_SCL,
	hps_io_hps_io_gpio_inst_GPIO09,
	hps_io_hps_io_gpio_inst_GPIO35,
	hps_io_hps_io_gpio_inst_GPIO53,
	hps_io_hps_io_gpio_inst_GPIO54,
	hps_io_hps_io_gpio_inst_GPIO61,
	memory_mem_a,
	memory_mem_ba,
	memory_mem_ck,
	memory_mem_ck_n,
	memory_mem_cke,
	memory_mem_cs_n,
	memory_mem_ras_n,
	memory_mem_cas_n,
	memory_mem_we_n,
	memory_mem_reset_n,
	memory_mem_dq,
	memory_mem_dqs,
	memory_mem_dqs_n,
	memory_mem_odt,
	memory_mem_dm,
	memory_oct_rzqin,
	pio_s0_addr_external_connection_in_port,
	pio_s0_addr_external_connection_out_port,
	pio_s0_len_external_connection_in_port,
	pio_s0_len_external_connection_out_port,
	reset_reset_n,
	pio_s0_rdy_external_connection_in_port,
	pio_s0_rdy_external_connection_out_port);	

	input		clk_clk;
	output		clock_bridge_0_out_clk_clk;
	input	[31:0]	f2h_sdram0_data_araddr;
	input	[3:0]	f2h_sdram0_data_arlen;
	input	[7:0]	f2h_sdram0_data_arid;
	input	[2:0]	f2h_sdram0_data_arsize;
	input	[1:0]	f2h_sdram0_data_arburst;
	input	[1:0]	f2h_sdram0_data_arlock;
	input	[2:0]	f2h_sdram0_data_arprot;
	input		f2h_sdram0_data_arvalid;
	input	[3:0]	f2h_sdram0_data_arcache;
	input	[31:0]	f2h_sdram0_data_awaddr;
	input	[3:0]	f2h_sdram0_data_awlen;
	input	[7:0]	f2h_sdram0_data_awid;
	input	[2:0]	f2h_sdram0_data_awsize;
	input	[1:0]	f2h_sdram0_data_awburst;
	input	[1:0]	f2h_sdram0_data_awlock;
	input	[2:0]	f2h_sdram0_data_awprot;
	input		f2h_sdram0_data_awvalid;
	input	[3:0]	f2h_sdram0_data_awcache;
	output	[1:0]	f2h_sdram0_data_bresp;
	output	[7:0]	f2h_sdram0_data_bid;
	output		f2h_sdram0_data_bvalid;
	input		f2h_sdram0_data_bready;
	output		f2h_sdram0_data_arready;
	output		f2h_sdram0_data_awready;
	input		f2h_sdram0_data_rready;
	output	[255:0]	f2h_sdram0_data_rdata;
	output	[1:0]	f2h_sdram0_data_rresp;
	output		f2h_sdram0_data_rlast;
	output	[7:0]	f2h_sdram0_data_rid;
	output		f2h_sdram0_data_rvalid;
	input		f2h_sdram0_data_wlast;
	input		f2h_sdram0_data_wvalid;
	input	[255:0]	f2h_sdram0_data_wdata;
	input	[31:0]	f2h_sdram0_data_wstrb;
	output		f2h_sdram0_data_wready;
	input	[7:0]	f2h_sdram0_data_wid;
	input	[31:0]	hps_0_f2h_irq0_irq;
	input	[31:0]	hps_0_f2h_irq1_irq;
	output		hps_0_h2f_reset_reset_n;
	output		hps_io_hps_io_emac1_inst_TX_CLK;
	output		hps_io_hps_io_emac1_inst_TXD0;
	output		hps_io_hps_io_emac1_inst_TXD1;
	output		hps_io_hps_io_emac1_inst_TXD2;
	output		hps_io_hps_io_emac1_inst_TXD3;
	input		hps_io_hps_io_emac1_inst_RXD0;
	inout		hps_io_hps_io_emac1_inst_MDIO;
	output		hps_io_hps_io_emac1_inst_MDC;
	input		hps_io_hps_io_emac1_inst_RX_CTL;
	output		hps_io_hps_io_emac1_inst_TX_CTL;
	input		hps_io_hps_io_emac1_inst_RX_CLK;
	input		hps_io_hps_io_emac1_inst_RXD1;
	input		hps_io_hps_io_emac1_inst_RXD2;
	input		hps_io_hps_io_emac1_inst_RXD3;
	inout		hps_io_hps_io_sdio_inst_CMD;
	inout		hps_io_hps_io_sdio_inst_D0;
	inout		hps_io_hps_io_sdio_inst_D1;
	output		hps_io_hps_io_sdio_inst_CLK;
	inout		hps_io_hps_io_sdio_inst_D2;
	inout		hps_io_hps_io_sdio_inst_D3;
	inout		hps_io_hps_io_usb1_inst_D0;
	inout		hps_io_hps_io_usb1_inst_D1;
	inout		hps_io_hps_io_usb1_inst_D2;
	inout		hps_io_hps_io_usb1_inst_D3;
	inout		hps_io_hps_io_usb1_inst_D4;
	inout		hps_io_hps_io_usb1_inst_D5;
	inout		hps_io_hps_io_usb1_inst_D6;
	inout		hps_io_hps_io_usb1_inst_D7;
	input		hps_io_hps_io_usb1_inst_CLK;
	output		hps_io_hps_io_usb1_inst_STP;
	input		hps_io_hps_io_usb1_inst_DIR;
	input		hps_io_hps_io_usb1_inst_NXT;
	output		hps_io_hps_io_spim1_inst_CLK;
	output		hps_io_hps_io_spim1_inst_MOSI;
	input		hps_io_hps_io_spim1_inst_MISO;
	output		hps_io_hps_io_spim1_inst_SS0;
	input		hps_io_hps_io_uart0_inst_RX;
	output		hps_io_hps_io_uart0_inst_TX;
	inout		hps_io_hps_io_i2c0_inst_SDA;
	inout		hps_io_hps_io_i2c0_inst_SCL;
	inout		hps_io_hps_io_i2c1_inst_SDA;
	inout		hps_io_hps_io_i2c1_inst_SCL;
	inout		hps_io_hps_io_gpio_inst_GPIO09;
	inout		hps_io_hps_io_gpio_inst_GPIO35;
	inout		hps_io_hps_io_gpio_inst_GPIO53;
	inout		hps_io_hps_io_gpio_inst_GPIO54;
	inout		hps_io_hps_io_gpio_inst_GPIO61;
	output	[14:0]	memory_mem_a;
	output	[2:0]	memory_mem_ba;
	output		memory_mem_ck;
	output		memory_mem_ck_n;
	output		memory_mem_cke;
	output		memory_mem_cs_n;
	output		memory_mem_ras_n;
	output		memory_mem_cas_n;
	output		memory_mem_we_n;
	output		memory_mem_reset_n;
	inout	[31:0]	memory_mem_dq;
	inout	[3:0]	memory_mem_dqs;
	inout	[3:0]	memory_mem_dqs_n;
	output		memory_mem_odt;
	output	[3:0]	memory_mem_dm;
	input		memory_oct_rzqin;
	input	[31:0]	pio_s0_addr_external_connection_in_port;
	output	[31:0]	pio_s0_addr_external_connection_out_port;
	input	[31:0]	pio_s0_len_external_connection_in_port;
	output	[31:0]	pio_s0_len_external_connection_out_port;
	input		reset_reset_n;
	input	[31:0]	pio_s0_rdy_external_connection_in_port;
	output	[31:0]	pio_s0_rdy_external_connection_out_port;
endmodule
