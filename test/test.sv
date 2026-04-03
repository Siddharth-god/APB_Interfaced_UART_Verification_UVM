//xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx TEST xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

//-----------------------------------------------------TEST-------------------------------------------------------\
class test extends uvm_test;
    `uvm_component_utils(test)

    env envh;
    vseq vseqh; 
    env_config env_cfg; 
    apb_agent_config apb_cfg; 
    uart_agent_config uart_cfg; 
    // apb_half_duplex apb_half_duplex_h;
    // apb_read_seq apb_read_seq_h; 

    
    int has_apb_agent = 1; 
    //env_cfg.has_uart_agent = 1; // why this will throw error ?? 
    int has_uart_agent = 1; 
    bit [7:0] lcr; 

    function new(string name="",uvm_component parent);
        super.new(name,parent);
    endfunction 

    function void create_config();
        if(has_apb_agent)
            begin 
                $display(" TEST BASE --has apb agent-- ==> %0d",has_apb_agent);

                apb_cfg = apb_agent_config::type_id::create("apb_cfg");

                if(!uvm_config_db #(virtual apb_if)::get(this,"","apb_if",apb_cfg.vif))
                    `uvm_fatal(get_type_name(),"Failed to get vif from TOP")

                $display(" TEST BASE -- apb cfg captured vif from TOP %p",apb_cfg);
                
                apb_cfg.is_active = UVM_ACTIVE; 
                env_cfg.apb_cfg = apb_cfg; // handle assignment to apb agent inside env config
            end

        if(has_uart_agent)
             begin 
                $display(" TEST BASE --has uart agent-- ==> %0d",has_uart_agent);

                uart_cfg = uart_agent_config::type_id::create("uart_cfg");

                if(!uvm_config_db #(virtual uart_if)::get(this,"","uart_if",uart_cfg.vif))
                    `uvm_fatal(get_type_name(),"Failed to get vif from TOP")

                $display(" TEST BASE -- uart cfg captured vif from TOP %p",uart_cfg);

                uart_cfg.is_active = UVM_ACTIVE; 
                env_cfg.uart_cfg = uart_cfg; // handle assignment to apb agent inside env config
            end

        env_cfg.has_apb_agent = has_apb_agent; 
        env_cfg.has_uart_agent = has_uart_agent; 
    endfunction 


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env_cfg = env_config::type_id::create("env_cfg");
        lcr = 8'h03;
        // call config function 
        create_config();

        uvm_config_db #(env_config)::set(this,"env*","env_config",env_cfg);
        $display("------env config has %p",env_cfg);

        uvm_config_db #(bit [7:0])::set(this,"*","lcr",lcr);
        $display("lcr value in half_duplex_test = %p",lcr);

        vseqh = vseq::type_id::create("vseqh");
        envh = env::type_id::create("envh",this);
    endfunction 

    function void end_of_elaboration_phase(uvm_phase phase);
        uvm_top.print_topology();
    endfunction 
/*
    task run_phase(uvm_phase phase);
        apb_half_duplex_h = apb_half_duplex::type_id::create("apb_half_duplex_h");
        apb_read_seq_h    = apb_read_seq::type_id::create("apb_read_seq_h");

        phase.raise_objection(this);
        apb_half_duplex_h.start(envh.apb_agent_top_h.apb_agent_h.apb_seqr_h);
        apb_read_seq_h.start(envh.apb_agent_top_h.apb_agent_h.apb_seqr_h);
        #87000;
        phase.drop_objection(this);
    endtask
        */
endclass 


//---------------------------------------------------- Half Duplex Test -------------------------------------------

class half_duplex_test extends test; 
    `uvm_component_utils(half_duplex_test)

    function new(string name="",uvm_component parent);
        super.new(name,parent);
    endfunction

    apb_half_duplex apb_half_duplex_h; 
    apb_read_seq apb_read_seq_h; 
    uart_half_duplex uart_half_duplex_h; 
    //bit [7:0] lcr; 

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        super.lcr = 8'h04;  //====> For half duplex, only the data length can be configured, nothing else changes so we can directly configure like this.

        // uvm_config_db #(bit [7:0])::set(this,"*","lcr",lcr);
        // $display("lcr value in half_duplex_test = %p",lcr);
    endfunction 

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        apb_half_duplex_h = apb_half_duplex::type_id::create("apb_half_duplex_h");
        apb_read_seq_h    = apb_read_seq::type_id::create("apb_read_seq_h");
        uart_half_duplex_h = uart_half_duplex::type_id::create("uart_half_duplex_h");
        phase.raise_objection(this);

        apb_half_duplex_h.start(envh.apb_agent_top_h.apb_agent_h.apb_seqr_h);
        uart_half_duplex_h.start(envh.uart_agent_top_h.uart_agent_h.uart_seqr_h);
        apb_read_seq_h.start(envh.apb_agent_top_h.apb_agent_h.apb_seqr_h); // Whenever dut receives something then only checking happens, here DUT will receive from UART agent. So after that we can read.  


        phase.phase_done.set_drain_time(this,200000);
        phase.drop_objection(this);
    endtask


endclass 