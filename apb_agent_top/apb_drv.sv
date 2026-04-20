
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
        @(vif.apb_drv_cb) begin 
        // CPU/APB is driving 
            //vif.apb_drv_cb.PRESETn   <= xtn_h.PRESETn; // when removed compiler started working - with this it is getting stuck check why ? 
            vif.apb_drv_cb.PWRITE   <= xtn_h.PWRITE; // Because this is randomized
            vif.apb_drv_cb.PWDATA   <= xtn_h.PWDATA; // Because this is randomized
            vif.apb_drv_cb.PADDR    <= xtn_h.PADDR;  // Because this is randomized
            vif.apb_drv_cb.PSEL     <= 1;
            vif.apb_drv_cb.PENABLE  <= 0; 
        end
        
        @(vif.apb_drv_cb);
            vif.apb_drv_cb.PENABLE  <= 1; 
            
        // stay in ACCESS until ready
        do begin
            @(vif.apb_drv_cb);
        end while(!vif.apb_drv_cb.PREADY);

        if(xtn_h.PADDR == 32'h8 && xtn_h.PWRITE == 0) begin
            while(vif.apb_drv_cb.IRQ === 0)  
                @(vif.apb_drv_cb); 

        //xtn_h.IIR = vif.apb_drv_cb.PRDATA; // Changed from below -- 
        xtn_h.IIR = vif.PRDATA;

        // seq_item_port.put_response(xtn_h); //===>  it only fires when PADDR==8 && PWRITE==0. But get_response in the sequence is called unconditionally after every finish_item. So for every non-IIR transaction, get_response hangs forever waiting for a response that never comes.
    end
        seq_item_port.put_response(xtn_h); // Moved put response outside the if block so it fires for every transaction, and always populate IIR and PRDATA into the response before sending
    
        vif.apb_drv_cb.PSEL     <= 0; // Go to IDLE (PSEL is used to select the apb slaves - dut is our slave of APB)
        vif.apb_drv_cb.PENABLE  <= 0; // It should instantly got to idle as out apb fsm is working that way
    endtask

endclass 
