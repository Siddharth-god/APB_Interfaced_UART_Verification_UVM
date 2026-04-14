
//xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx TEST xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

//-----------------------------------------------------TEST-------------------------------------------------------\
class base_test extends uvm_test;
    `uvm_component_utils(base_test)

    env envh;
    //vseq vseqh; 
    env_config env_cfg; 
    apb_agent_config apb_cfg; 
    uart_agent_config uart_cfg; 
    // apb_half_duplex apb_half_duplex_h;
    // apb_read_seq apb_read_seq_h; 

   // uart_reg_block regmodel; 

    int has_no_of_agent = 1;
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

        // if(has_uart_agent)
        //     begin 
        //         $display(" TEST BASE --has uart agent-- ==> %0d",has_uart_agent);

        //         uart_cfg = new[has_no_of_agent]; 
        //             foreach(uart_cfg[i]) begin 
        //                 uart_cfg[i] = uart_agent_config::type_id::create($sformatf("uart_cfg[%0d]",i));

        //             //uart_cfg = uart_agent_config::type_id::create("uart_cfg");

        //             if(!uvm_config_db #(virtual uart_if)::get(this,"",$sformatf("uart_if[%0d]",i),uart_cfg[i].vif))
        //                 `uvm_fatal(get_type_name(),"Failed to get vif from TOP")

        //             $display(" TEST BASE -- uart cfg captured vif from TOP %p",uart_cfg);

        //             uart_cfg[i].is_active = UVM_ACTIVE; 
        //             env_cfg.uart_cfg[i] = uart_cfg[i]; // handle assignment to apb agent inside env config
        //         end
        //     end

        env_cfg.has_apb_agent = has_apb_agent; 
        env_cfg.has_uart_agent = has_uart_agent; 
    endfunction 


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env_cfg = env_config::type_id::create("env_cfg");
        lcr = 8'h3;
        // if(has_uart_agent)
        //     env_cfg.uart_cfg = new[has_no_of_agent];
        // call config function 
        create_config();


        //regmodel = uart_reg_block::type_id::create("regmodel");
        //regmodel.build(); 
        //env_cfg.regmodel = this.regmodel; 

        uvm_config_db #(env_config)::set(this,"env*","env_config",env_cfg);
        $display("------env config has %p",env_cfg);

        uvm_config_db #(bit [7:0])::set(this,"*","lcr",lcr);
        $display("lcr value in half_duplex_test = %p",lcr);

        //vseqh = vseq::type_id::create("vseqh");
        envh = env::type_id::create("envh",this);
    endfunction 
endclass 


//---------------------------------------------------- Half Duplex Test -------------------------------------------

class half_duplex_test extends base_test; 
    `uvm_component_utils(half_duplex_test)

    function new(string name="",uvm_component parent);
        super.new(name,parent);
    endfunction

    apb_half_duplex apb_half_duplex_h; 
    apb_read_seq apb_read_seq_h; 
    uart_half_duplex uart_half_duplex_h; 
    //bit [7:0] lcr; 

    function void build_phase(uvm_phase phase);
        super.lcr = 8'h03;  // why is this not working ? 
        super.build_phase(phase);
    endfunction 

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        apb_half_duplex_h = apb_half_duplex::type_id::create("apb_half_duplex_h");
        apb_read_seq_h    = apb_read_seq::type_id::create("apb_read_seq_h");
        uart_half_duplex_h = uart_half_duplex::type_id::create("uart_half_duplex_h");

        phase.raise_objection(this);
            // Apb configures the DUT so we must pass apb seq first and for half duplex we think we don't need to pass half duplex right, but no without passing half duplex seq uart regs won't be configured so can't just use read seq.
        //fork // also works we must make sure read happens after uart seq comes and we must configure regs using apb half duplex
            begin 
                apb_half_duplex_h.start(envh.apb_agent_top_h.apb_agent_h.apb_seqr_h);
                uart_half_duplex_h.start(envh.uart_agent_top_h.uart_agent_h.uart_seqr_h); // why it will not work outside ? why only in fork join ?? 

                apb_read_seq_h.start(envh.apb_agent_top_h.apb_agent_h.apb_seqr_h); // read always should happen after we get the data from uart else agar read happens first irq happens early and when apb mon is trying to sample and trying to get irq it will not be there as read already happened and uart_agent data comes late
            end
            // begin   
            //     #500;
                    //apb_read_seq_h.start(envh.apb_agent_top_h.apb_agent_h.apb_seqr_h); --> This will work
            // end
        //join_none  /// kyuuuuuuuuuuuuu it is working(this also works). why we need to pass uart just little late ? --> wait but to make half duplex work we need to read the rbr values right but that to happen we need something coming and that data is sent by uart and that is why we need to run uart at the same time or little early of read else read seq khatam ho jayega and we will keep waiting for irq to go high which already happened. (ask sir or gpt after exam)
                // #500;
                // apb_read_seq_h.start(envh.apb_agent_top_h.apb_agent_h.apb_seqr_h); ==> This will also work
        phase.phase_done.set_drain_time(this,200000);
        
        phase.drop_objection(this);
    endtask


endclass 

//---------------------------------------------------- Full Duplex Test -------------------------------------------

class full_duplex_test extends base_test; 
    `uvm_component_utils(full_duplex_test)

    function new(string name="",uvm_component parent);
        super.new(name,parent);
    endfunction

    apb_full_duplex apb_full_duplex_h; 
    apb_read_seq apb_read_seq_h; 
    uart_full_duplex uart_full_duplex_h; 
    //bit [7:0] lcr; 

    function void build_phase(uvm_phase phase);
        super.lcr = 8'h03;  // why is this not working ? 
        super.build_phase(phase);
    endfunction 

    task run_phase(uvm_phase phase);

        $display("---------------<<<<<xxxxxxxxxx FULL DUPLEX RUNNING xxxxxxxxxx>>>>>---------------");
        super.run_phase(phase);
        apb_full_duplex_h = apb_full_duplex::type_id::create("apb_full_duplex_h");
        apb_read_seq_h    = apb_read_seq::type_id::create("apb_read_seq_h");
        uart_full_duplex_h = uart_full_duplex::type_id::create("uart_full_duplex_h");

        phase.raise_objection(this);
        fork
            begin 
                apb_full_duplex_h.start(envh.apb_agent_top_h.apb_agent_h.apb_seqr_h); 
                apb_read_seq_h.start(envh.apb_agent_top_h.apb_agent_h.apb_seqr_h); 
            end
            begin 
                uart_full_duplex_h.start(envh.uart_agent_top_h.uart_agent_h.uart_seqr_h);
            end
        join
        phase.phase_done.set_drain_time(this,200000);
        
        phase.drop_objection(this);
    endtask


