# 假设RTL_PATH变量在Makefile中定义，但也可以从环境变量中获取
SOURCE_PATH ?= imports
prj="board"
SIM_DIR=./pms.sim/sim_1/behav/questa
FILE_PATH=imports/tb/xilinx_dma_pcie_ep.vh
TOP_PATH=imports/rtl/top/xilinx_dma_pcie_ep.sv
DATE_TIME := $(shell date +%m%d%H%M)
TIMESTAMP_PLACEHOLDER="parameter\ TIMESTAMP\ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ =\ "
TIMING_REPORT="./pms.runs/impl_1/xilinx_dma_pcie_ep_timing_summary_routed.rpt"

TEST      ?= dma_stream0
CASE      ?= 0
CASES     ?= 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16
XDMA      ?= 0
DDR       ?= 1
GUI       ?= 0
ALL       ?= 0
timeout   ?= 7200


ifeq ($(ALL), 1)
	CASES  += 99
endif


# 最大同时运行的 Docker 容器数量
MAX_CONTAINERS := 14
# yeting notebook:
# MAC_ADDRESS=00:0c:29:78:ab:79
# MAC_ADDRESS=34:5a:60:32:8f:e9
# yeting server  :
# MAC_ADDRESS=64:4e:d7:69:87:6b

# 获取当前用户名并设置相应的 MAC 地址
CURRENT_USER := $(shell whoami)

ifeq ($(CURRENT_USER),ting)
    MAC_ADDRESS=64:4e:d7:69:87:6b
else
    # 默认 MAC 地址，或者报错
    MAC_ADDRESS=34:5a:60:32:8f:e9
endif


COMP_OPTS :=
RUN_OPTS  :=


COMP_OPTS += -64
COMP_OPTS += -c

RUN_OPTS  += -64
ifeq ($(GUI), 0)
	RUN_OPTS  += -c
endif

RUN_OPTS  += +TESTNAME=$(TEST)
RUN_OPTS  += -coverage
#RUN_OPTS  += +TEST_CASE=$(CASE)
RUN_OPTS  += -lib xil_defaultlib board_opt
RUN_OPTS  += -do "coverage save -onexit tb_$(CASE).ucdb;set NumericStdNoWarnings 1;set StdArithNoWarnings 1;do {board_wave.do};view wave;view structure;view signals;log -r /*;do {board.udo};run -all;quit -f"
RUN_OPTS  += -l run_$(CASE).log
RUN_OPTS  += -wlf vsim_$(CASE).wlf


# 默认目标
.PHONY: default
default: help

.PHONY: clean_bit clean_sim blank lf fmt init clean genbit bit gensim comp elab run sim wave help prj reset update_commit_date

# blank目标：删除RTL_PATH下所有文件的行尾空格
blank:
	@find $(SOURCE_PATH) -type f -exec sed -i 's/[[:space:]]\+$$//' {} \;

lf:
	@find $(SOURCE_PATH) -type f -exec dos2unix {} \;

fmt: blank lf

init:
	rm -rf $(FILE_PATH)
	touch $(FILE_PATH)
	@if [ "$(DDR)" -eq 1 ]; then \
        echo '`define DDR' >> "$(FILE_PATH)"; \
    fi
	@if [ "$(XDMA)" -eq 1 ]; then \
        echo '`define XDMA' >> "$(FILE_PATH)"; \
    fi

clean_bit:
	rm -rf ./pms.runs 

clean_sim:
	rm -rf ./pms.sim

clean:
	git clean -fd

reset:
	git reset --hard HEAD

genbit:
	@vivado -mode tcl -source ./scripts/pms.tcl

update_commit_date:
	@sed -i "s/${TIMESTAMP_PLACEHOLDER}.*/${TIMESTAMP_PLACEHOLDER}32'h$(DATE_TIME),/" $(TOP_PATH)

check_timing:
	@grep -A 3 "WNS" ${TIMING_REPORT} | head -n 3 | tr -s ' ' | cut -d ' ' -f 2,3

bit: clean_bit update_commit_date genbit check_timing

gensim:
	@vivado -mode tcl -source ./scripts/prepare_sim.tcl
	@echo "quit -f" >> $(SIM_DIR)/${prj}_compile.do
	@echo "quit -f" >> $(SIM_DIR)/${prj}_elaborate.do
	@cat ./scripts/wave.do > $(SIM_DIR)/${prj}_wave.do

comp:
	@cd $(SIM_DIR) \
    && vsim ${COMP_OPTS} -do ${prj}_compile.do -l comp.log\
    && cd -

elab:
	@cd $(SIM_DIR) \
    && vsim -64 -c -do ${prj}_elaborate.do -l elab.log\
    && cd -

