//-----------------------------------------------------UART AGT TOP-------------------------------------------------------
class uart_agent_top extends uvm_agent; 
    `uvm_component_utils(uart_agent_top)

    uart_agent uart_agent_h; 

    function new(string name="",uvm_component parent);
        super.new(name,parent);
    endfunction 

    function void build_phase(uvm_phase phase);
        uart_agent_h = uart_agent::type_id::create("uart_agent_h",this);
    endfunction 
endclass 
