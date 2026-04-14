
//xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx MONITORS xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

//-----------------------------------------------------APB MONITOR-------------------------------------------------------
class apb_mon extends uvm_monitor;
    `uvm_component_utils(apb_mon)

    apb_agent_config apb_cfg;
    virtual apb_if vif;
    apb_xtn xtn_h;
    static int rx_count;

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
        @(vif.apb_mon_cb);  // This delay does not interfere with sampling operation (it just skips first sample which happens before driver drives - as sampling always happens before driving)
        forever begin : monitor_loop
            // xtn_h = apb_xtn::type_id::create("xtn_h");
            collect_data();
            $display("[%0t] RX BYTE ARRIVED FROM TX", $time);
            $display("APB MON ==> SAMPLING THE DATA------------------");
            xtn_h.print();
        end : monitor_loop
    endtask

    // //Task Collect Data --------------------------------------
    task collect_data(); 

        //@(vif.apb_mon_cb)

        // PENABLE is not yet in xtn_h so we get it from interface
        // Wait for setup phase
            // xtn_h.data_in_thr = 0;
            // xtn_h.data_in_rbr = 0;

            @(vif.apb_mon_cb)
                while (!(vif.apb_mon_cb.PSEL && !vif.apb_mon_cb.PENABLE)) begin 
                    @(vif.apb_mon_cb);
                    //$display("Waiting for setup state in apb monitor =+=+=+=+=+=+=+=");
                end

                `uvm_info("APB_MON", $sformatf("\nSETUP DETECTED:\nPADDR=%0h \nPWRITE=%0b \ntime=%0t",
                    vif.apb_mon_cb.PADDR, vif.apb_mon_cb.PWRITE, $time), UVM_LOW)

                begin : transfer_capture

                    // Wait for completion
                    do begin
                    @(vif.apb_mon_cb);
                    end while (!vif.apb_mon_cb.PREADY);

                // @(vif.apb_mon_cb iff (vif.apb_mon_cb.PSEL &&
                //      vif.apb_mon_cb.PENABLE &&
                //      vif.apb_mon_cb.PREADY));

                `uvm_info("APB_MON", $sformatf("\bACCESS COMPLETE: \nPADDR=%0h \nPWRITE=%0b \nPWDATA=%0d \nPRDATA=%0d \ntime=%0t",
                    vif.apb_mon_cb.PADDR,
                    vif.apb_mon_cb.PWRITE,
                    vif.apb_mon_cb.PWDATA,
                    vif.apb_mon_cb.PRDATA,
                    $time), UVM_LOW)

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
             
                // LCR Update
                if(xtn_h.PADDR == 32'hC &&
                    xtn_h.PWRITE == 1)
                    xtn_h.LCR = vif.apb_mon_cb.PWDATA;// ==> We have data available in xtn
                    //xtn_h.LCR = xtn_h.PWDATA;
                
                // IER Update
                if(xtn_h.PADDR == 32'h4 &&
                    xtn_h.PWRITE == 1)
                    xtn_h.IER = xtn_h.PWDATA;

                // FCR Update
                if(xtn_h.PADDR == 32'h8 &&
                    xtn_h.PWRITE == 1)
                    xtn_h.FCR = xtn_h.PWDATA;

                // IIR Update  ==> READ Only
                if(xtn_h.PADDR == 32'h8 &&
                    xtn_h.PWRITE == 0) 
                    begin 
                        `uvm_info("APB_MON", $sformatf("WAITING FOR IRQ at time=%0t", $time), UVM_LOW)
                        while(vif.apb_mon_cb.IRQ !== 1)
                            @(vif.apb_mon_cb);  /// this was here - removed just for checking 

                        xtn_h.IIR = vif.apb_mon_cb.PRDATA; 
                        `uvm_info("APB_MON", $sformatf("IRQ DETECTED, SAMPLING IIR=%0h time=%0t",
                                    vif.apb_mon_cb.PRDATA, $time), UVM_LOW)

                        // $display("\nIRQ is HIGH ? -------> %0d | at time = %0t",vif.apb_mon_cb.IRQ, $time);     
                        // $display("\nIIR Value in apb monitor -------> %0d | at time = %0t",xtn_h.IIR, $time);     
                    end
                
                // MCR Update 
                if(xtn_h.PADDR == 32'h10 &&
                    xtn_h.PWRITE == 1)
                    xtn_h.MCR = xtn_h.PWDATA;

                // LSR Read 
                if(xtn_h.PADDR == 32'h14 &&
                    xtn_h.PWRITE == 0)
                    xtn_h.LSR = xtn_h.PRDATA; 
    

                // DIV - LSB
                if(xtn_h.PADDR == 32'h1C &&
                    xtn_h.PWRITE == 1) 
                    begin : divisor_lsb

                        xtn_h.DIV[7:0] = xtn_h.PWDATA;
                        xtn_h.dl_access = 1;

                    end : divisor_lsb
                    
                // DIV - MSB
                if(xtn_h.PADDR == 32'h20 &&
                    xtn_h.PWRITE == 1)
                    begin : divisor_msb

                        xtn_h.DIV[15:8] = xtn_h.PWDATA;
                        xtn_h.dl_access = 1;

                    end : divisor_msb

                // THR 
                if(xtn_h.PADDR == 32'h0 &&
                    xtn_h.PWRITE == 1) 
                    begin : THR_REG

                        xtn_h.data_in_thr = 1;
                        xtn_h.THR.push_back(xtn_h.PWDATA);
                        `uvm_info("\n[APB_MON",$sformatf("/// THR DATA /// : %p",xtn_h.THR),UVM_LOW)
                    end : THR_REG
                
                // RBR 
                //`uvm_info("\n[APB_MON",$sformatf("<<<<<<------- ABOUT TO ENTER RBR IN APB MON ------->>>>>>"),UVM_LOW)
                if(xtn_h.PADDR == 32'h0 &&
                    xtn_h.PWRITE == 0) // We configure in sequence 
                    begin : RBR_REG
                        if(!xtn_h.PRDATA == 0) begin // Not pushing if prdata is 0
                            xtn_h.data_in_rbr = 1;
                            xtn_h.RBR.push_back(xtn_h.PRDATA);
                        end
                        `uvm_info("\n[APB_MON",$sformatf("/// RBR DATA /// : %p",xtn_h.RBR),UVM_LOW)
                    end : RBR_REG
                //`uvm_info("\n[APB_MON",$sformatf("<<<<<<------- EXITED RBR IN APB MON  ------->>>>>>: %p",xtn_h.RBR),UVM_LOW)

            end : transfer_capture

            $display("MONITOR BEFORE WRITE: \ndata_in_THR=%0d, THR size=%0d, THR data=%p\n",
                        xtn_h.data_in_thr, xtn_h.THR.size(), xtn_h.THR);
            $display("MONITOR BEFORE WRITE: \ndata_in_RBR=%0d, RBR size=%0d, RBR data=%p\n",
                        xtn_h.data_in_rbr, xtn_h.RBR.size(), xtn_h.RBR);

            rx_count ++; 
            $display("[%0t] RX COUNT inside APB Monitor coming from TX UART agent = %0d", $time, rx_count);

               if (xtn_h.FCR[1])
                $display("[%0t] RX FIFO BEING RESET", $time);


            // Send collected data to SB 
            apb_mon_port.write(xtn_h);
            `uvm_info("APB_MON", $sformatf("\nWRITE TO SB: PADDR=%0h time=%0t",
                xtn_h.PADDR, $time), UVM_LOW)
    endtask 

endclass 