run:
	@cd $(SIM_DIR) \
    && vsim ${RUN_OPTS} +TEST_CASE=$(CASE) \
    && cd -

case:
	@cd $(SIM_DIR)/../ \
	&& rm -rf questa_$(CASE) \
	&& cp -r questa questa_$(CASE) \
	&& cd questa_$(CASE) \
    && vsim ${RUN_OPTS} +TEST_CASE=$(CASE) > run_$(CASE).log &

wait:
	@echo "Waiting for all cases to finish..."
	@for case in $(CASES); do \
		logfile="$(SIM_DIR)/../questa_$$case/run_$$case.log"; \
		echo "Waiting for case $$case to finish..."; \
		timeout=7200; \
		start_time=$$(date +%s); \
		while [ ! -f "$$logfile" ]; do \
			current_time=$$(date +%s); \
			if [ $$((current_time - start_time)) -ge $$timeout ]; then \
				echo "Timeout: Log file for case $$case was not created within $$timeout seconds."; \
				exit 1; \
			fi; \
			sleep 1; \
		done; \
		while ! grep -q "Elapsed time" "$$logfile"; do \
			current_time=$$(date +%s); \
			if [ $$((current_time - start_time)) -ge $$timeout ]; then \
				echo "Timeout: Case $$case did not finish within $$timeout seconds."; \
				exit 1; \
			fi; \
			sleep 1; \
		done; \
		echo "Case $$case finished."; \
	done
	@echo "All cases have finished."

collect_results:
	@echo "---------------------------------------------------------------------"
	@echo "Collecting results..."
	@for case in $(CASES); do \
		logfile="$(SIM_DIR)/run_$$case.log"; \
		if [ -f "$$logfile" ]; then \
			if grep -q "INFO: PASS All tests passed" "$$logfile"; then \
				echo "Case $$case: PASS"; \
			else \
				echo "Case $$case: FAIL"; \
			fi; \
		else \
			echo "Case $$case: FAIL (Log file not found: $$logfile)"; \
		fi; \
	done


summary: wait collect_results

run_all:
	@cd $(SIM_DIR) \
	vsim $(RUN_OPTS) +TEST_CASE=$(CASE) > run_$(CASE)_$(CASE).log &  

wave:
	@cd $(SIM_DIR) \
    && vsim -64 -view vsim_$(CASE).wlf -do ${prj}_wave.do

sim: clean_sim init gensim comp elab run
env: clean_sim init gensim comp elab

regr:
	make env
	@for case in $(CASES); do \
		make case CASE=$$case; \
	done
	make summary


.PHONY: copy regrdock

copy:
	@cd $(SIM_DIR)/../ \
	&& rm -rf questa_$(CASE) \
	&& cp -r questa questa_$(CASE)


regrdock:
	make env
	@echo "Starting regression tests in Docker containers..."
	@count=0; \
	for case in $(CASES); do \
		while [ $$count -ge $(MAX_CONTAINERS) ]; do \
			sleep 10; \
			count=$$(sudo docker ps -q | wc -l); \
		done; \
		echo "Starting case $$case in Docker container..."; \
		sudo docker run -d --rm \
			-v $(CURDIR):/workspace \
			--mac-address $(MAC_ADDRESS) \
			--name case_$$case \
			questasim-image \
			/bin/bash -c "cd /workspace && make run CASE=$$case"; \
		count=$$((count + 1)); \
	done; \
	echo "Waiting for all Docker containers to finish..."; \
	while [ $$(sudo docker ps -q | wc -l) -gt 0 ]; do \
		sleep 10; \
	done; \
	echo "All Docker containers have finished."
	make collect_results

mergecover:
#	rm ${SIM_DIR}/top_merge.ucdb
	vcover merge ${SIM_DIR}/top_merge.ucdb ${SIM_DIR}/*.ucdb 

viewcover:
	vsim -viewcov ${SIM_DIR}/top_merge.ucdb

prj:
	vivado pms.xpr

help:
	@echo "可用目标:"
	@echo "  fmt        - format source file"
	@echo "  clean_sim  - clean all sim files which are not registered in git"
	@echo "  clean_bit  - clean all syn + imp + bit files which are not registered in git"
	@echo "  clean      - clean all sim files which are not registered in git"
	@echo "  bit        - gen bitfile"
	@echo "  sim        - gensim comp elab run, should do 'make bit' first to generate IP files"
	@echo "  regrdock   - regression test case"
	@echo "  wave       - 查看波形"
	@echo "  mergecover - merger every case's ucdb to one top ucdb file"
	@echo "  viewcover  - view coverage report"
	@echo "  e.g. 1: make sim CASE=0"
