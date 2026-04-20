
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
        // lcr = 8'h3;
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

        //vseqh = vseq::type_id::create("vseqh");
        envh = env::type_id::create("envh",this);
    endfunction 
endclass 

//---------------------------------------------------- Half Duplex Test -------------------------------------------


class reset_test extends base_test; 
    `uvm_component_utils(reset_test)

    function new(string name="",uvm_component parent);
        super.new(name,parent);
    endfunction

    apb_rst_check apb_rst_check_h;
    
    function void build_phase(uvm_phase phase);
        super.lcr = 8'h03;  // why is this not working ? 
        super.build_phase(phase);
    endfunction 

    task run_phase(uvm_phase phase);
        apb_rst_check_h = apb_rst_check::type_id::create("apb_rst_check_h");

        phase.raise_objection(this);
        apb_rst_check_h.start(envh.apb_agent_top_h.apb_agent_h.apb_seqr_h);
        phase.drop_objection(this);
    endtask
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
        super.lcr = 8'h03; 
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

class overrun_test extends base_test;  // Working fine 
    `uvm_component_utils(overrun_test)

    function new(string name="",uvm_component parent);
        super.new(name,parent);
    endfunction

    apb_overrun_seq apb_overrun_seq_h; // This has read sequence inside
    uart_overrun_seq uart_overrun_seq_h;
    apb_read_seq apb_read_seq_h; 

    function void build_phase(uvm_phase phase);
        super.lcr = 8'h03; // If this is set before super.buildphase then build phase will override super.lcr with it's own values so always set it after super.buildphase. (but setting it later will miss the setting as set happens in base build so we remove hardcode of lcr in base and set it first then call build super so now it sets properly)
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
            uart_overrun_seq_h.start(envh.uart_agent_top_h.uart_agent_h.uart_seqr_h); 
        join_none // Let UART run in background
            apb_overrun_seq_h.start(envh.apb_agent_top_h.apb_agent_h.apb_seqr_h);
        wait fork; // Wait for UART to finish all 17 frames
            apb_read_seq_h.start(envh.apb_agent_top_h.apb_agent_h.apb_seqr_h);
    /*
    `join_none` launches UART in background, APB config runs in foreground at the same time. `wait fork` just ensures read sequence only fires after UART finishes all 17 frames — because only then is the FIFO full and IRQ asserted, which is what the read sequence needs to check.        
    */

        phase.phase_done.set_drain_time(this,200000);
        
        phase.drop_objection(this);
    endtask


endclass 


//---------------------------------------------------- Framing Test -------------------------------------------

class framing_test extends base_test; 
    `uvm_component_utils(framing_test)

    function new(string name="",uvm_component parent);
        super.new(name,parent);
    endfunction

    apb_framing_seq apb_framing_seq_h; // This has read sequence inside
    uart_framing_seq uart_framing_seq_h;
    apb_read_seq apb_read_seq_h; 

    function void build_phase(uvm_phase phase);
        super.lcr = 8'h03;
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
            end
            begin 
                uart_framing_seq_h.start(envh.uart_agent_top_h.uart_agent_h.uart_seqr_h); 
            end
        join
        wait fork; 
            apb_read_seq_h.start(envh.apb_agent_top_h.apb_agent_h.apb_seqr_h); 

        phase.phase_done.set_drain_time(this,200000);
        
        phase.drop_objection(this);
    endtask


endclass 


//---------------------------------------------------- Parity Test -------------------------------------------

class parity_test extends base_test; 
    `uvm_component_utils(parity_test)

    function new(string name="",uvm_component parent);
        super.new(name,parent);
    endfunction

    apb_parity_seq apb_parity_seq_h; // This has read sequence inside
    uart_parity_seq uart_parity_seq_h;
    apb_read_seq apb_read_seq_h; 

    function void build_phase(uvm_phase phase);
        super.lcr = 8'h0B; // B = 1011 (so 1 stop bit only)
        super.build_phase(phase);
    endfunction 

    task run_phase(uvm_phase phase);

        $display("---------------<<<<<xxxxxxxxxx Parity is RUNNING xxxxxxxxxx>>>>>---------------");
        super.run_phase(phase);
        apb_parity_seq_h = apb_parity_seq::type_id::create("apb_parity_seq_h");
        uart_parity_seq_h = uart_parity_seq::type_id::create("uart_parity_seq_h");
        apb_read_seq_h = apb_read_seq::type_id::create("apb_read_seq_h");

        phase.raise_objection(this);

        fork 
            uart_parity_seq_h.start(envh.uart_agent_top_h.uart_agent_h.uart_seqr_h); 
        join_none
            apb_parity_seq_h.start(envh.apb_agent_top_h.apb_agent_h.apb_seqr_h);

        wait fork; // Wait for uart and apb sequence to be completed. Then read. 
            apb_read_seq_h.start(envh.apb_agent_top_h.apb_agent_h.apb_seqr_h); 

        phase.phase_done.set_drain_time(this,200000);
        
        phase.drop_objection(this);
    endtask


