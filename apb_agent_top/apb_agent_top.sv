//-----------------------------------------------------APB AGT TOP-------------------------------------------------------

class apb_agent_top extends uvm_agent; 
    `uvm_component_utils(apb_agent_top)

    apb_agent apb_agent_h;

    function new(string name="",uvm_component parent);
        super.new(name,parent);
    endfunction 

    function void build_phase(uvm_phase phase);
        apb_agent_h = apb_agent::type_id::create("apb_agent_h",this);
    endfunction 
endclass 
