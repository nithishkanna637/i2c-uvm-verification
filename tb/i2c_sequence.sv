class i2c_sequence extends uvm_sequence #(transaction);
`uvm_object_utils(i2c_sequence)
function new(string name="");
  super.new(name);
endfunction
endclass

class write_data extends i2c_sequence;
    `uvm_object_utils(write_data)
    function new(string name = "write_data");
        super.new(name);
    endfunction
    task body();
        transaction req;

        // write 0xAB to address 0x27
		$display("sequence 1 is happening ");
        `uvm_do_with(req, {req.wr==1; req.addr==7'h27; req.din==8'hAB;})
		$display("sequence 2 is happening ");
        // read back from address 0x27
       `uvm_do_with(req, {req.wr==0; req.addr==7'h27; req.din==8'h00;})
		$display("sequence 3 is happening ");
        
    endtask
endclass
