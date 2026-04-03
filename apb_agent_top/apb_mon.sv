//xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx MONITORS xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

//-----------------------------------------------------APB MONITOR-------------------------------------------------------
class apb_mon extends uvm_monitor;
    `uvm_component_utils(apb_mon)

    apb_agent_config apb_cfg;
    virtual apb_if vif;
    apb_xtn xtn_h;

    uvm_analysis_port #(apb_xtn) apb_mon_port;

    function new(string name="",uvm_component parent);
        super.new(name,parent);
        apb_mon_port = new("apb_mon_port",this);
    endfunction 

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if(!uvm_config_db #(apb_agent_config)::get(this,"","apb_agent_config",apb_cfg))
            `uvm_fatal(get_type_name(),"Failed to get() apb_cfg from ENV")

        // Create transaction object ==> can also be done directly in run_phase
        xtn_h = apb_xtn::type_id::create("xtn_h");

    endfunction 

    function void connect_phase(uvm_phase phase);
        vif = apb_cfg.vif;
    endfunction 

    task run_phase(uvm_phase phase);
        forever begin : monitor_loop
            collect_data();
            $display("------------------SAMPLING THE DATA------------------");
            xtn_h.print();
        end : monitor_loop
    endtask

    //Task Collect Data --------------------------------------
    task collect_data(); 
        @(vif.apb_mon_cb)

        // PENABLE is not yet in xtn_h so we get it from interface
        while(vif.apb_mon_cb.PENABLE !== 1) // To read "re" must be high that happens in access state of apb fsm, SO, Wait for enable to become HIGH
            @(vif.apb_mon_cb)
        
            begin : transfer_capture
                while(vif.apb_mon_cb.PREADY !== 1) // Wait for ready to become HIGH
                    @(vif.apb_mon_cb)

                // Sample all the signals 
                    xtn_h.PENABLE = vif.apb_mon_cb.PENABLE;
                    xtn_h.PRESETn = vif.apb_mon_cb.PRESETn;
                    xtn_h.PSEL    = vif.apb_mon_cb.PSEL;
                    xtn_h.PSLVERR = vif.apb_mon_cb.PSLVERR;
                    xtn_h.PADDR   = vif.apb_mon_cb.PADDR;
                    xtn_h.PWRITE  = vif.apb_mon_cb.PWRITE;
                    xtn_h.IRQ     = vif.apb_mon_cb.IRQ;

                // Sample data phase
                if(xtn_h.PWRITE == 1)
                    xtn_h.PWDATA = vif.apb_mon_cb.PWDATA;
                else 
                    xtn_h.PRDATA = vif.apb_mon_cb.PRDATA;
                    
                // Register Updates based on address decoding 
                    //==> We sample all the configured registers (in seq we did) to check whether the configuration happened correctly. We compare in SB 
                
                // LCR Update
                if(xtn_h.PADDR == 8'hC &&
                    xtn_h.PWRITE == 1)
                    //xtn_h.LCR = vif.apb_mon_cb.PWDATA; ==> We have data available in xtn
                    xtn_h.LCR = xtn_h.PWDATA;
                
                // IER Update
                if(xtn_h.PADDR == 8'h4 &&
                    xtn_h.PWRITE == 1)
                    xtn_h.IER = xtn_h.PWDATA;

                // FCR Update
                if(xtn_h.PADDR == 8'h8 &&
                    xtn_h.PWRITE == 1)
                    xtn_h.FCR = xtn_h.PWDATA;

                // IIR Update  ==> READ Only
                if(xtn_h.PADDR == 8'h8 &&
                    xtn_h.PWRITE == 0) 
                    begin 
                        while(vif.apb_mon_cb.IRQ !== 1)
                        //while(xtn_h.IRQ !== 1) // I already have IRQ sampled (Why do I need to use vif.cb here then ?)
                            @(vif.apb_mon_cb)
                            xtn_h.IIR = vif.apb_mon_cb.PRDATA;       
                    end
                
                // MCR Update 
                if(xtn_h.PADDR == 8'h10 &&
                    xtn_h.PWRITE == 1)
                    xtn_h.MCR = xtn_h.PWDATA;

                // LSR Read 
                if(xtn_h.PADDR == 8'h14 &&
                    xtn_h.PWRITE == 0)
                    xtn_h.LSR = xtn_h.PRDATA; // Mam did directly ?? don't we need to check if iir is lsr or not ? 
                    // begin
                    //     while(xtn_h.IIR !== 6)
                    //         @(vif.apb_mon_cb)
                    //     xtn_h.LSR = xtn_h.PRDATA;
                    // end

                // DIV - LSB
                if(xtn_h.PADDR == 8'h1C &&
                    xtn_h.PWRITE == 1) 
                    begin : divisor_lsb

                        xtn_h.DIV[7:0] = xtn_h.PWDATA;
                        xtn_h.dl_access = 1;

                    end : divisor_lsb
                    
                // DIV - MSB
                if(xtn_h.PADDR == 8'h20 &&
                    xtn_h.PWRITE == 1)
                    begin : divisor_msb

                        xtn_h.DIV[15:8] = xtn_h.PWDATA;
                        xtn_h.dl_access = 1;

                    end : divisor_msb

                // THR 
                if(xtn_h.PADDR == 8'h0 &&
                    xtn_h.PWRITE == 1) 
                    begin : THR_REG

                        xtn_h.data_in_thr = 1;
                        xtn_h.THR.push_back(xtn_h.PWDATA);
                    end : THR_REG
                
                // RBR 
                if(xtn_h.PADDR == 8'h0 &&
                    xtn_h.PWRITE == 0) 
                    begin : RBR_REG

                        xtn_h.data_in_rbr = 1;
                        xtn_h.RBR.push_back(vif.apb_mon_cb.PRDATA);
                    end : RBR_REG

            end : transfer_capture

            // Send collected data to SB 
            apb_mon_port.write(xtn_h);
    endtask 

endclass 