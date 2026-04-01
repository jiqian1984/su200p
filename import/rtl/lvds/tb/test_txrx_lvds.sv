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
`define NODEBUG
program test_txrx_lvds
(
	// Clock and Reset
	input logic refclk_p,
	input logic refclk_n,
	output logic tx_reset,
	output logic rx_reset,

	// TX Parallel Interface
	input tx_px_clk,
	output logic [34:0] tx1_px_data,
	output logic [34:0] tx2_px_data,

	// RX Parallel Interface
	input rx1_px_clk,
	input logic [34:0] rx1_px_data,
	input logic rx1_px_ready,
	input rx2_px_clk,
	input logic [34:0] rx2_px_data,
	input logic rx2_px_ready
);
	
// Define constants for LVDS module
`define DW 35  // 35-bit parallel data width
`define SP_Mult 1
`define ONE_FRAME_LENGTH 1024

// Define a data mode control to control data generate pattern
class data_control;
	rand logic [3:0] data_mode;
	constraint reasonable{
		data_mode dist {0:= 1 , 1 := 1 , 2 := 1, 3 := 1};
	}
endclass

class sync_control;
	rand logic [4:0] sync_control_length;
	constraint reasonable{
		sync_control_length dist {[16:32]:/1};
	}
endclass

import "DPI-C" function real sin(input real r);

function integer my_sin;
input integer value;
input integer length;
integer act_value;
real duble_value;
real duble_sin;
begin 
    if(value > length) begin
	    act_value = value - length;
	end
	else begin
	    act_value = value;
	end
	//`ifdef DEBUG
	//	$write("my_sin func:value in is %4d,length is %4d,act_valueis %4d\n",value,length,act_value);
	//`endif
	duble_value = 6.283*(real'(act_value)/real'(length));
	duble_sin = sin(duble_value);
    my_sin = integer'(duble_sin * 1024);
end 
endfunction 


//function logic[31:0] reference_model;
//input shortint input_i;
//input shortint input_q;
//input shortint i_sin;
//input shortint i_cos;
//int step_i;
//int step_q;
//shortint result_i;
//shortint result_q;
//begin
//    step_i = (-(input_q * i_sin)) + input_i * i_cos ;
//	step_q = input_i * i_sin + input_q * i_cos;
//    result_i = shortint'(step_i >>> 10);
//    result_q = shortint'(step_q >>> 10);
//`ifdef DEBUG
//	$write("---input_i is 'h%0h;  input_q is 'h%0h;  i_sin is 'h%0h;  i_cos is 'h%0h;\n",input_i,input_q,i_sin,i_cos);
//	$write("---step_i is 'h%0h;  step_q is 'h%0h\n",step_i,step_q);
//	$write("---result_i is 'h%0h;  result_q is 'h%0h\n",result_i,result_q);
//`endif
//	reference_model = {result_i,result_q};
//end 
//endfunction 

//////////////////////////////////////////
// Definition: Coverage Group
//////////////////////////////////////////
    covergroup txrx_lvds_cvr ;
        DMODE: coverpoint IO_DATA_TYPE.data_mode {
            bins ZERO  = { 0 };
			bins ONE_FORTH  = { 1 };
            bins TWO_FORTH  = { 2 };
            bins THREE_FORTH  = { 3 };
        }
		SYNCMODE: coverpoint SYNC_TYPE.sync_control_length {
            bins SHORT  = { [16:24]};
            bins LONG  = { [25:32]};
        }
		DMODExSYNCMODE: cross DMODE,SYNCMODE;
    endgroup



// Define the control and cvr check point
data_control  IO_DATA_TYPE;
sync_control  SYNC_TYPE;
txrx_lvds_cvr my_msg_crv_0;

logic [`DW*`SP_Mult-1:0] data_io_msg0_ch1[$];
logic [`DW*`SP_Mult-1:0] data_io_msg0_ch2[$];

mailbox mbox_after_reveive_ch1;
mailbox mbox_after_reveive_ch2;

