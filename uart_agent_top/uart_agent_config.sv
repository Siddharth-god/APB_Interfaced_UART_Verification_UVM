//-----------------------------------------------------UART CONFIG------------------------------------------------------
class uart_agent_config extends uvm_object;
    `uvm_object_utils(uart_agent_config)

    function new(string name="uart_agent_config");
        super.new(name);
    endfunction 

    virtual uart_if vif; 
    uvm_active_passive_enum is_active = UVM_ACTIVE;
endclass 