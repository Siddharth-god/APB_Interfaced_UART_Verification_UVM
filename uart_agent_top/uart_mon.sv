
//-----------------------------------------------------UART MONITOR-------------------------------------------------------

class uart_mon extends uvm_monitor;
    `uvm_component_utils(uart_mon)

    virtual uart_if vif; 
    uart_agent_config uart_cfg; 
    bit [7:0] LCR; 
    uart_xtn xtnh; 

    uvm_analysis_port #(uart_xtn) uart_mon_port; 

    function new(string name="",uvm_component parent);
        super.new(name,parent);
        uart_mon_port = new("uart_mon_port",this); 
    endfunction 

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if(!uvm_config_db #(uart_agent_config)::get(this,"","uart_agent_config",uart_cfg))
            `uvm_fatal(get_type_name(),"Failed to get uart_cfg in UART MON from TEST")

        if(!uvm_config_db #(bit [7:0])::get(this,"*","lcr",LCR)) //why are we using "*" ?? Ask mam, we don't need to use right.
            `uvm_fatal(get_type_name(),"Failed to get LCR in UART MON from TEST")

        xtnh = uart_xtn::type_id::create("xtnh"); // updated 1st
    endfunction  
    
    function void connect_phase(uvm_phase phase);
        vif = uart_cfg.vif; 
    endfunction

    task run_phase(uvm_phase phase);
        bit rx_busy, tx_busy; 
            fork // understand why we need this as seperately ? and what exactly we are doing here. ?????? 
                // uart monitor rx line 
                @(posedge vif.uart_mon_cb.baud_o);
                forever begin 
                    if(rx_busy == 0) begin : rx_line
                        rx_busy = 1; // vif.rx to tx
                        collect_uart_data(vif.uart_mon_cb.rx, xtnh.rx, xtnh.parity); // vif.rx acting as line here ? how 
                        rx_busy = 0; 
                    end : rx_line
                    else begin 
                        @(posedge vif.uart_mon_cb.baud_o);
                    end
                end
               
                // uart monitor tx line  
                forever begin 
                    if(tx_busy == 0) begin : tx_line
                        tx_busy = 1;  // vif.tx hona he yaha pe - then only this will work(i did rx and in sb it was showing value received by uart agent is 41 and value received by uart core is 41 but how that is possible koi to send kre bc then I found out the issue, i was writing rx and that is why it was only receiving and not sending so tx to rx ke time hora and rx tx ke time inverse logic) --> will go in deep later after exam. how exactly it was working. 
                        collect_uart_data(vif.uart_mon_cb.tx, xtnh.tx, xtnh.parity); // we collect the data from [vif.tx/rx] and then store it in [xtn.tx/rx and also xtn.parity] ===> In collect data we are doing assignment operation in for loop. 
                        tx_busy = 0; 
                    end : tx_line
                    else begin 
                        @(posedge vif.uart_mon_cb.baud_o); // agar tx line busy he to wait for it go low
                    end
                end
            join
    endtask 

    task collect_uart_data(ref logic line, ref bit[7:0] data, ref bit parity); // line can be bit also right ? 
        int bits; 

        bits = LCR[1:0] + 5; // total data bits 
        $display("///////////// Entered into UART AGENT MON //////////////");
        //@(posedge line);
        // if(line == 1) // Idle --> is it stop bit ? ask mam  ///====> This removed and issue got resolved of wrong sample
        //     $display("=========================== UART AGENT MON Line became 1 ============================");
        // else 
        //     `uvm_warning(get_type_name(),"Line is not getting 1 in uart mon");
        @(posedge vif.uart_mon_cb.baud_o);
        // if(line == 0) // Wait for start bit
       @(negedge line); // Detect start bit
        // $display("=========================== UART AGENT MON After negedge of line (Start bit )============================");
        // else  
        //     `uvm_warning(get_type_name(),"Line is not getting 0 in uart mon");
        //repeat(24) @(posedge vif.uart_mon_cb.baud_o); // wait for 24 pulses ? we sample in between but what about first 16 sampels ? there it is not getting sampled ? ==> UART Protocol says that sampling of bit between 2 uarts should happen in between the first bit and second bit is driving. that is 24. as first bit driven at 16 baud pulse and 2nd driven at 32. 
        repeat(8) @(posedge vif.uart_mon_cb.baud_o);   // go to center of start bit

        repeat(16) @(posedge vif.uart_mon_cb.baud_o);  // move to first data bit center

        // Collect the data bits 
        for(int i=0; i<bits; i++) begin 
            data[i] = line; // From interface/DUT - get the values into txn class, where data[i](its a single bit) acts as tx or rx bit. 
            //`uvm_info("\n[UART MON",$sformatf("data bits sampled = %0d",data[i]),UVM_LOW)
            //`uvm_info("UART_MON", $sformatf("FULL DATA = %0d (%b)", data, data), UVM_LOW)
            repeat(16) @(posedge vif.uart_mon_cb.baud_o); // wait for 16 pulses
        end

        // Collect parity bit if enabled 
        if(LCR[3])  begin 
            parity = line;
            `uvm_info("\n[UART MON",$sformatf("parity bit sampled = %0d",parity),UVM_LOW)
        end

        repeat(16) @(posedge vif.uart_mon_cb.baud_o); // wait for stop bit

        // Send collected data to SB
        uart_mon_port.write(xtnh);
        
        $display("UART ==> Sampling transactions");
                        xtnh.print();
    endtask 
endclass : uart_mon
