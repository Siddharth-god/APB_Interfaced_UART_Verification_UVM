
//xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx ENV xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

//-----------------------------------------------------ENV-------------------------------------------------------
class env extends uvm_env;
    `uvm_component_utils(env)

    apb_agent_top apb_agent_top_h; 
    uart_agent_top uart_agent_top_h;
    //vseqr vseqrh;
    sb sb_h; 
    uart_reg_block regmodel;
    env_config env_cfg; 

    function new(string name="",uvm_component parent);
        super.new(name,parent);
    endfunction 

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if(!uvm_config_db #(env_config)::get(this,"","env_config",env_cfg))
            `uvm_fatal(get_type_name(),"Failed to get env_cfg from TEST")

            $display(" ENV --uart vif-- ==> %p",env_cfg.uart_cfg.vif);
            $display(" ENV CONFIG -- apb cfg captured vif %p",env_cfg.apb_cfg);
            $display(" ENV CONFIG -- uart cfg captured vif %p",env_cfg.uart_cfg);

        
            // 1. Create regmodel
            regmodel = uart_reg_block::type_id::create("regmodel", this);

            // 2. Build it
            regmodel.build();
            regmodel.lock_model();

            // 3. Attach it to env_cfg
            env_cfg.regmodel = regmodel;

            // 4. Send env_cfg forward
            uvm_config_db#(env_config)::set(this, "*", "env_config", env_cfg);


        // set apb_cfg and create the apb agent top 
        if(env_cfg.has_apb_agent)
            begin 
                apb_agent_top_h = apb_agent_top::type_id::create("apb_agent_top_h",this);
                uvm_config_db #(apb_agent_config)::set(this,"apb_agent_top*","apb_agent_config",env_cfg.apb_cfg);
            end


        // set uart_cfg and create the uart agent top 
        if(env_cfg.has_uart_agent)
            begin 
                $display(" ENV --has uart agent-- ==> %0d",env_cfg.has_uart_agent);

                uart_agent_top_h = uart_agent_top::type_id::create("uart_agent_top_h",this);
                uvm_config_db #(uart_agent_config)::set(this,"uart_agent_top*","uart_agent_config",env_cfg.uart_cfg);
            end

        sb_h = sb::type_id::create("sb_h",this);
    endfunction 

    function void connect_phase(uvm_phase phase);
        apb_agent_top_h.apb_agent_h.apb_mon_h.apb_mon_port.connect(sb_h.fifo_apb.analysis_export);
        uart_agent_top_h.uart_agent_h.uart_mon_h.uart_mon_port.connect(sb_h.fifo_uart.analysis_export);
    endfunction
endclass 
