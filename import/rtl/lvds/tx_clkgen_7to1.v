//////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2017 Xilinx, Inc.
// This design is confidential and proprietary of Xilinx, All Rights Reserved.
//////////////////////////////////////////////////////////////////////////////
//   ____  ____
//  /   /\/   /
// /___/  \  /   Vendor: Xilinx
// \   \   \/    Version: 1.0
//  \   \        Filename: tx_clkgen_7to1.v
//  /   /        Date Last Modified:  04/03/2017
// /___/   /\    Date Created: 02/27/2017
// \   \  /  \
//  \___\/\___\
//
// Device    :  Ultrascale
//
// Purpose   :  Transmit clock generation for 1-to-7 serialization
//
// Parameters:  CLKIN_PERIOD - Real - Default = 6.600
//                 - Period in nanoseconds of the transmit clock clkin
//                 - Range = 6.364 to 17.500
//              USE_PLL - String - Default = "FALSE"
//                 - Selects either PLL or MMCM for clocking
//                 - Range = "FALSE" or "TRUE"
//
// Reference:	XAPPxxx
//
// Revision History:
//    Rev 1.0 - Initial Release (knagara)
//    Rev 0.9 - Early Access Release (mcgett)
//
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

module tx_clkgen_7to1 # (
         parameter real CLKIN_PERIOD = 6.600,  // Clock period (ns) of transmit clock
         parameter      USE_PLL      = "FALSE" // Selects either PLL or MMCM for clocking
     )
     (
         input    clkin,                       // Transmit pixel clock
         input    reset,                       // Asynchronous interface reset 
         output   px_clk,                      // Pixel clock 
         output   tx_clkdiv2,                  // Transmit Clock divide by two  (px_clk * 3.50)
         output   tx_clkdiv4,                  // Transmit Clock divide by four (px_clk * 1.75)
         output   cmt_locked                   // PLL/MMCM locked output
     );

//
// Set VCO multiplier for PLL/MMCM 
//  2  - if clock_period is greater than 600 MHz/7
//  1  - if clock period is <= 600 MHz/7 
//
localparam VCO_MULTIPLIER = (CLKIN_PERIOD >11.666) ? 2 : 1; 

wire   px_pllmmcm; 
wire   tx_pllmmcm_div2; 

//
// Instantiate PLL or MMCM
//
generate
if (USE_PLL == "FALSE") begin                   // use an MMCM
   MMCME3_BASE # (
         .CLKIN1_PERIOD      (CLKIN_PERIOD),
         .BANDWIDTH          ("OPTIMIZED"),
         .CLKFBOUT_MULT_F    (7*VCO_MULTIPLIER),
         .CLKFBOUT_PHASE     (0.0),
         .CLKOUT0_DIVIDE_F   (2*VCO_MULTIPLIER),
         .CLKOUT0_DUTY_CYCLE (0.5),
         .CLKOUT0_PHASE      (0.0),
         .DIVCLK_DIVIDE      (1),
         .REF_JITTER1        (0.100)
      )
      tx_mmcm (
         .CLKFBOUT       (px_pllmmcm),
         .CLKFBOUTB      (),
         .CLKOUT0        (tx_pllmmcm_div2),
         .CLKOUT0B       (),
         .CLKOUT1        (),
         .CLKOUT1B       (),
         .CLKOUT2        (),
         .CLKOUT2B       (),
         .CLKOUT3        (),
         .CLKOUT3B       (),
         .CLKOUT4        (),
         .CLKOUT5        (),
         .CLKOUT6        (),
         .LOCKED         (cmt_locked),
         .CLKFBIN        (px_clk),
         .CLKIN1         (clkin),
         .PWRDWN         (1'b0),
         .RST            (reset)
     );
   end else begin           // Use a PLL
   PLLE3_BASE # (
         .CLKIN_PERIOD       (CLKIN_PERIOD),
         .CLKFBOUT_MULT      (7*VCO_MULTIPLIER),
         .CLKFBOUT_PHASE     (0.0),
         .CLKOUT0_DIVIDE     (2*VCO_MULTIPLIER),
         .CLKOUT0_DUTY_CYCLE (0.5),
         .REF_JITTER         (0.100),
         .DIVCLK_DIVIDE      (1)
      )
      tx_pll (
          .CLKFBOUT       (px_pllmmcm),
          .CLKOUT0        (tx_pllmmcm_div2),
          .CLKOUT0B       (),
          .CLKOUT1        (),
          .CLKOUT1B       (),
          .CLKOUTPHY      (),
          .LOCKED         (cmt_locked),
          .CLKFBIN        (px_clk),
          .CLKIN          (clkin),
          .CLKOUTPHYEN    (1'b0),
          .PWRDWN         (1'b0),
          .RST            (reset)
      );
   end
endgenerate

// 
// Global Clock Buffers
//
BUFG bg_px     (.I(px_pllmmcm     ), .O(px_clk    )) ;
BUFG bg_txdiv2 (.I(tx_pllmmcm_div2), .O(tx_clkdiv2)) ;
BUFGCE_DIV  # (
       .BUFGCE_DIVIDE(2)
     ) 
     bg_txdiv4 (
       .I(tx_pllmmcm_div2), 
       .CLR(1'b0), 
       .CE(1'b1),
       .O(tx_clkdiv4)
      ) ;
   
endmodule
