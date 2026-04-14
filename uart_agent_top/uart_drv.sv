
//-----------------------------------------------------UART DRIVER------------------------------------------------------
class uart_drv extends uvm_driver #(uart_xtn);
    `uvm_component_utils(uart_drv)

    uart_agent_config uart_cfg; 
    virtual uart_if vif; 
    bit [7:0] LCR; 

    function new(string name="",uvm_component parent);
        super.new(name,parent);
    endfunction 

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // req.LCR = LCR; // we get the value for LCR from Sequence so no need for this 

        if(!uvm_config_db #(uart_agent_config)::get(this,"","uart_agent_config",uart_cfg))
            `uvm_fatal(get_type_name(),"Failed to get uart_cfg in uart_driver from ENV")

        if(!uvm_config_db #(bit [7:0])::get(this,"","lcr",LCR))
            `uvm_fatal(get_type_name(),"Failed to get LCR in uart_driver from TEST")

    endfunction 
    function void connect_phase(uvm_phase phase);
        vif = uart_cfg.vif;
        $display("In uart driver vif connection happened %p",vif); 
    endfunction 

    task run_phase(uvm_phase phase);
        vif.uart_drv_cb.tx <= 1; // Idle bit 
        forever begin 
            seq_item_port.get_next_item(req);
            send_to_dut(req); 
            $display("UART ==> Driving transactions");
            req.print();
            seq_item_port.item_done();
        end
    endtask     

    task send_data(bit tx);
        vif.uart_drv_cb.tx <= tx; 
        repeat(16) @(posedge vif.uart_drv_cb.baud_o);
    endtask  

    task send_to_dut(uart_xtn xtnh);
        int bits; // This we already have in xtn right ?? we can just use that. 
        bits = LCR[1:0] + 5; // This is also we already did in post_randomize right ?? Why again here ? 

        // Guard time before passing frame
        @(posedge vif.uart_drv_cb.baud_o);
        $display("=========================== UART AGENT DRV After Guard TIME ============================");

        vif.uart_drv_cb.tx <= 0; // Start bit 

        repeat(16) @(posedge vif.uart_drv_cb.baud_o);

        for(int i=0; i<bits; i++) begin 
            send_data(xtnh.tx[i]);  
        end

        if(LCR[3])
            send_data(xtnh.parity); // we already calculated parity in post_randomize in xtn we use that 

        send_data(xtnh.stop_bit);
            
        if(LCR[2] == 1) begin // if stop bits are 2
            if(LCR[1:0] == 2'b00) // Why only for 5 bits ?? Don't we check 6-8 ? 
                repeat(8) @(posedge vif.uart_drv_cb.baud_o);
        end   
    endtask  
endclass 