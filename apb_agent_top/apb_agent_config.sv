//-----------------------------------------------------APB CONFIG-------------------------------------------------------
// agent Config class 
class apb_agent_config extends uvm_object;
    `uvm_object_utils(apb_agent_config)

    function new(string name="apb_agent_config");
        super.new(name);
    endfunction 

    virtual apb_if vif; 
    uvm_active_passive_enum is_active = UVM_ACTIVE;
endclass 