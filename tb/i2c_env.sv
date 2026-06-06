class env extends uvm_env;
`uvm_component_utils(env)
 
function new(input string inst = "env", uvm_component c);
super.new(inst,c);
endfunction
 
agent a;
//sco s;
 
function void build_phase(uvm_phase phase);
super.build_phase(phase);
  a = agent::type_id::create("a",this);
 // s = sco::type_id::create("s", this);
endfunction
 
/* function void connect_phase(uvm_phase phase);
  agent.i2c_monitor.ap.connect(s.analysis_export);
endfunction */
endclass

