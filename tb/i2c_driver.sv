class i2c_driver extends uvm_driver #(transaction);
    `uvm_component_utils(i2c_driver)

    virtual i2c_i vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual i2c_i)::get(this, "", "vif", vif))
            `uvm_fatal("NO_VIF", "Driver could not get virtual interface")
    endfunction

    task run_phase(uvm_phase phase);
        transaction req;

        forever begin
            seq_item_port.get_next_item(req);
            drive(req);
            seq_item_port.item_done();
        end
    endtask

    task drive(transaction tx);

        @(vif.driver_cb);

        vif.driver_cb.wr   <= tx.wr;
        vif.driver_cb.addr <= tx.addr;

        if(tx.wr == 1)
            vif.driver_cb.din <= tx.din;
        else
            vif.driver_cb.din <= 0;

               while (vif.driver_cb.done !== 1'b1) begin
            @(vif.driver_cb);
        end

        if(tx.wr == 0) begin
            tx.datard = vif.driver_cb.datard;
        end else begin
            tx.datard = 0;
        end

        vif.driver_cb.wr   <= 0;
        vif.driver_cb.addr <= 0;
        vif.driver_cb.din  <= 0;

    endtask
endclass

