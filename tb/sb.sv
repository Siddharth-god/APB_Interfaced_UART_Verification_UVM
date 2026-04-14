
//xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx SCOREBOARD xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
//-----------------------------------------------------SB-------------------------------------------------------

class sb extends uvm_scoreboard; 
    `uvm_component_utils(sb)

    uvm_tlm_analysis_fifo #(apb_xtn) fifo_apb; 
    uvm_tlm_analysis_fifo #(uart_xtn) fifo_uart; 
    
    // Store the thr and rbr size ==> For what ? 
    int thr_size; // for uart core side 
    int rbr_size; // for uart core side 
    bit rx[$] , tx[$]; // queue to store the bits that are getting transfered or received one by one. (for uart agent)

    // Getting trans from monitors 
    apb_xtn uart_core; 
    uart_xtn uart_agent; 

    // Getting transactions for cov 
    apb_xtn cov_uart_core;
    uart_xtn cov_uart_agent; 

    // Backdoor access - register block 
    bit [7:0] reg_lcr; 
    bit [7:0] reg_ier;
    bit [7:0] reg_fcr;
    bit [7:0] reg_mcr; 
    bit [7:0] reg_lsr;
    bit [7:0] reg_iir;

    uart_reg_block regmodel; 
    env_config env_cfg; 
    uvm_status_e status; // In-built method status (used for back door access)

    // Coverage 

        // 1. Covergroup for basic APB signals-----------------------------------------------------------------------------------
        covergroup apb_signal_cov; 
            ADDRESS : coverpoint cov_uart_core.PADDR{
                bins addr = {[0:255]}; 
            }

            WR_ENB : coverpoint cov_uart_core.PWRITE{
                bins high = {1};
                bins low = {0};
            }
        endgroup 

        // 2. LCR Covergroup ----------------------------------------------------------------------------------------------------
        covergroup apb_lcr_cov; 
            FRAME_SIZE : coverpoint cov_uart_core.LCR[1:0]{
                bins five_data_bits = {2'b00};
                bins eight_data_bits = {2'b11};
            }

            STOP_BIT : coverpoint cov_uart_core.LCR[2]{
                bins one = {1'b0};
                bins more = {1'b1};
            }

            PARITY_BIT : coverpoint cov_uart_core.LCR[3]{
                bins no_parity = {0}; 
                bins parity = {1}; 
            }

            EVEN_ODD_PAR : coverpoint cov_uart_core.LCR[4]{
                bins odd = {0}; 
                bins even = {1}; 
            }

            BREAK_BIT : coverpoint cov_uart_core.LCR[6]{
                bins no_break = {0}; 
                bins break_err = {1}; 
            }
        endgroup 

        // 3. IER Covergroup ---------------------------------------------------------------------------------------------------
        covergroup apb_ier_cov; 

            // Received data available at threshold lvl interrupt
            BIT0 : coverpoint cov_uart_core.IER[0]{
                bins dis = {0};
                bins enb = {1};
            }

            // THR empty interrupt enable 
            BIT1 : coverpoint cov_uart_core.IER[1]{
                bins dis = {0};
                bins enb = {1};
            }

            // Line status interrupt enable 
            BIT2 : coverpoint cov_uart_core.IER[2]{
                bins dis = {0};
                bins enb = {1};
            }

            IER_RST : coverpoint cov_uart_core.IER[7:0]{
                bins ier_rst = {0};
            }
        endgroup 

        // 4. FCR Covergroup ---------------------------------------------------------------------------------------------------
        covergroup apb_fcr_cov; 

            // RX_FIFO Flush 
            RX_FLUSH : coverpoint cov_uart_core.FCR[0]{
                bins dis = {0};
                bins rx_flush = {1};
            }

            // TX_FIFO Flush  
            TX_FLUSH : coverpoint cov_uart_core.FCR[1]{
                bins dis = {0};
                bins tx_flush = {1};
            }

            // RX_FIFO Trigger level  
            TRIG_LVL : coverpoint cov_uart_core.FCR[7:0]{
                bins one = {0};
                //bins four = {1};
                bins eight = {2}; 
                bins fourteen = {3}; 
            }
        endgroup 

        // 5. MCR -------------------------------------------------------------------------------------------------------------
        covergroup apb_mcr_cov; 

            // Loopback enable or disable 
            LOOPBACK : coverpoint cov_uart_core.MCR[4]{
                bins loop_dis = {0};
                bins loop_enb = {1};
            }
            
            // Reset the MCR register 
            MCR_RST : coverpoint cov_uart_core.MCR[7:0]{
                bins mcr_rst = {0};
            }
        endgroup 

        // 6. IIR -------------------------------------------------------------------------------------------------------------
        covergroup apb_iir_cov; 

            // Check the interrupts 
            INTERRUPT : coverpoint cov_uart_core.IIR[3:0]{
                bins lsr_intr = {6};
                bins received_data = {4};
                bins time_out = {12};
                //bins tx_empty = {2};
            }

            // IIR_RST : coverpoint cov_uart_core.IIR[7:0]{
            //     bins mcr_rst = {0};
            // }
        endgroup 

        // 7. LSR -------------------------------------------------------------------------------------------------------------
        // LSR Coverage
        covergroup apb_lsr_cov;
        option.per_instance = 1;

            DATA_READY: coverpoint cov_uart_core.LSR[0] { 
                bins fifoempty = {1'b0};
                bins datarcvd = {1'b1}; 
            }

            OVER_RUN: coverpoint cov_uart_core.LSR[1] {
                bins nooverrun = {1'b0};
                bins overrun = {1'b1}; 
            }

            PARITY_ERR: coverpoint cov_uart_core.LSR[2] { 
                bins noparityerr = {1'b0};
                bins parityerr = {1'b1}; 
            }

            FRAME_ERR: coverpoint cov_uart_core.LSR[3] { 
                bins frameerr = {1'b0}; 
            }

            BREAK_INT: coverpoint cov_uart_core.LSR[4] { 
                bins nobreakint = {1'b0};
                bins breakint = {1'b1}; 
            }

            bl: coverpoint cov_uart_core.LSR[5] { 
                bins al = {1'b0};
                bins a2 = {1'b1}; 
            }
        endgroup 

    function new(string name="",uvm_component parent);
        super.new(name,parent);
        fifo_apb = new("fifo_apb",this); 
        fifo_uart = new("fifo_uart",this);

        // create covergroup 
        apb_signal_cov  = new();
        apb_lcr_cov     = new();
        apb_ier_cov     = new();
        apb_fcr_cov     = new();
        apb_mcr_cov     = new();
        apb_iir_cov     = new();
        apb_lsr_cov     = new();
    endfunction 

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // env_cfg = env_config::type_id::create("env_cfg");

        if(!uvm_config_db #(env_config)::get(this,"","env_config",env_cfg))
            `uvm_fatal(get_type_name(),"Failed to get env_cfg from TEST")

         if(env_cfg==null)
                        `uvm_fatal("FATAL", "null")

        regmodel = env_cfg.regmodel;

    endfunction 

    task run_phase(uvm_phase phase);
        fork
            // Process APB tranasction 
            forever begin
                fifo_apb.get(uart_core);
                thr_size = uart_core.THR.size(); 
                rbr_size = uart_core.RBR.size();
                //---------------------------------------------------------------- THR DATA & SIZE
                $display("SCOREBOARD RECEIVED: \ndata_in_THR=%0d, THR size=%0d, THR data=%p\n",
                uart_core.data_in_thr, uart_core.THR.size(), uart_core.THR);


                $display("MONITOR BEFORE WRITE: \ndata_in_RBR=%0d, RBR size=%0d, RBR data=%p\n",
                        uart_core.data_in_rbr, uart_core.RBR.size(), uart_core.RBR);
                //---------------------------------------------------------------- RBR DATA & SIZE

                if(uart_core.PADDR == 32'h8 && uart_core.PWRITE == 0) begin 
                    $display("\nPADDR and PWRITE and PRDATA Value in SB -------> %0d and %0d and %0d| at time = %0t",
                                uart_core.PADDR,
                                uart_core.PWRITE,
                                uart_core.PRDATA, 
                                $time
                            ); 
                    $display("\nIIR Value in SB -------> %0d | at time = %0t",uart_core.IIR, $time); 
                end
                cov_uart_core = uart_core; 
                 // Calling the "sample" in run phase outside forever and once for all     
                apb_signal_cov.sample();
                apb_lcr_cov.sample();
                apb_ier_cov.sample();
                apb_fcr_cov.sample();
                apb_mcr_cov.sample();
                apb_iir_cov.sample();
                apb_lsr_cov.sample();

                // Call task ral 
                // if(regmodel == null)
                //     `uvm_fatal("SB","regmodel is NULL before RAL")
                // ral; 

                // FCR Effect checking 
                // ==> FCR won't print in check phase => FCR write → flush happened → FIFOs changed → system continued → state changed again
                if(uart_core.PADDR == 32'h8 && uart_core.PWRITE == 1 && uart_core.PWDATA[2]) begin 
                    if(uart_core.THR.size == 0)
                        `uvm_info("FCR[2]","SB : ############################# TX flush success #############################", UVM_LOW)
                    else
                        `uvm_error("FCR[2]","SB : ############################# TX flush failed #############################")
                end

                if(uart_core.PADDR == 32'h8 && uart_core.PWRITE == 1 && uart_core.PWDATA[1]) begin 
                    if(uart_core.RBR.size == 0)
                        `uvm_info("FCR[1]","SB : ############################# RX flush success #############################", UVM_LOW)
                    else
                        `uvm_error("FCR[1]","SB : ############################# RX flush failed #############################")
                end
                `uvm_info("SCOREBOARD",$sformatf("Data from UART_CORE :\n %s",uart_core.sprint()),UVM_LOW)
            end

            // Process UART transaction 
            forever begin
                fifo_uart.get(uart_agent); 
                cov_uart_agent = uart_agent; 
                //`uvm_info("SCOREBOARD",$sformatf("Data from UART_AGENT :\n %s",uart_agent.sprint()),UVM_LOW) // The sprint() method in UVM is primarily used for debugging purposes. It provides a formatted string representation of the contents of a UVM sequence item, which can be useful for identifying issues during testing. The method returns the contents in a string format, allowing for easy identification of the data being transferred or displayed.
            end
        join
    endtask 

    function void check_phase(uvm_phase phase);
        `uvm_info(get_type_name(),$sformatf("Size of THR = %0d",thr_size),UVM_LOW)
        `uvm_info(get_type_name(),$sformatf("Size of RBR = %0d",rbr_size),UVM_LOW)

        if (uart_core == null && uart_agent == null) begin
            `uvm_info(get_type_name(), "check_phase: no transactions received - skipping comparison", UVM_LOW)
            return;
            end
        
        if(uart_core != null) begin 
            `uvm_info(get_type_name(),$sformatf("Values sent by uart_core : %p",uart_core.THR),UVM_LOW)
            `uvm_info(get_type_name(),$sformatf("Values Received by uart_core : %p",uart_core.RBR),UVM_LOW) // RBR is on core size
        end
            else 
            `uvm_fatal(get_type_name(), "uart_core is NULL")


        if(uart_agent != null) begin : loopback_gives_null
            `uvm_info(get_type_name(),$sformatf("Values Received by uart_agent : %p",uart_agent.rx),UVM_LOW) // rx is in agent.  
            `uvm_info(get_type_name(),$sformatf("Values sent by uart_agent : %p",uart_agent.tx),UVM_LOW)
        end : loopback_gives_null


        $display("///////// IIR value in SB //////////= %0d at time=%0t",uart_core.IIR, $time); 

        if(uart_core.IIR[3:0] == 4) begin // Receive data threshold interrupt 
            if(uart_core.MCR[4] == 0) begin // Check whether loop back is present
                if(uart_core.THR.size() == 0) begin // THR should be empty means we cannot pass THR in sequence else it will be one and half duplex won't be checked.
                
                //xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx HALF DUPLEX xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx//

                    if((uart_core.PWDATA[7:0] == uart_agent.rx) || (uart_core.PRDATA[7:0] == uart_agent.tx)) // or pwdata check once - But likely it should be prdata as we compare it with tx (means tx coming which will be received in rbr and hence read by prdata)
                        `uvm_info(get_type_name(), "\n[---- HALF DUPLEX ----> DATA MATCH SUCCESS]",UVM_LOW) // success hota he when i use uart_core.paddr == tx which is wrong condition
                    else 
                        `uvm_error(get_type_name(), "\n[---- HALF DUPLEX ----> DATA MATCH FAILED]")
                    end
                
                //xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx FULL DUPLEX xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx//
                else begin 
                    if((uart_core.PWDATA[7:0] == uart_agent.rx) && (uart_core.PRDATA[7:0] == uart_agent.tx))
                            `uvm_info(get_type_name(), "\n[---- FULL DUPLEX ----> DATA MATCH SUCCESS]",UVM_LOW)
                        else 
                            `uvm_error(get_type_name(), "\n[---- FULL DUPLEX ----> DATA MATCH FAILED]")
                end
            end
            //xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx LOOPBACK xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx//
            else begin 
                if(uart_core.PWDATA[7:0] == uart_core.PRDATA[7:0])
                    `uvm_info(get_type_name(), "\n[---- LOOPBACK ----> DATA MATCH SUCCESS]",UVM_LOW)
                    else 
                        `uvm_error(get_type_name(), "\n[---- LOOPBACK ----> DATA MATCH FAILED]")
            end 
        end
            //xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx ERROR CONDITIONS CHECK xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx//
        else begin
            // 1. Line status error checking 
            if(uart_core.IIR[3:0] == 6) begin 
                if(uart_core.LSR[1])
                    `uvm_info("SCOREBOARD : ","/// OVERRUN /// ERROR IN UART CORE",UVM_LOW)
                if(uart_core.LSR[2])
                    `uvm_info("SCOREBOARD : ","/// PARITY /// ERROR IN UART CORE",UVM_LOW)
                if(uart_core.LSR[3])
                    `uvm_info("SCOREBOARD : ","/// FRAMING /// ERROR IN UART CORE",UVM_LOW)
                if(uart_core.LSR[4])
                    `uvm_info("SCOREBOARD : ","/// BREAK /// ERROR IN UART CORE",UVM_LOW)
            end
                    
            // 2. Time out error checking 
            if(uart_core.IIR[3:0] == 12) // 4'b1100 | 1'hc 
                `uvm_info("SCOREBOARD : ","/// TIME OUT /// ERROR IN UART CORE",UVM_LOW)

            // 3. THR empty error checking 
            if(uart_core.IIR[3:0] == 2) 
                `uvm_info("SCOREBOARD : ","/// THR EMPTY /// ERROR IN UART CORE",UVM_LOW)
        end
    endfunction 

    task ral; 
        $display(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> entered ral task >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");

        regmodel.lcr.read(status,reg_lcr,UVM_BACKDOOR,.map(regmodel.default_map)); 
        `uvm_info("REG",$sformatf("<<<<<xxxxxxxxxxxxxx LCR : %0d <xxxxxxxxxxxxxx>>>>>",reg_lcr),UVM_NONE)

        regmodel.ier.read(status,reg_ier,UVM_BACKDOOR,.map(regmodel.default_map)); 
        `uvm_info("REG",$sformatf("<<<<<xxxxxxxxxxxxxx IER : %0d <xxxxxxxxxxxxxx>>>>>",reg_ier),UVM_NONE)

        // regmodel.fcr.read(status,reg_fcr,UVM_BACKDOOR,.map(regmodel.default_map)); 
        // `uvm_info("REG",$sformatf("<<<<<xxxxxxxxxxxxxx FCR : %0d <xxxxxxxxxxxxxx>>>>>",reg_fcr),UVM_NONE)

        regmodel.mcr.read(status,reg_mcr,UVM_BACKDOOR,.map(regmodel.default_map)); 
        `uvm_info("REG",$sformatf("<<<<<xxxxxxxxxxxxxx MCR : %0d <xxxxxxxxxxxxxx>>>>>",reg_mcr),UVM_NONE)

        regmodel.lsr.read(status,reg_lsr,UVM_BACKDOOR,.map(regmodel.default_map)); 
        `uvm_info("REG",$sformatf("<<<<<xxxxxxxxxxxxxx LSR : %0d <xxxxxxxxxxxxxx>>>>>",reg_lsr),UVM_NONE)

        if(uart_core.PADDR == 32'h00 && uart_core.PWRITE == 0) begin // IIR only valid here
            regmodel.iir.read(status,reg_iir,UVM_BACKDOOR,.map(regmodel.default_map)); 
            `uvm_info("REG",$sformatf("<<<<<xxxxxxxxxxxxxx IIR : %0d <xxxxxxxxxxxxxx>>>>>",reg_iir),UVM_NONE)
            
             // IIR 
            if(uart_core.IIR == reg_iir)
                `uvm_info("REG_COMP"," SB : Comparision Successful : IIR[DUT] == IIR[REG_model]",UVM_LOW)
            else 
                `uvm_error("REG_COMP","SB : Comparision Failed : IIR[DUT] != IIR[REG_model]")
        end

        // LCR
        if(uart_core.LCR == reg_lcr)
            `uvm_info("REG_COMP"," SB : Comparision Successful : LCR[DUT] == LCR[REG_model]",UVM_LOW)
        else 
            `uvm_error("REG_COMP","SB : Comparision Failed : LCR[DUT] != LCR[REG_model]")

        // IER
        if(uart_core.IER == reg_ier)
            `uvm_info("REG_COMP"," SB : Comparision Successful : IER[DUT] == IER[REG_model]",UVM_LOW)
        else 
            `uvm_error("REG_COMP","SB : Comparision Failed : IER[DUT] != IER[REG_model]")

        // // FCR
        // if(uart_core.FCR == reg_fcr)
        //     `uvm_info("REG_COMP"," SB : Comparision Successful : FCR[DUT] == FCR[REG_model]",UVM_LOW)
        // else 
        //     `uvm_error("REG_COMP","SB : Comparision Failed : FCR[DUT] != FCR[REG_model]")

        // MCR
        if(uart_core.MCR == reg_mcr)
            `uvm_info("REG_COMP"," SB : Comparision Successful : MCR[DUT] == MCR[REG_model]",UVM_LOW)
        else 
            `uvm_error("REG_COMP","SB : Comparision Failed : MCR[DUT] != MCR[REG_model]")

        // LSR
        if(uart_core.LSR == reg_lsr)
            `uvm_info("REG_COMP"," SB : Comparision Successful : LSR[DUT] == LSR[REG_model]",UVM_LOW)
        else 
            `uvm_error("REG_COMP","SB : Comparision Failed : LSR[DUT] != LSR[REG_model]")    
    endtask 
endclass 

/*
Note : Why NOT check_phase for RAL (in your case) 

Because many of your registers are:

volatile (IIR, LSR)
event-driven
time-dependent

So by check_phase:

value at time T1 ≠ value at end of simulation

👉 You compare wrong snapshot → false fail/pass

# ================================
# RUN PHASE vs CHECK PHASE
# ================================

# ---------- RUN PHASE ----------
# time = running
# DUT = active
# events = happening now

run_phase:
    observe "what is happening right now"
    check   "did this transaction behave correctly?"

# examples
run_phase:
    check IIR interrupt timing
    check LSR status change
    check FCR flush effect immediately
    check APB read/write correctness
    track FIFO push/pop


# ---------- CHECK PHASE ----------
# time = stopped
# DUT = inactive
# events = finished

check_phase:
    observe "final system state"
    check   "did everything end correctly?"

# examples
check_phase:
    compare sent_data == received_data
    check final FIFO contents
    verify scoreboard queues empty/matched
    print summary / coverage


# ---------- DECISION RULE ----------
if (signal_changes_with_time):
    use run_phase
else:
    use check_phase


# ---------- YOUR UART CASE ----------
# transient / event-based
IIR  -> run_phase
LSR  -> run_phase
FCR  -> run_phase

# stable / final result
loopback_data -> check_phase


# ---------- CORE DIFFERENCE ----------
run_phase   = truth while system is moving
check_phase = truth after system stops
*/