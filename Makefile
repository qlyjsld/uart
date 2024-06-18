CC = g++
BEAR = bear
VINC = /usr/share/verilator/include
OBJ_DIR = $(PWD)/obj_dir
CFLAGS = -I $(VINC) -I $(OBJ_DIR)
MODULE = top

.PHONY: all
all: v main

main: main.cpp $(OBJ_DIR)/V$(MODULE)__ALL.a
	cd $(OBJ_DIR) && $(BEAR) --output ../compile_commands.json -- \
		$(CC) $(CFLAGS) $(VINC)/verilated.cpp \
		$(VINC)/verilated_threads.cpp \
		$(VINC)/verilated_vcd_c.cpp \
		../main.cpp \
		V$(MODULE)__ALL.a \
		-o ../a.out

v: $(MODULE).v
	verilator -Wall --trace -cc $(MODULE).v && cd obj_dir && $(MAKE) -f V$(MODULE).mk

.PHONY: clean
clean:
	rm -rf $(OBJ_DIR) compile_commands.json a.out