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
    endfunction 

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        xtnh = uart_xtn::type_id::create("xtnh");

        if(!uvm_config_db #(uart_agent_config)::get(this,"","uart_agent_config",uart_cfg))
            `uvm_fatal(get_type_name(),"Failed to get uart_cfg in UART MON from TEST")

        if(!uvm_config_db #(bit [7:0])::get(this,"*","lcr",LCR)) //why are we using "*" ?? Ask mam, we don't need to use right.
            `uvm_fatal(get_type_name(),"Failed to get LCR in UART MON from TEST")

    endfunction  
    
    function void connect_phase(uvm_phase phase);
        vif = uart_cfg.vif; 
    endfunction

    task run_phase(uvm_phase phase);
        bit rx_busy, tx_busy; 
            fork
                // uart monitor rx line 
                forever begin 
                    if(rx_busy == 0) begin : rx_line
                        rx_busy = 1; 
                        collect_uart_data(vif.rx, xtnh.rx, xtnh.parity); // vif.rx acting as line here ? how 
                        rx_busy = 0; 
                    end : rx_line
                    else begin 
                        @(posedge vif.baud_o);
                    end
                end
               
                // uart monitor tx line  
                forever begin 
                    if(tx_busy == 0) begin : tx_line
                        tx_busy = 1; 
                        collect_uart_data(vif.tx, xtnh.tx, xtnh.parity); // we collect the data from [vif.tx/rx] and then store it in [xtn.tx/rx and also xtn.parity] ===> In collect data we are doing assignment operation in for loop. 
                        tx_busy = 0; 
                    end : tx_line
                    else begin 
                        @(posedge vif.baud_o);
                    end
                end
            join
    endtask 

    task collect_uart_data(ref logic line, ref bit[7:0] data, ref bit parity); // line can be bit also right ? 
        int bits; 

        bits = LCR[1:0] + 5; // total data bits 

        wait(line == 1); // Idle --> is it stop bit ? ask mam 
        @(posedge vif.baud_o) 
        wait(line == 0); // Wait for start bit

        repeat(24) @(posedge vif.baud_o); // wait for 24 pulses ? we sample in between but what about first 16 sampels ? there it is not getting sampled ? ==> UART Protocol says that sampling of bit between 2 uarts should happen in between the first bit and second bit is driving. that is 24. as first bit driven at 16 baud pulse and 2nd driven at 32. 


        // Collect the data bits 
        for(int i=0; i<bits; i++) begin 
            data[i] = line; // From interface/DUT - get the values into txn class, where data[i](its a single bit) acts as tx or rx bit. 
            repeat(16) @(posedge vif.baud_o); // wait for 16 pulses
        end

        // Collect parity bit if enabled 
        if(LCR[3])
            parity = line;
            @(posedge vif.baud_o);

        $display("UART ==> Sampling transactions");
                        xtnh.print();
    endtask 
endclass : uart_mon
