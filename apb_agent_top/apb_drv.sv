
//xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx DRIVERS xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

//-----------------------------------------------------APB DRIVER-------------------------------------------------------
class apb_drv extends uvm_driver #(apb_xtn); 
    `uvm_component_utils(apb_drv)

    apb_agent_config apb_cfg; 
    virtual apb_if vif; 

    function new(string name="",uvm_component parent);
        super.new(name,parent);
    endfunction 

    function void build_phase(uvm_phase phase); 
        super.build_phase(phase);
        if(!uvm_config_db #(apb_agent_config)::get(this,"","apb_agent_config",apb_cfg))
            `uvm_fatal(get_type_name(),"Failed to get apb_cfg from ENV")

    endfunction 

    function void connect_phase(uvm_phase phase);
        vif = apb_cfg.vif; 
    endfunction 

    task run_phase(uvm_phase phase);
        @(vif.apb_drv_cb);
            vif.apb_drv_cb.PRESETn <= 0;
        @(vif.apb_drv_cb);
            vif.apb_drv_cb.PRESETn <= 1;
        forever begin 
            seq_item_port.get_next_item(req);
            send_to_dut(req);
            $display("APB ==> DRIVING THE DATA------------------");
            req.print();
            seq_item_port.item_done();
        end
    endtask 

    task send_to_dut(apb_xtn xtn_h);
        @(vif.apb_drv_cb);
        // CPU/APB is driving 
            vif.apb_drv_cb.PWRITE   <= xtn_h.PWRITE; // Because this is randomized
            vif.apb_drv_cb.PWDATA   <= xtn_h.PWDATA; // Because this is randomized
            vif.apb_drv_cb.PADDR    <= xtn_h.PADDR;  // Because this is randomized
            vif.apb_drv_cb.PSEL     <= 1;
            vif.apb_drv_cb.PENABLE  <= 0; 
        
        @(vif.apb_drv_cb);
            vif.apb_drv_cb.PENABLE  <= 1; 
        
        @(vif.apb_drv_cb);  
            while(!vif.apb_drv_cb.PREADY)
                @(vif.apb_drv_cb);

        if(xtn_h.PADDR == 32'h8 && xtn_h.PWRITE == 0) begin
            while(vif.apb_drv_cb.IRQ === 0)  
                @(vif.apb_drv_cb); 

        xtn_h.IIR = vif.apb_drv_cb.PRDATA;
        seq_item_port.put_response(xtn_h); 
    end
        vif.apb_drv_cb.PSEL     <= 0; // Go to IDLE (PSEL is used to select the apb slaves - dut is our slave of APB)
        vif.apb_drv_cb.PENABLE  <= 0;
    endtask

endclass 
