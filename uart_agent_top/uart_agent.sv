
//-----------------------------------------------------UART AGENT-------------------------------------------------------
class uart_agent extends uvm_agent;
    `uvm_component_utils(uart_agent)
    
    uart_drv uart_drv_h; 
    uart_mon uart_mon_h; 
    uart_seqr uart_seqr_h;

    uart_agent_config uart_cfg; 

    function new(string name="",uvm_component parent);
        super.new(name,parent);
    endfunction 

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if(!uvm_config_db #(uart_agent_config)::get(this,"","uart_agent_config",uart_cfg))
            `uvm_fatal(get_type_name(),"Failed to get() uart_cfg from ENV")

        uart_mon_h = uart_mon::type_id::create("uart_mon_h",this);

        if(uart_cfg.is_active == UVM_ACTIVE) begin   
            uart_drv_h = uart_drv::type_id::create("uart_drv_h",this);
            uart_seqr_h = uart_seqr::type_id::create("uart_seqr_h",this);
        end
    endfunction 

    function void connect_phase(uvm_phase phase);
        if(uart_cfg.is_active == UVM_ACTIVE) begin 
            uart_drv_h.seq_item_port.connect(uart_seqr_h.seq_item_export);
        end
    endfunction 
endclass 
