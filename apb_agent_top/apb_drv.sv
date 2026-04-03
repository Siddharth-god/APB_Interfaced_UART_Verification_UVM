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
            $display("------------------APB ==> DRIVING THE DATA------------------");
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
            vif.apb_drv_cb.PENABLE  <= 0; // SETUP STATE --> PENB = 0 & PSEL = 1 ==> we will be one in apb fsm in design 
        
        @(vif.apb_drv_cb);
            vif.apb_drv_cb.PENABLE  <= 1; // After 1 cc GO TO ACCESS state. // we == 0 and re == 1 in apb fsm
        
        @(vif.apb_drv_cb); // Ask mam - how and from where PREADY comes from slave right ?? So how can we use driver ? 
            while(!vif.apb_drv_cb.PREADY) // Waiting For Slave to be READY to RECEIVE the DATA.
            //==> If PREADY is 1, move to next state (otherwise wait for 1cc) --> while declares continuity (means if PREADY is 0 keep waiting)
                @(vif.apb_drv_cb);

// NOTE : We want to resolve the interrpts so for that we need the interrupt info and based on that interrupt we again drive the sequence to DUT and resolve the interrupt. So, we get the response from the driver. 
// We won't read everything here, we have monitor for that, using this info we will write the logic and seq and drive that so that's why we take only needed info from driver. 

        // IIR Register --> Address == 0x8 and IIR is READ ONLY so PWRITE == 0. If PWRITE == 1 => FCR 
        if(xtn_h.PADDR == 32'h8 && xtn_h.PWRITE == 0) begin
            while(!vif.apb_drv_cb.IRQ === 0) // Wait for the interrupt - (if no interrupt high --> Keep waiting) => IRQ tells there is an Interrupt when it is HIGH. ==> When IRQ is high then only we can read IIR and for IRQ to go HIGH IER must enable the interrupt. 
                @(vif.apb_drv_cb); 

        xtn_h.IIR = vif.apb_drv_cb.PRDATA; // Sample the IIR register value from the UART using PRDATA, So that sequence can be generated according to IIR value. ----> We are using response method of DRIVER. (So sampling is done in DRIVER)
        seq_item_port.put_response(xtn_h); // put resp so seq can get it; 
    end
        vif.apb_drv_cb.PSEL     <= 0; // Go to IDLE
        vif.apb_drv_cb.PENABLE  <= 0;
    endtask


endclass 