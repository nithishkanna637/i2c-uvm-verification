class i2c_monitor extends uvm_monitor;
    `uvm_component_utils(i2c_monitor)

    virtual i2c_i vif;
    uvm_analysis_port #(transaction) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db #(virtual i2c_i)::get(this, "", "vif", vif))
            `uvm_fatal("NO_VIF", "Monitor could not get virtual interface")
    endfunction

    task run_phase(uvm_phase phase);
    transaction trans;
    forever begin
        trans = transaction::type_id::create("trans");
        wait(vif.done == 1);
        @(posedge vif.clk);
        trans.wr     = vif.wr;
        trans.addr   = vif.addr;
        trans.din    = vif.din;
        trans.datard = vif.datard;
        ap.write(trans);
    end
    endtask
endclass
