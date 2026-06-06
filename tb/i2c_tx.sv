 class transaction extends uvm_sequence_item;
  `uvm_object_utils(transaction)
    rand logic        wr;
    rand logic [6:0]  addr;
    rand logic [7:0]  din;
    logic [7:0]  datard;
    logic        ack_err;        
    function new(string name = "transaction");
        super.new(name);
    endfunction 
endclass 
