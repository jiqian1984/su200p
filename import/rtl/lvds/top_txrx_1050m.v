//////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2017 Xilinx, Inc.
// This design is confidential and proprietary of Xilinx, All Rights Reserved.
//////////////////////////////////////////////////////////////////////////////
//   ____  ____
//  /   /\/   /
// /___/  \  /   Vendor: Xilinx
// \   \   \/    Version: 1.3
//  \   \        Filename: top_txrx_example.v
//  /   /        Date Last Modified:  06/06/2022
// /___/   /\    Date Created: 02/27/2017
// \   \  /  \
//  \___\/\___\
//
// Device    :  Ultrascale
//
// Purpose   :  Top level example with two transmit and two receiver channels
//              targetted to the KCU105 LPC interface using the FMC-XM107 
//              loopback card.
//
// Parameters:  None
//
// Reference:	XAPPxxx
//
// Revision History:
//    Rev 1.3 - Add SIM_DEVICE to allow code to work with ULTRASCALE_PLUS (jimt)
//    Rev 1.1 - CR 993494 fixes (jimt)
//    Rev 1.0 - Initial Release (knagara)
//    Rev 0.9 - Early Access Release (mcgett)
//////////////////////////////////////////////////////////////////////////////
//
//  Disclaimer:
//
// This disclaimer is not a license and does not grant any rights to the
// materials distributed herewith. Except as otherwise provided in a valid
// license issued to you by Xilinx, and to the maximum extent permitted by
// applicable law:
//
// (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND WITH ALL FAULTS, AND
// XILINX HEREBY DISCLAIMS ALL WARRANTIES AND CONDITIONS, EXPRESS, IMPLIED, OR
// STATUTORY, INCLUDING BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY,
// NON-INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and (2) Xilinx
// shall not be liable (whether in contract or tort, including negligence, or
// under any other theory of liability) for any loss or damage of any kind or
// nature related to, arising under or in connection with these materials,
// including for any direct, or any indirect, special, incidental, or
// consequential loss or damage (including loss of data, profits, goodwill, or
// any type of loss or damage suffered as a result of any action brought by a
// third party) even if such damage or loss was reasonably foreseeable or
// Xilinx had been advised of the possibility of the same.
//
// Critical Applications:
//
// Xilinx products are not designed or intended to be fail-safe, or for use in
// any application requiring fail-safe performance, such as life-support or
// safety devices or systems, class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any other applications
// that could lead to death, personal injury, or severe property or
// environmental damage (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and liability of any use of
// Xilinx products in Critical Applications, subject only to applicable laws
// and regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS PART OF THIS FILE
// AT ALL TIMES.
//
//////////////////////////////////////////////////////////////////////////////

