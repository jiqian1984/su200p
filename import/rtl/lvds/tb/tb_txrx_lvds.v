//-----------------------------------------------------------------------------
// Title    : LVDS TXRX Test Bench
// Project  : LVDS
// Author   : Author:
// Revision : Revision: 1.0
// Date     : Date:
//-----------------------------------------------------------------------------
// Description  : Test bench of moudle_txrx_lvds
//-----------------------------------------------------------------------------
`timescale 1ns / 1ps
module tb_txrx_lvds();
//-----------------------------------------------------------------------------
// Dump fsdb file
//-----------------------------------------------------------------------------

glbl glbl();

//define vcs_dump_file("tb_txrx_lvds.fsdb");
`ifdef VCS
initial
begin
    $fsdbDumpoff;
    #100; // Wait before starting wave dump
    $fsdbDumpon;
    $fsdbDumpfile("tb_txrx_lvds.fsdb");
    $fsdbDumpvars(0, tb_txrx_lvds);
end
`endif 

always #10000 $display("Simulate time == %0dus",$time/1000);

// Clock generation - 300 MHz reference clock (3.33ns period)
reg refclk = 1'b0;
always #1.667 refclk = ~refclk;
wire refclk_p;
wire refclk_n;


// Reset signals
wire tx_reset ;
wire rx_reset ;

// LVDS differential signals - TX to RX loopback
wire clkout1_p, clkout1_n;
wire [4:0] dataout1_p, dataout1_n;
wire clkout2_p, clkout2_n;
wire [4:0] dataout2_p, dataout2_n;

wire clkin1_p;
wire clkin1_n;

wire [4:0] datain1_p;
wire [4:0] datain1_n;

wire clkin2_p;
wire clkin2_n;
wire [4:0] datain2_p;
wire [4:0] datain2_n;

// Parallel interface signals
wire tx_px_clk;
wire [34:0] tx1_px_data;
wire [34:0] tx2_px_data;

wire rx1_px_clk;
wire [34:0] rx1_px_data;
wire rx1_px_ready;
wire rx2_px_clk;
wire [34:0] rx2_px_data;
wire rx2_px_ready;

//--------------
// Differential clock output
assign  refclk_p = refclk;
assign  refclk_n = ~refclk;


assign clkin1_p = clkout1_p;
assign clkin1_n = clkout1_n;

assign datain1_p = dataout1_p;
assign datain1_n = dataout1_n;


assign clkin2_p = clkout2_p;
assign clkin2_n = clkout2_n;
assign datain2_p = dataout2_p;
assign datain2_n = dataout2_n;
//---------------------------------------------------------------
// DUT Instantiation
//-----------------------------------------------------------------------------
moudle_txrx_lvds #(
   .SIM_DEVICE("ULTRASCALE"),
   .TX_DATA_WIDTH(5),
   .RX_DATA_WIDTH(5),
   .NUM_CHANNELS(2),
   .NUM_CLOCKS(2),
   .CLK_PATTERN(7'b1100011)
) u_moudle_txrx_lvds (
   .refclk_p      (refclk_p),
   .refclk_n      (refclk_n),
   .tx_reset      (tx_reset),
   .rx_reset      (rx_reset),
   // TX Outputs
   .clkout1_p     (clkout1_p),
   .clkout1_n     (clkout1_n),
   .dataout1_p    (dataout1_p),
   .dataout1_n    (dataout1_n),
   .clkout2_p     (clkout2_p),
   .clkout2_n     (clkout2_n),
   .dataout2_p    (dataout2_p),
   .dataout2_n    (dataout2_n),
   // RX Inputs (looped back from TX)
   .clkin1_p      (clkin1_p),
   .clkin1_n      (clkin1_n),
   .datain1_p     (datain1_p),
   .datain1_n     (datain1_n),
   .clkin2_p      (clkin2_p),
   .clkin2_n      (clkin2_n),
   .datain2_p     (datain2_p),
   .datain2_n     (datain2_n),
   // Parallel TX Interface
   .tx_px_clk     (tx_px_clk),
   .tx1_px_data   (tx1_px_data),
   .tx2_px_data   (tx2_px_data),
   // Parallel RX Interface
   .rx1_px_clk    (rx1_px_clk),
   .rx1_px_data   (rx1_px_data),
   .rx1_px_ready  (rx1_px_ready),
   .rx2_px_clk    (rx2_px_clk),
   .rx2_px_data   (rx2_px_data),
   .rx2_px_ready  (rx2_px_ready)
);

//-----------------------------------------------------------------------------
// Test Program Instantiation
//-----------------------------------------------------------------------------
test_txrx_lvds u_test_txrx_lvds (
	// Clock and Reset
	.refclk_p      (refclk_p),
	.refclk_n      (refclk_n),
	.tx_reset      (tx_reset),
	.rx_reset      (rx_reset),
	// TX Parallel Interface
	.tx_px_clk     (tx_px_clk),
	.tx1_px_data   (tx1_px_data),
	.tx2_px_data   (tx2_px_data),
	// RX Parallel Interface
	.rx1_px_clk    (rx1_px_clk),
	.rx1_px_data   (rx1_px_data),
	.rx1_px_ready  (rx1_px_ready),
	.rx2_px_clk    (rx2_px_clk),
	.rx2_px_data   (rx2_px_data),
	.rx2_px_ready  (rx2_px_ready)
);

endmodule
