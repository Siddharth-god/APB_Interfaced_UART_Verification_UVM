//-----------------------------------------------------ENV CONFIG------------------------------------------------------
class env_config extends uvm_object;
    `uvm_object_utils(env_config)

    uart_agent_config uart_cfg; 
    apb_agent_config apb_cfg;
    uart_reg_block regmodel; 

    function new(string name="env_config");
        super.new(name);

    endfunction 

    // virtual apb_if vif; //==> This should not be in the env config keep it always only in agent configs 

    int has_apb_agent;
    int has_uart_agent; 
    int has_sb;

endclass