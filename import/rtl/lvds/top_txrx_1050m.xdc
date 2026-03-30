#
# KCU105 Specific
#
set_property CFGBVS         GND [current_design]
set_property CONFIG_VOLTAGE 1.8 [current_design]

#
# 300 MHz Reference Clock
#
set_property IOSTANDARD    LVDS  [get_ports "refclk_*"] ;#
set_property DIFF_TERM_ADV TERM_NONE [get_ports "refclk_*"] ;#
set_property PACKAGE_PIN   AK17  [get_ports "refclk_p"] ;# Bank  45 VCCO - VADJ_1V2_FPGA - SYSCLK_300_P
create_clock -period 3.333       [get_ports "refclk_p"] ;#

#
# Reset and Match LEDs
#
set_property IOSTANDARD  LVCMOS18 [get_ports "tx_reset"] ;# 
set_property PACKAGE_PIN AF9      [get_ports "tx_reset"] ;# Bank  64 VCCO - VCC1V8_FPGA - GPIO_SW_W
set_property IOSTANDARD  LVCMOS18 [get_ports "rx_reset"] ;# 
set_property PACKAGE_PIN AE8      [get_ports "rx_reset"] ;# Bank  64 VCCO - VCC1V8_FPGA - GPIO_SW_E

set_property IOSTANDARD  LVCMOS18 [get_ports "rx1_match"   ] ;# 
set_property PACKAGE_PIN AP8      [get_ports "rx1_match"   ] ;# Bank  64 VCCO - VCC1V8_FPGA - GPIO_LED_0_LS
set_property IOSTANDARD  LVCMOS18 [get_ports "rx1_match_lt"] ;# 
set_property PACKAGE_PIN H23      [get_ports "rx1_match_lt"] ;# Bank  64 VCCO - VCC1V8_FPGA - GPIO_LED_1_LS

set_property IOSTANDARD  LVCMOS18 [get_ports "rx2_match"   ] ;# 
set_property PACKAGE_PIN P20      [get_ports "rx2_match"   ] ;# Bank  65 VCCO - VCC1V8_FPGA - GPIO_LED_2_LS
set_property IOSTANDARD  LVCMOS18 [get_ports "rx2_match_lt"] ;#
set_property PACKAGE_PIN P21      [get_ports "rx2_match_lt"] ;# Bank  65 VCCO - VCC1V8_FPGA - GPIO_LED_3_LS

set_false_path -to [get_pins icontrol/RST]

#
# RX Channel 1 
#
set_property IOSTANDARD  LVDS [get_ports "clkin1_*"  ];
set_property IOSTANDARD  LVDS [get_ports "datain1_*"] ;
create_clock -period  6.666   [get_ports "clkin1_p"] ;#