endclass 


//---------------------------------------------------- Loopback Test -------------------------------------------

class loopback_test extends base_test; 
    `uvm_component_utils(loopback_test)

    function new(string name="",uvm_component parent);
        super.new(name,parent);
    endfunction

    apb_loopback apb_loopback_h; 
    apb_read_seq apb_read_seq_h; 

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction 

    task run_phase(uvm_phase phase);

        $display("---------------<<<<<xxxxxxxxxx Loopback is RUNNING xxxxxxxxxx>>>>>---------------");
        super.run_phase(phase);
        apb_loopback_h = apb_loopback::type_id::create("apb_loopback_h");
        apb_read_seq_h = apb_read_seq::type_id::create("apb_read_seq_h");

        phase.raise_objection(this);
            apb_loopback_h.start(envh.apb_agent_top_h.apb_agent_h.apb_seqr_h); 
            apb_read_seq_h.start(envh.apb_agent_top_h.apb_agent_h.apb_seqr_h); 
        phase.phase_done.set_drain_time(this,200000);
        
        phase.drop_objection(this);
    endtask


endclass 


//---------------------------------------------------- Overrun Test -------------------------------------------

class overrun_test extends base_test; 
    `uvm_component_utils(overrun_test)

    function new(string name="",uvm_component parent);
        super.new(name,parent);
    endfunction

    apb_overrun_seq apb_overrun_seq_h; // This has read sequence inside
    uart_overrun_seq uart_overrun_seq_h;
    apb_read_seq apb_read_seq_h; 

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction 

    task run_phase(uvm_phase phase);

        $display("---------------<<<<<xxxxxxxxxx Overrun is RUNNING xxxxxxxxxx>>>>>---------------");
        super.run_phase(phase);
        apb_overrun_seq_h = apb_overrun_seq::type_id::create("apb_overrun_seq_h");
        uart_overrun_seq_h = uart_overrun_seq::type_id::create("uart_overrun_seq_h");
        apb_read_seq_h = apb_read_seq::type_id::create("apb_read_seq_h");

        phase.raise_objection(this);
        fork 
            begin 
                apb_overrun_seq_h.start(envh.apb_agent_top_h.apb_agent_h.apb_seqr_h);
                apb_read_seq_h.start(envh.apb_agent_top_h.apb_agent_h.apb_seqr_h); 
            end
            begin 
                uart_overrun_seq_h.start(envh.uart_agent_top_h.uart_agent_h.uart_seqr_h); 
            end
        join
        phase.phase_done.set_drain_time(this,200000);
        
        phase.drop_objection(this);
    endtask


endclass 


//---------------------------------------------------- Overrun Test -------------------------------------------

class framing_test extends base_test; 
    `uvm_component_utils(framing_test)

    function new(string name="",uvm_component parent);
        super.new(name,parent);
    endfunction

    apb_framing_seq apb_framing_seq_h; // This has read sequence inside
    uart_framing_seq uart_framing_seq_h;
    apb_read_seq apb_read_seq_h; 

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction 

    task run_phase(uvm_phase phase);

        $display("---------------<<<<<xxxxxxxxxx Framing is RUNNING xxxxxxxxxx>>>>>---------------");
        super.run_phase(phase);
        apb_framing_seq_h = apb_framing_seq::type_id::create("apb_framing_seq_h");
        uart_framing_seq_h = uart_framing_seq::type_id::create("uart_framing_seq_h");
        apb_read_seq_h = apb_read_seq::type_id::create("apb_read_seq_h");

        phase.raise_objection(this);
        fork 
            begin 
                apb_framing_seq_h.start(envh.apb_agent_top_h.apb_agent_h.apb_seqr_h);
                apb_read_seq_h.start(envh.apb_agent_top_h.apb_agent_h.apb_seqr_h); 
            end
            begin 
                uart_framing_seq_h.start(envh.uart_agent_top_h.uart_agent_h.uart_seqr_h); 
            end
        join
        phase.phase_done.set_drain_time(this,200000);
        
        phase.drop_objection(this);
    endtask


endclass 