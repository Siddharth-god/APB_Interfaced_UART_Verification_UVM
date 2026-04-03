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
        //vif.tx <= 1; // Idle bit 
        forever begin 
            seq_item_port.get_next_item(req);
            send_to_dut(req); 
            $display("UART ==> Driving transactions");
            req.print();
            seq_item_port.item_done();
        end
    endtask     

    task send_data(bit tx);
        vif.tx <= tx; 
        repeat(16) @(posedge vif.baud_o);
    endtask  

    task send_to_dut(uart_xtn xtnh);
        int bits; // This we already have in xtn right ?? we can just use that. 
        bits = LCR[1:0] + 5; // This is also we already did in post_randomize right ?? Why again here ? 
        repeat(16) @(posedge vif.baud_o);

        vif.tx <= 0; // Start bit 

        repeat(16) @(posedge vif.baud_o);

        for(int i=0; i<xtnh.bits; i++) begin 
            send_data(xtnh.tx[i]); // tx lies in xtnh | bits are for no of data bits only. 
        end

        if(LCR[3])
            //vif.tx <= xtnh.parity; // I can also do this way right ? Ask mam. 
            send_data(xtnh.parity); // we already calculated parity in post_randomize in xtn we use that 

        //repeat(16) @(posedge vif.baud_o);
            //vif.tx <= xtnh.stop_bit;   //=====> Also can be done this way, needs one more line for baud pulse

        send_data(xtnh.stop_bit);
            
        // Additional wait for specific configurations 
        if(LCR[2] == 1) begin // if stop bits are 2
            if(LCR[1:0] == {2'b00 || 2'b01 || 2'b10 || 2'b11}) // Why only for 5 bits ?? Don't we check 6-8 ? 
                repeat(8) @(posedge vif.baud_o);
        end   
    endtask  
endclass 