`timescale 1ps/1ps

module top_txrx_example (
   input        refclk_p,  refclk_n,     // lvds reference clock
   input        tx_reset,                // reset (active high)
   input        rx_reset,                // reset (active high)
   // Transmitters
   output       clkout1_p,  clkout1_n,   // lvds channel 1 clock output
   output [4:0] dataout1_p, dataout1_n,  // lvds channel 1 data outputs
   output       clkout2_p,  clkout2_n,   // lvds channel 2 clock output
   output [4:0] dataout2_p, dataout2_n,  // lvds channel 2 data outputs
   // Receivers
   input        clkin1_p,  clkin1_n,     // lvds channel 1 clock input
   input  [4:0] datain1_p, datain1_n,    // lvds channel 1 data inputs
   input        clkin2_p,  clkin2_n,     // lvds channel 2 clock input
   input  [4:0] datain2_p, datain2_n,    // lvds channel 2 data inputs
   // Status
   output reg   rx1_match, rx1_match_lt,
   output reg   rx2_match, rx2_match_lt
) ;  
localparam   SIM_DEVICE   = "ULTRASCALE" ; // Set for the family <ULTRASCALE | 

// Wires

wire            refclk_i;         
wire            clk300_g;   
wire            clk150_g;   

wire            tx_px_clk;
wire            tx_clkdiv2;
wire            tx_clkdiv4;
wire            tx_locked;

reg      [3:0]  tx_px_locked;
wire            tx_px_reset;
wire            tx_reset_int;

reg     [34:0]  tx_px_data;

wire            idly_reset_int;

wire            rx_idelay_rdy;
wire            rx_reset_int;

wire            rx1_cmt_locked;
wire            rx1_px_clk;
wire            rx1_px_ready;
reg      [7:0]  rx1_px_count;
wire    [34:0]  rx1_px_data;            
reg     [34:0]  rx1_px_last;            

wire            rx2_cmt_locked;
wire            rx2_px_clk;
wire            rx2_px_ready;
reg      [7:0]  rx2_px_count;
wire    [34:0]  rx2_px_data;            
reg     [34:0]  rx2_px_last;            

//-------------------------------------------------------------------------------
//
// 300 MHz and 150 MHz clock generation for transmit and receive
// interfaces
// 
IBUFDS # (
      .DIFF_TERM("FALSE") 
   )
   ib_refclk (
      .I                (refclk_p),
      .IB               (refclk_n),
      .O                (refclk_i)
   );

//
//  Idelay reference clock global buffer
//
BUFG bg_ref (
    .I             (refclk_i),
    .O             (clk300_g)) ;

//
//  Divide by two BUFG for 150 MHz source for transmit interfaces
//
BUFGCE_DIV # (
      .BUFGCE_DIVIDE(2)
    )
    bg_150 (
    .I             (refclk_i),
    .CLR           (1'b0),
    .CE            (1'b1),
    .O             (clk150_g)) ;

//-------------------------------------------------------------------------------
// 
// Begin two channel transmit example 
//

//
// Transmit reset Logic
//
assign tx_reset_int   = tx_reset;

//
// Transmit Clock Generator, only one required per design source
// all transmit interfaces
//
tx_clkgen_7to1 #(
        .CLKIN_PERIOD  ( 6.666),   // Reference clock period
        .USE_PLL       ("FALSE")   // Use MMCM instead of PLL
     )
     tx_clkgen (
        .clkin       (clk150_g),
        .reset       (tx_reset_int),
        .px_clk      (tx_px_clk),   // Transmit pixel clock for internal logic
        .tx_clkdiv2  (tx_clkdiv2),  // Transmit clock at 1/2 data rate
        .tx_clkdiv4  (tx_clkdiv4),  // Transmit clock at 1/4 data rate
        .cmt_locked  (tx_locked)
     );

//
// Synchronize locked status to TX px_clk domain
//
always @ (posedge tx_px_clk or negedge tx_locked) //cr993494
begin
    if (!tx_locked)
       tx_px_locked <= 4'b000;
    else
       tx_px_locked <= {1'b1,tx_px_locked[3:1]};
end
assign tx_px_reset = !tx_px_locked[0];

//
// TX Channel 1
//
tx_channel_7to1 #(
      .LINES          (5),           // 5 Data Lines
      .DATA_FORMAT    ("PER_LINE"),  // PER_CLOCK or PER_LINE data formatting
      .CLK_PATTERN    (7'b1100011),  // Clock bit pattern
      .TX_SWAP_MASK   (5'h0),        // Output inversion for P/N swap 0=Non Inverted, 1=Inverted
      .SIM_DEVICE    (SIM_DEVICE)
   )
   tx_channel1 (
      .px_data        (tx_px_data),
      .px_reset       (tx_px_reset),
      .px_clk         (tx_px_clk),
      .tx_clkdiv2     (tx_clkdiv2),
      .tx_clkdiv4     (tx_clkdiv4),
      .tx_clk_p       (clkout1_p),
      .tx_clk_n       (clkout1_n),
      .tx_out_p       (dataout1_p),
      .tx_out_n       (dataout1_n)
   );

//
// TX Channel 2
//
tx_channel_7to1 #(
      .LINES          (5),            // 5 Data Lines
      .DATA_FORMAT    ("PER_LINE"),   // PER_CLOCK or PER_LINE data formatting
      .CLK_PATTERN    (7'b1100011),   // Clock bit pattern
      .TX_SWAP_MASK   (5'h0),         // Output inversion for P/N swap 0=Non Inverted, 1=Inverted
      .SIM_DEVICE    (SIM_DEVICE)
   )
   tx_channel2 (
      .px_data        (tx_px_data),
      .px_reset       (tx_px_reset),
      .px_clk         (tx_px_clk),
      .tx_clkdiv2     (tx_clkdiv2),
      .tx_clkdiv4     (tx_clkdiv4),
      .tx_clk_p       (clkout2_p),
      .tx_clk_n       (clkout2_n),
      .tx_out_p       (dataout2_p),
      .tx_out_n       (dataout2_n)
   );

//
// Transmit Data Generation
//
always @ (posedge tx_px_clk)
begin
   if (tx_px_reset) begin
      tx_px_data[ 6:0 ] <= 7'h01;
      tx_px_data[13:7 ] <= 7'h02;
      tx_px_data[20:14] <= 7'h03;
      tx_px_data[27:21] <= 7'h04;
      tx_px_data[34:28] <= 7'h05;
   end
   else begin
      tx_px_data[ 6:0 ] <= tx_px_data[ 6:0 ] + 1'b1;
      tx_px_data[13:7 ] <= tx_px_data[13:7 ] + 1'b1;
      tx_px_data[20:14] <= tx_px_data[20:14] + 1'b1;
      tx_px_data[27:21] <= tx_px_data[27:21] + 1'b1;
      tx_px_data[34:28] <= tx_px_data[34:28] + 1'b1;
   end
end



//-------------------------------------------------------------------------------
// 
// Begin two channel transmit example
//

//
// Receiver reset Logic
//
assign rx_reset_int   = rx_reset     | !tx_locked;
assign idly_reset_int = rx_reset_int | !rx1_cmt_locked | !rx2_cmt_locked;

//
//  Idelay control block
//
IDELAYCTRL #( // Instantiate input delay control block
      .SIM_DEVICE ("ULTRASCALE"))
   icontrol (
      .REFCLK (clk300_g),
      .RST    (idly_reset_int),
      .RDY    (rx_idelay_rdy)
   );

//
// Receiver 1 - 5 Channels @ 1050 Mbps
//
rx_channel_1to7 # (
      .LINES        (5),            // Number of data lines
      .CLKIN_PERIOD ( 6.666),       // Clock period (ns) of input clock on clkin_p
      .REF_FREQ     (300.0),        // Reference frequency used by idelay controller
      .DIFF_TERM    ("TRUE"),       // Enable internal differential termination
      .USE_PLL      ("FALSE"),      // Enable PLL use rather than MMCM
      .DATA_FORMAT  ("PER_LINE"),   // PER_CLOCK or PER_LINE data formatting
      .CLK_PATTERN  (7'b1100011),   // Clock bit pattern
      .RX_SWAP_MASK (16'b0),        // Allows P/N inputs to be invered to ease PCB routing
      .SIM_DEVICE    (SIM_DEVICE)
   )
   rx_channel1 (
      .clkin_p      (clkin1_p),      // Input from LVDS clock receiver pin
      .clkin_n      (clkin1_n),      // Input from LVDS clock receiver pin
      .datain_p     (datain1_p),     // Input from LVDS data pins
      .datain_n     (datain1_n),     // Input from LVDS data pins
      .reset        (rx_reset_int),  // Reset line
      .cmt_locked   (rx1_cmt_locked),// PLL/MMCM locked
      .idelay_rdy   (rx_idelay_rdy), // Input delay control ready
      .px_clk       (rx1_px_clk),    // Pixel clock output
      .px_data      (rx1_px_data),   // Pixel data
      .px_ready     (rx1_px_ready)   // Pixel data ready
   );

//
// Receiver 2 - 5 Channels @ 1050 Mbps
//
rx_channel_1to7 # (
      .LINES        (5),            // Number of data lines
      .CLKIN_PERIOD ( 6.666),       // Clock period (ns) of input clock on clkin_p
      .REF_FREQ     (300.0),        // Reference frequency used by idelay controller
      .DIFF_TERM    ("TRUE"),       // Enable internal differential termination
      .USE_PLL      ("TRUE"),       // Enable PLL use rather than MMCM
      .DATA_FORMAT  ("PER_LINE"),   // PER_CLOCK or PER_LINE data formatting
      .CLK_PATTERN  (7'b1100011),   // Clock bit pattern
      .RX_SWAP_MASK (16'b0),        // Allows P/N inputs to be invered to ease PCB routing
      .SIM_DEVICE    (SIM_DEVICE)
   )
   rx_channel2 (
      .clkin_p      (clkin2_p),      // Input from LVDS clock receiver pin
      .clkin_n      (clkin2_n),      // Input from LVDS clock receiver pin
      .datain_p     (datain2_p),     // Input from LVDS data pins 
      .datain_n     (datain2_n),     // Input from LVDS data pins 
      .reset        (rx_reset_int),  // Reset line
      .cmt_locked   (rx2_cmt_locked),// PLL/MMCM locked
      .idelay_rdy   (rx_idelay_rdy), // Input delay control ready
      .px_clk       (rx2_px_clk),    // Pixel clock output
      .px_data      (rx2_px_data),   // Pixel data
      .px_ready     (rx2_px_ready)   // Pixel data ready
   );
   
//
// Receiver 1 - Data checking per pixel clock
//
always @(posedge rx1_px_clk or negedge rx1_px_ready)
begin
   rx1_px_last <= rx1_px_data;
   if (!rx1_px_ready) begin
         rx1_match <= 1'b0;
   end
   else if ((rx1_px_data[ 6:0 ]  == rx1_px_last[ 6:0 ] + 1'b1 ) &&
            (rx1_px_data[13:7 ]  == rx1_px_last[13:7 ] + 1'b1 ) &&
            (rx1_px_data[20:14]  == rx1_px_last[20:14] + 1'b1 ) &&
            (rx1_px_data[27:21]  == rx1_px_last[27:21] + 1'b1 ) &&
            (rx1_px_data[34:28]  == rx1_px_last[34:28] + 1'b1 )) begin
      rx1_match <= 1'b1;
   end
   else begin 
      rx1_match <= 1'b0;
   end
end

//
// Receiver 1 - Long term monitor
//
always @(posedge rx1_px_clk or negedge rx1_px_ready) 
begin
   if (!rx1_px_ready) begin
      rx1_px_count <= 8'b0;
      rx1_match_lt <= 1'b0;
   end
   else if (rx1_px_count != 8'hff) begin
      rx1_px_count <= rx1_px_count + 1'b1;
      rx1_match_lt <= rx1_match;
   end
   else begin
      if (!rx1_match) rx1_match_lt <= 1'b0;
   end
end

//
// Receiver 2 - Data checking per pixel clock
//
always @(posedge rx2_px_clk or negedge rx2_px_ready)
begin
   rx2_px_last <= rx2_px_data;
   if (!rx2_px_ready) begin
         rx2_match <= 1'b0;
   end
   else if ((rx2_px_data[ 6:0 ]  == rx2_px_last[ 6:0 ] + 1'b1 ) &&
            (rx2_px_data[13:7 ]  == rx2_px_last[13:7 ] + 1'b1 ) &&
            (rx2_px_data[20:14]  == rx2_px_last[20:14] + 1'b1 ) &&
            (rx2_px_data[27:21]  == rx2_px_last[27:21] + 1'b1 ) &&
            (rx2_px_data[34:28]  == rx2_px_last[34:28] + 1'b1 )) begin
      rx2_match <= 1'b1;
   end
   else begin 
      rx2_match <= 1'b0;
   end
end

//
// Receiver 2 - Long term monitor
//
always @(posedge rx2_px_clk or negedge rx2_px_ready) 
begin
   if (!rx2_px_ready) begin    
      rx2_px_count <= 8'b0;
      rx2_match_lt <= 1'b0;
   end
   else if (rx2_px_count != 8'hff) begin
      rx2_px_count <= rx2_px_count + 1'b1;
      rx2_match_lt <= rx2_match;
   end
   else begin
      if (!rx2_match) rx2_match_lt <= 1'b0;
   end
end

endmodule
