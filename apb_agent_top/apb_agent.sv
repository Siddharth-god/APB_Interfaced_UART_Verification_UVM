
//xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx AGENTS xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

//-----------------------------------------------------APB AGENT-------------------------------------------------------

class apb_agent extends uvm_agent;
    `uvm_component_utils(apb_agent)

    apb_drv apb_drv_h; 
    apb_mon apb_mon_h; 
    apb_seqr apb_seqr_h; 

    apb_agent_config apb_cfg; 


    function new(string name="",uvm_component parent);
        super.new(name,parent);
    endfunction 

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

         if(!uvm_config_db #(apb_agent_config)::get(this,"","apb_agent_config",apb_cfg))
            `uvm_fatal(get_type_name(),"Failed to get() apb_cfg from ENV")

        apb_mon_h = apb_mon::type_id::create("apb_mon_h",this);

        if(apb_cfg.is_active == UVM_ACTIVE) begin 
            apb_drv_h = apb_drv::type_id::create("apb_drv_h",this);
            apb_seqr_h = apb_seqr::type_id::create("apb_seqr_h",this);
        end
    endfunction 

    function void connect_phase(uvm_phase phase);
        if(apb_cfg.is_active == UVM_ACTIVE) begin 
            apb_drv_h.seq_item_port.connect(apb_seqr_h.seq_item_export);
        end
    endfunction 
endclass 