set_property PACKAGE_PIN AA32 [get_ports "clkin1_p"    ] ;# Bank  48 VCCO - VADJ_1V8_FPGA - FMC_LPC_LA17_CC_P
set_property PACKAGE_PIN AA29 [get_ports "datain1_p[0]"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - FMC_LPC_LA19_P
set_property PACKAGE_PIN AA34 [get_ports "datain1_p[1]"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - FMC_LPC_LA20_P
set_property PACKAGE_PIN AC33 [get_ports "datain1_p[2]"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - FMC_LPC_LA21_P
set_property PACKAGE_PIN AC34 [get_ports "datain1_p[3]"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - FMC_LPC_LA22_P
set_property PACKAGE_PIN AD30 [get_ports "datain1_p[4]"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - FMC_LPC_LA23_P

# Clock group constraint to ensure correct clock skew for ISERDES
set_property CLOCK_DELAY_GROUP ioclockGroup_rx1 [get_nets "rx_channel1/rx_clkdiv*"]

set_false_path -to [get_pins "rx_channel1/rxc_gen/iserdes_m/D"]
set_false_path -to [get_pins "rx_channel1/rxc_gen/iserdes_s/D"]
set_false_path -to [get_pins {rx_channel1/rxc_gen/px_reset_sync_reg[*]/PRE}] 
set_false_path -to [get_pins {rx_channel1/rxc_gen/px_rx_ready_sync_reg[*]/CLR}] 
set_false_path -to [get_pins {rx_channel1/rxc_gen/px_data_reg[*]/D}]
set_false_path -to [get_pins {rx_channel1/rxc_gen/px_rd_last_reg[*]/D}]
#jimt set_false_path -to [get_pins {rx_channel1/rxd[*].sipo/px_data_reg[*]/D}]
#jimt set_false_path -to [get_pins {rx_channel1/rxd[*].sipo/px_rd_last_reg[*]/D}]

#
# RX Channel 2
#
set_property IOSTANDARD  LVDS [get_ports "clkin2_*" ] ;
set_property IOSTANDARD  LVDS [get_ports "datain2_*"] ;
create_clock -period  6.666   [get_ports "clkin2_p"] ;#

set_property PACKAGE_PIN AB30 [get_ports "clkin2_p"    ] ;# Bank  48 VCCO - VADJ_1V8_FPGA - FMC_LPC_LA18_CC_P
set_property PACKAGE_PIN AE32 [get_ports "datain2_p[0]"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - FMC_LPC_LA24_P
set_property PACKAGE_PIN AE33 [get_ports "datain2_p[1]"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - FMC_LPC_LA25_P
set_property PACKAGE_PIN AF33 [get_ports "datain2_p[2]"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - FMC_LPC_LA26_P
set_property PACKAGE_PIN AG31 [get_ports "datain2_p[3]"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - FMC_LPC_LA27_P
set_property PACKAGE_PIN V31  [get_ports "datain2_p[4]"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - FMC_LPC_LA28_P

# Clock group constraint to ensure correct clock skew for ISERDES
set_property CLOCK_DELAY_GROUP ioclockGroup_rx2 [get_nets "rx_channel2/rx_clkdiv*"]

set_false_path -to [get_pins "rx_channel2/rxc_gen/iserdes_m/D"]
set_false_path -to [get_pins "rx_channel2/rxc_gen/iserdes_s/D"]
set_false_path -to [get_pins {rx_channel2/rxc_gen/px_reset_sync_reg[*]/PRE}]
set_false_path -to [get_pins {rx_channel2/rxc_gen/px_rx_ready_sync_reg[*]/CLR}]
set_false_path -to [get_pins {rx_channel2/rxc_gen/px_data_reg[*]/D}]
set_false_path -to [get_pins {rx_channel2/rxc_gen/px_rd_last_reg[*]/D}]
set_false_path -to [get_pins {rx_channel2/rxd[*].sipo/px_data_reg[*]/D}]
set_false_path -to [get_pins {rx_channel2/rxd[*].sipo/px_rd_last_reg[*]/D}]

#
# TX Channel 1
#
set_property IOSTANDARD  LVDS [get_ports "clkout1_*"  ];
set_property IOSTANDARD  LVDS [get_ports "dataout1_*"] ;

set_property PACKAGE_PIN W23  [get_ports "clkout1_p"    ] ;# Bank  47 VCCO - VADJ_1V8_FPGA - FMC_LPC_LA00_CC_P
set_property PACKAGE_PIN AA22 [get_ports "dataout1_p[0]"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - FMC_LPC_LA02_P
set_property PACKAGE_PIN W28  [get_ports "dataout1_p[1]"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - FMC_LPC_LA03_P
set_property PACKAGE_PIN U26  [get_ports "dataout1_p[2]"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - FMC_LPC_LA04_P
set_property PACKAGE_PIN V27  [get_ports "dataout1_p[3]"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - FMC_LPC_LA05_P
set_property PACKAGE_PIN V29  [get_ports "dataout1_p[4]"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - FMC_LPC_LA06_P

set_false_path -to [get_pins {tx_channel1/tx_enable_sync_reg[*]/CLR}]
set_false_path -to [get_pins {tx_channel1/txc_piso/tx_data_reg[*]/D}]
set_false_path -to [get_pins {tx_channel1/txc_piso/rd_last_reg[*]/D}]
set_false_path -to [get_pins {tx_channel1/txd[*].piso/tx_data_reg[*]/D}]
set_false_path -to [get_pins {tx_channel1/txd[*].piso/rd_last_reg[*]/D}]

#
# TX Channel 1
#
set_property IOSTANDARD  LVDS [get_ports "clkout2_*" ] ;
set_property IOSTANDARD  LVDS [get_ports "dataout2_*"] ;

set_property PACKAGE_PIN W25  [get_ports "clkout2_p" ] ;# Bank  47 VCCO - VADJ_1V8_FPGA - FMC_LPC_LA01_CC_P
set_property PACKAGE_PIN V22  [get_ports "dataout2_p[0]"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - FMC_LPC_LA07_P
set_property PACKAGE_PIN U24  [get_ports "dataout2_p[1]"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - FMC_LPC_LA08_P
set_property PACKAGE_PIN V26  [get_ports "dataout2_p[2]"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - FMC_LPC_LA09_P
set_property PACKAGE_PIN T22  [get_ports "dataout2_p[3]"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - FMC_LPC_LA10_P
set_property PACKAGE_PIN V21  [get_ports "dataout2_p[4]"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - FMC_LPC_LA11_P

set_false_path -to [get_pins {tx_channel2/txc_piso/tx_data_reg[*]/D}]
set_false_path -to [get_pins {tx_channel2/txc_piso/rd_last_reg[*]/D}]
set_false_path -to [get_pins {tx_channel2/txd[*].piso/tx_data_reg[*]/D}]
set_false_path -to [get_pins {tx_channel2/txd[*].piso/rd_last_reg[*]/D}]

# Clock group constraint to ensure correct clock skew for TX OSERDES
set_property CLOCK_DELAY_GROUP ioclockGroup_tx [get_nets -of [get_pins tx_clkgen/bg_txdiv2/O]]
set_property CLOCK_DELAY_GROUP ioclockGroup_tx [get_nets -of [get_pins tx_clkgen/bg_txdiv4/O]]
