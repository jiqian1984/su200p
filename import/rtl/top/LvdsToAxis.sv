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
import definitions_pkg::*;

// Top level example with  transmit and receiver channels to axis interfaces
//---------S_axis -----> Tx_LVDS
//---------RX_LDS -----> M_axis,
//  if inter data gen and monitor are enabled, then the rx_px_ready is used
module LvdsToAxis #(
   parameter SIM_DEVICE = "ULTRASCALE"  // Set for the family <ULTRASCALE | ULTRASCALE_PLUS>
   parameter DATE_GEN_INTER = 0,
   parameter DATA_MON_INTER = 0,
   parameter DATA_WIDTH = 32,
)(
   //parralel data interfaces
   input           tx_px_clk,
   output  [34:0]  tx1_px_data,

   input         rx1_px_clk,
   input [34:0]  rx1_px_data,
   input         rx1_px_ready,

   //axis interfaces
   input axis_aclk,
   input axis_resetn,
   axi4stream_intf m_axis,
   //
   axi4stream_intf s_axis,
) ;  

reg [6:0] pix_data;
reg pix_data_last;


//data generator interface
generate
  if (DATE_GEN_INTER == 1) begin : date_gen
      always_ff @(posedge tx_px_clk) begin
         pix_data <= pix_data + 1'b1;
      end 

      always_comb begin
         tx1_px_data <= {pix_data, pix_data, pix_data, pix_data, pix_data};
      end 

 end
 else begin : data_from_maxis
      always_ff @(posedge axi_clk_in or posedge rst_in) begin
         if (rst_in) begin
            pix_data <= 0;
            pix_data_last <= 1'b0;
         end 
         else begin
            if (s_axis.tvalid && s_axis.ready) begin
               pix_data <= s_axis.tdata[6:0];
            end 
            
            if (s_axis.tvalid && s_axis.ready && s_axis.last) begin
               pix_data_last <= 1'b1;
            end 
            else begin
               pix_data_last <= 1'b0;
            end 
         end  

      always_comb begin
         tx1_px_data  <= {pix_data, pix_data, pix_data, pix_data, pix_data};
         s_axis.ready <= 1'b1;
      end 
      end 
 end
endgenerate



// Internal registers
reg [DATA_WIDTH-1:0] data_ff;
reg                  valid_ff;
reg                  ready_ff;

// CDC synchronization registers
reg                  serial_valid_sync;
reg [DATA_WIDTH-1:0] serial_data_sync;

// AXI Stream control signals
wire axis_ready = m_axis.READY;

//data monitor interface
generate
  if (DATA_MON_INTER == 1) begin : date_monitor
      always_ff @(posedge axi_clk_in or posedge rst_in) begin
         rx1_px_last <= rx1_px_data;

      end 

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
  end 
   else begin
    
    
    // CDC synchronization - sync serial data to AXI clock domain
    always_ff @(posedge axis_aclk or negedge axis_resetn) begin
        if (!axis_resetn) begin
            serial_valid_sync <= 1'b0;
            serial_data_sync  <= {DATA_WIDTH{1'b0}};
        end else begin
            serial_valid_sync <= rx1_px_ready;
            serial_data_sync  <= rx1_px_data[31:0];
        end
    end
    
    //convert data to axis's bit width

    // Data pipeline register
    always_ff @(posedge axis_aclk or negedge axis_resetn) begin
        if (!axis_resetn) begin
            data_ff  <= {DATA_WIDTH{1'b0}};
            valid_ff <= 1'b0;
        end else begin
            if (serial_valid_sync) begin
                data_ff  <= serial_data_sync;
                valid_ff <= 1'b1;
            end else if (axis_ready && valid_ff) begin
                valid_ff <= 1'b0;
            end
        end
    end
    
    // Ready signal generation
    always_ff @(posedge axis_aclk or negedge axis_resetn) begin
        if (!axis_resetn) begin
            ready_ff <= 1'b0;
        end else begin
            // Ready when not valid or when data is being transferred
            ready_ff <= !valid_ff || (valid_ff && axis_ready);
        end
    end
    
    // AXI Stream output assignments
    assign m_axis.VALID = valid_ff;
    assign m_axis.DATA  = data_ff;
    assign m_axis.KEEP  = {(DATA_WIDTH/8){1'b1}};  // All bytes valid
    assign m_axis.LAST  = 1'b1;                    // Single beat transfers
    assign m_axis.ID    = {ID_WIDTH{1'b0}};        // Default ID
    assign m_axis.DEST  = {DEST_WIDTH{1'b0}};      // Default destination

      end 
endgenerate

//data to s_axis interface



    axis_data_fifo_64b axi_txopt0_fifo (
      .s_axis_aresetn   (!rst_txopt_fifo[aurora_num]),  // input wire s_axis_aresetn
      .s_axis_aclk      (axi_clk_in),        // input wire s_axis_aclk
      .s_axis_tvalid    (s_opt_axi_tvalid[aurora_num]),    // input wire s_axis_tvalid
      .s_axis_tready    (s_opt_axi_tready[aurora_num]),    // output wire s_axis_tready
      .s_axis_tdata     (s_opt_axi_tdata[(aurora_num+1)*64-1:aurora_num*64]),      // input wire [63 : 0] s_axis_tdata
      .s_axis_tkeep     (s_opt_axi_tkeep[(aurora_num+1)*8-1:aurora_num*8]),      // input wire [7 : 0] s_axis_tkeep
      .s_axis_tlast     (s_opt_axi_tlast[aurora_num]),      // input wire s_axis_tlast
      .m_axis_aclk      (user_clk_t[aurora_num]),        // input wire m_axis_aclk
      .m_axis_tvalid    (tx_tvalid_t[aurora_num]),    // output wire m_axis_tvalid
      .m_axis_tready    (tx_tready_t[aurora_num]),    // input wire m_axis_tready
      .m_axis_tdata     (tx_data_t[(aurora_num+1)*64-1:aurora_num*64]),      // output wire [63 : 0] m_axis_tdata
      .m_axis_tkeep     (tx_tkeep_t[(aurora_num+1)*8-1:aurora_num*8]),      // output wire [7 : 0] m_axis_tkeep
      .m_axis_tlast     (tx_tlast_t[aurora_num]),      // output wire m_axis_tlast
      .almost_empty     (wfifo_empty[aurora_num]),      // output wire almost_empty
      .prog_full        (wfifo_full[aurora_num])            // output wire prog_full
    );


always_comb @(posedge axi_clk_in or posedge rst_in) begin

end 

always_ff @(posedge axi_clk_in or posedge rst_in) begin

end 
//
if

/*************************
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
****************************/

endmodule
