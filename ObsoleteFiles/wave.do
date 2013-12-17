onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic -label uclk -radix hexadecimal /userfpga_top_testbench_vhdl/uclk
add wave -noupdate -format Logic -label clkback /userfpga_top_testbench_vhdl/uut/clkback
add wave -noupdate -format Logic -label clk50MHz /userfpga_top_testbench_vhdl/uut/clock50mhz
add wave -noupdate -format Logic -label clk100MHz /userfpga_top_testbench_vhdl/uut/clock100mhz
add wave -noupdate -format Logic -label clk100MHzX /userfpga_top_testbench_vhdl/uut/clock100mhzx
add wave -noupdate -format Logic -label grst /userfpga_top_testbench_vhdl/uut/grst
add wave -noupdate -format Logic -label ebus_ena -radix hexadecimal /userfpga_top_testbench_vhdl/ebus_ena
add wave -noupdate -format Logic -label ebus_rd -radix hexadecimal /userfpga_top_testbench_vhdl/ebus_rd
add wave -noupdate -format Logic -label ebus_wr -radix hexadecimal /userfpga_top_testbench_vhdl/ebus_wr
add wave -noupdate -format Logic -label ebus_done -radix hexadecimal /userfpga_top_testbench_vhdl/ebus_done
add wave -noupdate -format Literal -label ebus_d -radix hexadecimal /userfpga_top_testbench_vhdl/ebus_d
add wave -noupdate -format Logic -label ebus_grant -radix hexadecimal /userfpga_top_testbench_vhdl/ebus_grant
add wave -noupdate -format Logic -label ebus_req -radix hexadecimal /userfpga_top_testbench_vhdl/ebus_req
add wave -noupdate -format Literal -label ebus_adr -radix hexadecimal /userfpga_top_testbench_vhdl/ebus_adr
add wave -noupdate -divider e2i
add wave -noupdate -format Literal -label {SF master State} -radix hexadecimal /userfpga_top_testbench_vhdl/uut/ints_userfpga/e2iconnector/usermodule_sf_master_state
add wave -noupdate -format Literal -label {UF master State} -radix hexadecimal /userfpga_top_testbench_vhdl/uut/ints_userfpga/e2iconnector/usermodule_uf_master_state
add wave -noupdate -format Logic -label Clock /userfpga_top_testbench_vhdl/uut/ints_userfpga/e2iconnector/clock
add wave -noupdate -format Literal -label {from BusController} -radix hexadecimal /userfpga_top_testbench_vhdl/uut/ints_userfpga/e2iconnector/buscontroller2busif
add wave -noupdate -format Literal -label {to BusController} -radix hexadecimal /userfpga_top_testbench_vhdl/uut/ints_userfpga/e2iconnector/busif2buscontroller
add wave -noupdate -divider {Bus Controller}
add wave -noupdate -format Literal -label state -radix hexadecimal /userfpga_top_testbench_vhdl/uut/ints_userfpga/buscontroller/buscontroller_state
add wave -noupdate -divider Simulator
add wave -noupdate -format Literal -label state /userfpga_top_testbench_vhdl/uut/ints_userfpga/inst_commander/usermodule_state
add wave -noupdate -format Literal -label clock /userfpga_top_testbench_vhdl/uut/ints_userfpga/inst_commander/clock
add wave -noupdate -format Literal -label counter /userfpga_top_testbench_vhdl/uut/ints_userfpga/inst_commander/counter
add wave -noupdate -format Literal -label {from BusController} -radix hexadecimal /userfpga_top_testbench_vhdl/uut/ints_userfpga/inst_commander/buscontroller2busif
add wave -noupdate -format Literal -label {to BusController} -radix hexadecimal /userfpga_top_testbench_vhdl/uut/ints_userfpga/inst_commander/busif2buscontroller
add wave -noupdate -divider ChModule0
add wave -noupdate -format Logic -label bufferNG /userfpga_top_testbench_vhdl/uut/ints_userfpga/inst_chmodule_0/buffernogood
add wave -noupdate -format Logic -label Trigger /userfpga_top_testbench_vhdl/uut/ints_userfpga/inst_chmodule_0/inst_triggermodule/triggerout
add wave -noupdate -format Literal -label {from Adc} -radix hexadecimal -expand /userfpga_top_testbench_vhdl/uut/ints_userfpga/inst_chmodule_0/adc2adcmodule
add wave -noupdate -format Literal -label {Buf Data In} -radix hexadecimal /userfpga_top_testbench_vhdl/uut/ints_userfpga/inst_chmodule_0/inst_buffermodule/inst_fifo/datain
add wave -noupdate -format Logic -label {Buf Wr Clk} -radix hexadecimal /userfpga_top_testbench_vhdl/uut/ints_userfpga/inst_chmodule_0/inst_buffermodule/inst_fifo/writeclock
add wave -noupdate -format Literal -label {Buf Wr Cnt} -radix hexadecimal /userfpga_top_testbench_vhdl/uut/ints_userfpga/inst_chmodule_0/inst_buffermodule/inst_fifo/writedatacount
add wave -noupdate -format Logic -label {Buf Wr Ena} -radix hexadecimal /userfpga_top_testbench_vhdl/uut/ints_userfpga/inst_chmodule_0/inst_buffermodule/inst_fifo/writeenable
add wave -noupdate -format Literal -label {Buf Data Out} -radix hexadecimal /userfpga_top_testbench_vhdl/uut/ints_userfpga/inst_chmodule_0/inst_buffermodule/inst_fifo/dataout
add wave -noupdate -format Logic -label {Buf Rd Clk} -radix hexadecimal /userfpga_top_testbench_vhdl/uut/ints_userfpga/inst_chmodule_0/inst_buffermodule/inst_fifo/readclock
add wave -noupdate -format Literal -label {Buf Rd Cnt} -radix hexadecimal /userfpga_top_testbench_vhdl/uut/ints_userfpga/inst_chmodule_0/inst_buffermodule/inst_fifo/readdatacount
add wave -noupdate -format Logic -label {Buf Rd Ena} -radix hexadecimal /userfpga_top_testbench_vhdl/uut/ints_userfpga/inst_chmodule_0/inst_buffermodule/inst_fifo/readenable
add wave -noupdate -divider Consumer0
add wave -noupdate -format Literal -label state -radix hexadecimal /userfpga_top_testbench_vhdl/uut/ints_userfpga/consumer__0/inst_consumer/usermodule_state
add wave -noupdate -format Literal -label realtime -radix hexadecimal /userfpga_top_testbench_vhdl/uut/ints_userfpga/consumer__0/inst_consumer/realtime
add wave -noupdate -format Literal -label RamAddress -radix hexadecimal /userfpga_top_testbench_vhdl/uut/ints_userfpga/consumer__0/inst_consumer/ramaddress
add wave -noupdate -format Literal -label RamDataIn -radix hexadecimal /userfpga_top_testbench_vhdl/uut/ints_userfpga/consumer__0/inst_consumer/ramdatain
add wave -noupdate -format Logic -label RamWE -radix hexadecimal /userfpga_top_testbench_vhdl/uut/ints_userfpga/consumer__0/inst_consumer/ramwriteenable
add wave -noupdate -format Literal -label DataCount -radix hexadecimal /userfpga_top_testbench_vhdl/uut/ints_userfpga/consumer__0/inst_consumer/datacount
add wave -noupdate -format Literal -label Maximum -radix hexadecimal /userfpga_top_testbench_vhdl/uut/ints_userfpga/consumer__0/inst_consumer/maximum
add wave -noupdate -format Literal -label CurrentCh -radix hexadecimal /userfpga_top_testbench_vhdl/uut/ints_userfpga/consumer__0/inst_consumer/currentch
add wave -noupdate -format Literal -label {to EventMgr} -radix hexadecimal -expand /userfpga_top_testbench_vhdl/uut/ints_userfpga/consumer__0/inst_consumer/consumer2eventmgr
add wave -noupdate -format Literal -label {from EventMgr} -radix hexadecimal -expand /userfpga_top_testbench_vhdl/uut/ints_userfpga/consumer__0/inst_consumer/eventmgr2consumer
add wave -noupdate -divider {SDRAMC BusIF}
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {37418314 ps} 0}
configure wave -namecolwidth 158
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 10000
configure wave -griddelta 40
configure wave -timeline 0
update
WaveRestoreZoom {35271513 ps} {35523581 ps}