int NUM = 0;
int num_current_tx = 0;
int num_current_rx = 0;
int rate_count_max = 0;
int wrong_receive_count_ch1 = 0;
int wrong_receive_count_ch2 = 0;
// Reset the previous reset
task init_reset(input [9:0] rst_delay = 200);
    $write("Here is the init,reset\n");
	tx_reset <= 1'b1;
	rx_reset <= 1'b1;
	tx1_px_data <= {(`DW*`SP_Mult){1'b0}};
	tx2_px_data <= {(`DW*`SP_Mult){1'b0}};
	repeat(rst_delay) @(posedge refclk_p);
	tx_reset <= 1'b0;
	rx_reset <= 1'b0;
	tx1_px_data <= {(`DW*`SP_Mult){1'b0}};
	tx2_px_data <= {(`DW*`SP_Mult){1'b0}};
	@(posedge refclk_p);
endtask



int sycn_length = 4;
// Generate TX data, according to data mode and sync control
task tx_data_generate(input frame_first = 0);
    logic [34:0] tx_data_ch1;
    logic [34:0] tx_data_ch2;

    // Randomize the data mode and sync length
    assert(IO_DATA_TYPE.randomize())
  	else $write("TEST: IO_DATA_TYPE randomize error!!!\n");
    assert(SYNC_TYPE.randomize())
  	else $write("TEST: SYNC_TYPE randomize error!!!\n");

	$write("here is TX data generate;this is the %4d times,the data_mode is %4d &&& the SYNC_Length is %4d at time: %12d \n",num_current_tx,IO_DATA_TYPE.data_mode,SYNC_TYPE.sync_control_length,$time);
	sycn_length = SYNC_TYPE.sync_control_length;

	// According to the addr_mode, set tx_px_data init value
	case(IO_DATA_TYPE.data_mode)
	    0 : begin tx_data_ch1 = 35'h555555555; tx_data_ch2 = 35'hAAAAAAAA; end
		1 : begin tx_data_ch1 = {35{1'b0}}; tx_data_ch2 = {35{1'b0}}; end
		2 : begin tx_data_ch1 = {35{1'b0}}; tx_data_ch2 = {35{1'b0}}; end
		3 : begin tx_data_ch1 = {35{1'b0}}; tx_data_ch2 = {35{1'b0}}; end
		default :
		    begin tx_data_ch1 = {35{1'b0}}; tx_data_ch2 = {35{1'b0}}; end
	endcase;

    // Generate one whole cycle (sync bytes + data)
	for(int sample_cycle = 0; sample_cycle < sycn_length; sample_cycle ++)
	begin
		tx_data_ch1 = 35'hCCCCCCCCC;
		tx_data_ch2 = 35'h333333333;
		`ifdef DEBUG
		    $write("TX_DATA SYNC generate is:sample_cycle is %4d,tx_data_ch1 is 'h%0h\n",sample_cycle,tx_data_ch1);
		`endif
		tx1_px_data = tx_data_ch1;
		tx2_px_data = tx_data_ch2;
		@(posedge tx_px_clk);
	end
	tx_data_ch1 = 35'h555555555;
	tx_data_ch2 = 35'hAAAAAAAA;
	tx1_px_data = tx_data_ch1;
	tx2_px_data = tx_data_ch2;
	for(int sample_cycle = 0; sample_cycle < `ONE_FRAME_LENGTH; sample_cycle ++)
	begin
		`ifdef DEBUG
		    $write("TX_DATA data generate is:sample_cycle is %4d,tx_data_ch1 is 'h%0h\n",sample_cycle,tx_data_ch1);
		`endif
		 case(IO_DATA_TYPE.data_mode)
			0 : begin tx_data_ch1 = ~tx_data_ch1; tx_data_ch2 = ~tx_data_ch2; end
			1 : begin tx_data_ch1 = tx_data_ch1 + 1; tx_data_ch2 = tx_data_ch2 - 1; end
			2 : begin tx_data_ch1 = tx_data_ch1 + 35'h111111111; tx_data_ch2 = tx_data_ch2 + 35'h222222222; end
			3 : begin tx_data_ch1 = my_sin(sample_cycle,`ONE_FRAME_LENGTH); tx_data_ch2 = my_sin(sample_cycle+100,`ONE_FRAME_LENGTH); end
			default :
		    	begin tx_data_ch1 = {35{1'b0}}; tx_data_ch2 = {35{1'b0}}; end
		 endcase
		tx1_px_data = tx_data_ch1;
		tx2_px_data = tx_data_ch2;
		data_io_msg0_ch1.push_back(tx_data_ch1);
		data_io_msg0_ch2.push_back(tx_data_ch2);
		@(posedge tx_px_clk);
	end
	tx1_px_data = {35{1'b0}};
	tx2_px_data = {35{1'b0}};
	@(posedge tx_px_clk);
    num_current_tx = num_current_tx + 1;
endtask

// Monitor received data
integer data_read_count_ch1 = 0;
integer data_read_count_ch2 = 0;

task rx_data_monitor_ch1(input read_delay = 1);
	integer receive_data_count;
	integer receive_head;
	logic [34:0] rx_data_before;

	$write("here is RX data monitor CH1;this is the %4d times, at time: %12d \n",num_current_rx,$time);
	receive_data_count = 0;
	receive_head = 0;

	// Wait for ready signal
	wait(rx1_px_ready == 1'b1);
	$display("CH1: RX ready asserted");

	// Wait for sync pattern (0xCCCCCCCCC)
	rx_data_before = rx1_px_data;
	@(posedge rx1_px_clk);
	while(rx1_px_data == 35'hCCCCCCCCC) begin
		if(receive_head == 0) begin
			receive_head = receive_head + 1;
			$display("CH1: detected sync byte");
		end
		else begin
			if(rx_data_before == 35'hCCCCCCCCC) begin
				receive_head = receive_head + 1;
				$display("CH1: Now detect the %0d sync pattern",receive_head);
			end
			else begin
				$display("CH1: it's a data 0xccccccccc detect");
			end
		end
		rx_data_before = rx1_px_data;
		@(posedge rx1_px_clk);
	end

	$display("CH1: Now begin data transfer");
	for(int read_i = 0; read_i < `ONE_FRAME_LENGTH; read_i ++)
	begin
		mbox_after_reveive_ch1.put(rx1_px_data);
		`ifdef DEBUG
		    $write("CH1: rx_data_monitor is:rx1_px_data is 'h%0h;it is %4d times at time: %12d \n",rx1_px_data,data_read_count_ch1,$time);
		`endif
		data_read_count_ch1 = data_read_count_ch1 + 1;
		@(posedge rx1_px_clk);
	end

	data_read_count_ch1 = 0;
    num_current_rx = num_current_rx + 1;
endtask

task rx_data_monitor_ch2(input read_delay = 1);
	integer receive_data_count;
	integer receive_head;
	logic [34:0] rx_data_before;

	$write("here is RX data monitor CH2;this is the %4d times, at time: %12d \n",num_current_rx,$time);
	receive_data_count = 0;
	receive_head = 0;

	// Wait for ready signal
	wait(rx2_px_ready == 1'b1);
	$display("CH2: RX ready asserted");

	// Wait for sync pattern (0x333333333)
	rx_data_before = rx2_px_data;
	@(posedge rx2_px_clk);
	while(rx2_px_data == 35'h333333333) begin
		if(receive_head == 0) begin
			receive_head = receive_head + 1;
			$display("CH2: detected sync byte");
		end
		else begin
			if(rx_data_before == 35'h333333333) begin
				receive_head = receive_head + 1;
				$display("CH2: Now detect the %0d sync pattern",receive_head);
			end
			else begin
				$display("CH2: it's a data 0x333333333 detect");
			end
		end
		rx_data_before = rx2_px_data;
		@(posedge rx2_px_clk);
	end

	$display("CH2: Now begin data transfer");
	for(int read_i = 0; read_i < `ONE_FRAME_LENGTH; read_i ++)
	begin
		mbox_after_reveive_ch2.put(rx2_px_data);
		`ifdef DEBUG
		    $write("CH2: rx_data_monitor is:rx2_px_data is 'h%0h;it is %4d times at time: %12d \n",rx2_px_data,data_read_count_ch2,$time);
		`endif
		data_read_count_ch2 = data_read_count_ch2 + 1;
		@(posedge rx2_px_clk);
	end

	data_read_count_ch2 = 0;
    num_current_rx = num_current_rx + 1;
endtask
// Check the output data from RX channels
task data_check_ch1(input [2:0] delay_cycle = 6);
	logic [34:0] rx_data_receive;
	logic [34:0] tx_data_expected;

    $write("check the data read in CH1\n");
	while(1)
	begin
        // Get the data that is read(poped) out of the mailbox
        mbox_after_reveive_ch1.get(rx_data_receive);
		// Get the expected data from top of the queue
		tx_data_expected = data_io_msg0_ch1.pop_front();

        // Compare the two
        assert(tx_data_expected == rx_data_receive)
  	    else
			$write("TEST: CH1 after receive data rx:'h%0h != expected data 'h%0h ;\n",rx_data_receive, tx_data_expected);
        if(tx_data_expected != rx_data_receive)begin
			wrong_receive_count_ch1 = wrong_receive_count_ch1 + 1;
		end
	end
endtask

task data_check_ch2(input [2:0] delay_cycle = 6);
	logic [34:0] rx_data_receive;
	logic [34:0] tx_data_expected;

    $write("check the data read in CH2\n");
	while(1)
	begin
        // Get the data that is read(poped) out of the mailbox
        mbox_after_reveive_ch2.get(rx_data_receive);
		// Get the expected data from top of the queue
		tx_data_expected = data_io_msg0_ch2.pop_front();

        // Compare the two
        assert(tx_data_expected == rx_data_receive)
  	    else
			$write("TEST: CH2 after receive data rx:'h%0h != expected data 'h%0h ;\n",rx_data_receive, tx_data_expected);
        if(tx_data_expected != rx_data_receive)begin
			wrong_receive_count_ch2 = wrong_receive_count_ch2 + 1;
		end
	end
endtask


////////////////////////////////
  //    Instantiation of objects
  ////////////////////////////////
 initial begin : main_prog
  my_msg_crv_0 = new();
  mbox_after_reveive_ch1 = new();
  mbox_after_reveive_ch2 = new();
  IO_DATA_TYPE = new();
  SYNC_TYPE = new();

  //////////////////////////////////////////
  //    Read in NUM value - how many sets of
  //    Data we want to simulate
  //////////////////////////////////////////

  if (!$value$plusargs("NUM=%0d",NUM))
    NUM = 10;
  $write("LVDS_TXRX_TEST: Start simulation %d sets of data \n",NUM);


  //////////////////////////////////////////
  //    Reset  and check for proper
  //    signals from DUT
  //////////////////////////////////////////

  fork
    init_reset(300);
  join


  //////////////////////////////////////////
  //  The checker blocks are spawned in the
  //  background ( fork join_none construct)
  //////////////////////////////////////////
  fork
    data_check_ch1(1);
    data_check_ch2(1);
  join_none


  ////////////////////////////////////////////
  //  Basic Test, write and read in parallel
  //  sample the covergroups initially
  ////////////////////////////////////////////
  repeat(NUM)
  fork
    tx_data_generate(1);
	rx_data_monitor_ch1(1);
	rx_data_monitor_ch2(1);
	$write("------complete one TX/RX cycle and check----------\n");
	@(posedge refclk_p) my_msg_crv_0.sample();
  join

  repeat(10)@(posedge refclk_p);
  #100us;
  $write("LVDS_TXRX_TEST: end simulation %d sets of data \n",NUM);
  if((wrong_receive_count_ch1 == 0) && (wrong_receive_count_ch2 == 0)) begin
		$write("Congratulations, Simulation PASSED! \n");
  end else begin
		$write("ERROR: simulation failed! check error in the log.\n");
		$write("CH1 failed %0d times, CH2 failed %0d times.\n",wrong_receive_count_ch1, wrong_receive_count_ch2);
  end

end : main_prog


endprogram : test_txrx_lvds