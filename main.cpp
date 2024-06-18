#include <iostream>
#include <bitset>

#include "Vtop.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

template <class Vmod> class tb
{
public:
    Vmod *m_core;
    VerilatedVcdC *m_trace;
    uint64_t m_tickcount;
    
    tb(const char* vcd): m_core(nullptr), m_tickcount(0) {
        m_core = new Vmod;
        Verilated::traceEverOn(true);
        open_trace(vcd);
        m_core->clk = 0;
        m_core->eval();
    }

    virtual void open_trace(const char *vcd) {
        m_trace = new VerilatedVcdC;
        m_core->trace(m_trace, 128);
        m_trace->open(vcd);
        if (!m_trace) {
            std::cerr << "invalid vcd" << std::endl;
            abort();
        }
    }

    virtual void eval() {
        m_core->eval();
    }

    virtual void tick() {
        m_core->eval();
        m_trace->dump(++m_tickcount * 32768);
        m_core->clk = 1;
        m_core->eval();
        m_trace->dump(++m_tickcount * 32768);
        m_core->clk = 0;
        m_core->eval();
        m_trace->dump(++m_tickcount * 32768);
    }

    ~tb() { m_trace->close(); delete m_core; };
};

class uartsim
{
public:
    uint64_t baud_count;
    uint64_t counter;
    uint64_t state;
    uint64_t bit;
    std::bitset<8> buff;

    uartsim(uint64_t baud_count): baud_count(baud_count),
        counter(baud_count), state(0), bit(0), buff(0) {};

    void eval(unsigned char rx);
};

void uartsim::eval(unsigned char rx)
{
    if (!state) {
        if (!rx)
            ++state;
    }

    else if (counter == 0) {
        /* start bit */
        if (state == 1) {
            counter = baud_count;
            ++state;
            return;
        }

        /* stop bit */
        if (state == 10) {
            state = 0;
            bit = 0;
            std::cout << (char)buff.to_ulong();
            return;
        }

        buff[bit] = rx;
        ++bit;
        ++state;
        counter = baud_count;

    } else --counter;
}

int main(int argc, char **argv) {
    std::cout << "simulation begins" << std::endl;
    Verilated::commandArgs(argc, argv);

    tb<Vtop> vtop_tb("trace.vcd");

    uartsim *uart = new uartsim(105);

    // create new testbench
    for (int i = 0; i < 8192; ++i) {
        vtop_tb.tick();
        uart->eval(vtop_tb.m_core->uart_rxd_out);
    }

    return 0;
}