endclass 


//---------------------------------------------------- Break Test -------------------------------------------

class break_test extends base_test; 
    `uvm_component_utils(break_test)

    function new(string name="",uvm_component parent);
        super.new(name,parent);
    endfunction

    apb_break_seq apb_break_seq_h; // This has read sequence inside
    uart_break_seq uart_break_seq_h;
    apb_read_seq apb_read_seq_h; 

    function void build_phase(uvm_phase phase);
        // super.lcr = 8'b0100_0011;
        super.lcr = 8'b0000_0011; // lcr made 3
        super.build_phase(phase);
    /*
    The UART agent is the one creating the break condition by sending stop_bit=0. The DUT's LCR[6] is irrelevant here because:
    LCR[6]=1 would make the DUT's own TX hold low — that's for testing the other side
    You're testing the DUT's RX, so the break comes from the UART agent side    
    */
    endfunction 

    task run_phase(uvm_phase phase);

        $display("---------------<<<<<xxxxxxxxxx Break is RUNNING xxxxxxxxxx>>>>>---------------");
        super.run_phase(phase);
        apb_break_seq_h = apb_break_seq::type_id::create("apb_break_seq_h");
        uart_break_seq_h = uart_break_seq::type_id::create("uart_break_seq_h");
        apb_read_seq_h = apb_read_seq::type_id::create("apb_read_seq_h");

        phase.raise_objection(this);

        fork 
            uart_break_seq_h.start(envh.uart_agent_top_h.uart_agent_h.uart_seqr_h); 
        join_none
            apb_break_seq_h.start(envh.apb_agent_top_h.apb_agent_h.apb_seqr_h);
        wait fork;   
            apb_read_seq_h.start(envh.apb_agent_top_h.apb_agent_h.apb_seqr_h);
        /*
        Break was failing and "framing was coming" Becasue read was happening before uart_break_seq was completed.
        */
        phase.phase_done.set_drain_time(this,200000);
        
        phase.drop_objection(this);
    endtask


endclass 


//---------------------------------------------------- timeout Test -------------------------------------------

class timeout_test extends base_test; 
    `uvm_component_utils(timeout_test)

    function new(string name="",uvm_component parent);
        super.new(name,parent);
    endfunction

    apb_timeout_seq apb_timeout_seq_h; // This has read sequence inside
    uart_timeout_seq uart_timeout_seq_h;
    apb_read_seq apb_read_seq_h; 

    function void build_phase(uvm_phase phase);
        super.lcr = 8'b0000_0011;
        super.build_phase(phase);
    endfunction 

    task run_phase(uvm_phase phase);

        $display("---------------<<<<<xxxxxxxxxx Timeout is RUNNING xxxxxxxxxx>>>>>---------------");
        super.run_phase(phase);
        apb_timeout_seq_h = apb_timeout_seq::type_id::create("apb_timeout_seq_h");
        uart_timeout_seq_h = uart_timeout_seq::type_id::create("uart_timeout_seq_h");
        apb_read_seq_h = apb_read_seq::type_id::create("apb_read_seq_h");

        phase.raise_objection(this);
        //---> Perfectly works
        // fork   
        //     apb_timeout_seq_h.start(envh.apb_agent_top_h.apb_agent_h.apb_seqr_h);
        // join
        //     uart_timeout_seq_h.start(envh.uart_agent_top_h.uart_agent_h.uart_seqr_h); // Why Uart seq outside fork ? Because in time out we want to read before uart sends the frame so when nothing to read then timeout like that. when fork ends read starts instantly causing timeout.
        // wait fork;   
        //         apb_read_seq_h.start(envh.apb_agent_top_h.apb_agent_h.apb_seqr_h);

            fork 
                uart_timeout_seq_h.start(envh.uart_agent_top_h.uart_agent_h.uart_seqr_h); // Uart seq runs sends 3 frames 
            join_none 
            apb_timeout_seq_h.start(envh.apb_agent_top_h.apb_agent_h.apb_seqr_h); // Configure first
            wait fork; 
                apb_read_seq_h.start(envh.apb_agent_top_h.apb_agent_h.apb_seqr_h); // Uart reads and expects 4 frames -> only 3 came - keeps waiting then timeout.


        phase.phase_done.set_drain_time(this,200000);
        
        phase.drop_objection(this);
    endtask


endclass 