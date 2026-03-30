//////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2017 Xilinx, Inc.
// This design is confidential and proprietary of Xilinx, All Rights Reserved.
//////////////////////////////////////////////////////////////////////////////
//   ____  ____
//  /   /\/   /
// /___/  \  /   Vendor: Xilinx
// \   \   \/    Version: 1.0
//  \   \        Filename: SerialToAxis.sv
//  /   /        Date Last Modified:  02/25/2026
// /___/   /\    Date Created: 02/25/2026
// \   \  /  \
//  \___\/\___\
//
// Device    :  Ultrascale
//
// Purpose   :  32-bit serial data to AXI Stream converter
//
// Parameters:  None
//
// Reference:	
//
// Revision History:
//    Rev 1.0 - Initial Release
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

module SerialToAxis #(
    parameter DATA_WIDTH = 32,          // Serial data width
    parameter DEST_WIDTH = 4,           // AXI Stream destination width
    parameter ID_WIDTH   = 4            // AXI Stream ID width
)(
    // Serial data interface
    input                         serial_clk,     // Serial data clock
    input                         serial_valid,   // Serial data valid
    input        [DATA_WIDTH-1:0] serial_data,    // Serial data input
    
    // AXI Stream interface
    input                         axis_aclk,      // AXI Stream clock
    input                         axis_resetn,    // AXI Stream reset (active low)
    axi4stream_intf.master        m_axis          // AXI Stream master interface
);

    // Internal registers
    reg [DATA_WIDTH-1:0] data_ff;
    reg                  valid_ff;
    reg                  ready_ff;
    
    // CDC synchronization registers
    reg                  serial_valid_sync;
    reg [DATA_WIDTH-1:0] serial_data_sync;
    
    // AXI Stream control signals
    wire axis_ready = m_axis.READY;
    
    // CDC synchronization - sync serial data to AXI clock domain
    always_ff @(posedge axis_aclk or negedge axis_resetn) begin
        if (!axis_resetn) begin
            serial_valid_sync <= 1'b0;
            serial_data_sync  <= {DATA_WIDTH{1'b0}};
        end else begin
            serial_valid_sync <= serial_valid;
            serial_data_sync  <= serial_data;
        end
    end
    
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
    
endmodule