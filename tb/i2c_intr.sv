`timescale 1ns / 1ps

interface i2c_i;
    logic        clk;
    logic        rst;
    logic        wr;
    logic [6:0]  addr;
    logic [7:0]  din;
    logic [7:0]  datard;
    logic        done;
    logic        scl;
    wire         sda;    
 
 clocking driver_cb @(posedge clk);
    default input #0ns output #0ns; // Defines setup/hold skews to prevent race conditions
    input  datard, done, scl;       // Monitored by the testbench environment
    output wr, addr, din;           // Driven by the testbench environment
    inout  sda;                     // Shared bidirectional data line
 endclocking

endinterface


