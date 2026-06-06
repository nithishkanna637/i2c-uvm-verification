module tb;

    i2c_i pif();
    pullup(pif.sda);

    i2c_master i2c_master(
        .clk(pif.clk), .rst(pif.rst), .wr(pif.wr),
        .addr(pif.addr), .din(pif.din),
        .datard(pif.datard), .done(pif.done),
        .scl(pif.scl), .sda(pif.sda)
    );

    i2c_slave i2c_slave(
        .rst(pif.rst), .scl(pif.scl), .sda(pif.sda)
    );

    initial begin
       pif.clk=0;
       forever #5 pif.clk=~pif.clk;
    end

    initial begin
        pif.rst=1;
		repeat(2) @(posedge pif.clk);
		pif.rst=0;
    end

    initial begin
        uvm_config_db#(virtual i2c_i)::set(null, "*", "vif", pif);
        run_test("test");
    end

    initial begin
        #20000;              
		$finish;
    end

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars;
    end

endmodule
