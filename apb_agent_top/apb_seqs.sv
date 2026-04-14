
//xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx SEQUENCES xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

//-----------------------------------------------------APB SEQS-------------------------------------------------------
class apb_seq_base extends uvm_sequence #(apb_xtn);
    `uvm_object_utils(apb_seq_base)

    function new(string name="apb_seq_base");
        super.new(name);
    endfunction
endclass 


// half duplex ------------------------------
class apb_half_duplex extends apb_seq_base;
    `uvm_object_utils(apb_half_duplex)

    function new(string name="apb_half_duplex");
        super.new(name);
    endfunction

    task body();
        //super.body();
        req = apb_xtn::type_id::create("req");

        // DIVISOR LATCH REG - MSB
        start_item(req);
        assert(req.randomize() with {PADDR==32'h20; PWRITE==1; PWDATA==0;});
        finish_item(req);

        // DIVISOR LATCH REG - LSB
        start_item(req);
        assert(req.randomize() with {PADDR==32'h1C; PWRITE==1; PWDATA==54;}); // 27 is the value of baud rate we have generated, using frequency. Another side value will be generated in the TOP module, because another UART side is not a DUT it is AGENT in our case so we cannot drive the value to agent, we have to take it from TOP using CONFIG class. 
        finish_item(req); // mam passing 54 as pwdata for div lsb

        // LINE CONTROL REG --> Used to configure the data size and behaviour
        start_item(req);
        assert(req.randomize() with {PADDR==32'hC; PWRITE==1; PWDATA==8'b0000_0011;});
        finish_item(req);

        // FIFO (ENABLE)CONTROL REG --> bit[0] always 0 | Resets RX_FIFO[bit 1] & TX_FIFO[bit 2] | bit[5:3] reserved | bit[6:7] RX_FIFO Interrupt threshold
        start_item(req);
        assert(req.randomize() with {PADDR==32'h08; PWRITE==1; PWDATA==8'b0000_0110;}); // Resetting rx & tx fifo every seq start
        finish_item(req);

        // INTERRUPT ENABLE --> bit 0 = Received data at threshold interrupt | bit 1 = THR Empty interrupt | bit 2 = Receiver Line status Interrupt
        start_item(req);
        assert(req.randomize() with {PADDR==32'h04; PWRITE==1; PWDATA==8'b0000_0101;});
        finish_item(req);

        // // THR REG -->  // We must not provide thr here. WHy ?? because our sb condition relies on thr empty, agar thr has value then it will always fail and go to full duplex and half duplex won't be printing. 
        // start_item(req);
        // assert(req.randomize() with {PADDR==32'h0; PWRITE==1; PWDATA==5;});
        // finish_item(req);
    endtask
endclass 

//------------------------------------------------ READ SEQUENCE ------------------------------------------------
class apb_read_seq extends apb_seq_base; 
    `uvm_object_utils(apb_read_seq)

    function new(string name="apb_read_seq");
        super.new(name);
    endfunction

    task body();
        //super.body(); 
        req = apb_xtn::type_id::create("req");
        $display("<<<<<<<<----------<<<<<<<< READ sequence started >>>>>>>>---------->>>>>>>>");

        // IIR REG --> 
        // do begin
        //     start_item(req);
        //     assert(req.randomize() with {PADDR==32'h08; PWRITE==0;}); // IIR
        //     finish_item(req);
        //     get_response(req);
        // end while (req.IIR != 4 || req.IIR != 6);

        start_item(req);
        //! we cannot solve the interrupt from another uart, as interrupt cannot be sent to uart 2 (so we need to read IIR here)
        assert(req.randomize() with {PADDR==32'h08; PWRITE==0;}) // IIR is Read only reg. 
        finish_item(req);
        get_response(req); // getting the response from driver, when driver samples it. 

        if(req.IIR == 4) begin // When IIR == 0x4 (Interrupt --> RECEIVED DATA AVAILABLE ==> Read from RBR)
        // RBR  
        start_item(req);
        assert(req.randomize() with {PADDR==32'h0; PWRITE==0;})
        finish_item(req);
        end

        if(req.IIR == 6) begin // When IIR == 0x4 (Interrupt --> READ LINE STATUS REG => Overrun,parity,framing,break errors)
        // LSR  
        start_item(req);
        assert(req.randomize() with {PADDR==32'h14; PWRITE==0;})
        finish_item(req);
        end

    endtask

endclass 

//------------------------------------------------ FULL DUPLEX SEQUENCE ------------------------------------------------
class apb_full_duplex extends apb_seq_base;
    `uvm_object_utils(apb_full_duplex)

    function new(string name="apb_full_duplex");
        super.new(name);
    endfunction

     task body();
        //super.body();
        req = apb_xtn::type_id::create("req");
        $display("<<<<<<<<----------<<<<<<<< Full Duplex sequence started >>>>>>>>---------->>>>>>>>");

        // DIVISOR LATCH REG - MSB
        start_item(req);
        assert(req.randomize() with {PADDR==32'h20; PWRITE==1; PWDATA==0;});
        finish_item(req);

        // DIVISOR LATCH REG - LSB
        start_item(req);
        assert(req.randomize() with {PADDR==32'h1C; PWRITE==1; PWDATA==54;});  
        finish_item(req); 

        // LINE CONTROL REG 
        start_item(req);
        assert(req.randomize() with {PADDR==32'hC; PWRITE==1; PWDATA==8'b0000_0011;});
        finish_item(req);

        // FIFO (ENABLE)CONTROL REG 
        start_item(req);
        assert(req.randomize() with {PADDR==32'h08; PWRITE==1; PWDATA==8'b0000_0110;});
        finish_item(req);

        // INTERRUPT ENABLE 
        start_item(req);
        assert(req.randomize() with {PADDR==32'h04; PWRITE==1; PWDATA==8'b0000_0101;});
        finish_item(req);

        // THR REG --> 
        start_item(req);
        assert(req.randomize() with {PADDR==32'h0; PWRITE==1; PWDATA==55;});
        finish_item(req);

    endtask
endclass 


//------------------------------------------------ LOOPBACK SEQUENCE ------------------------------------------------
class apb_loopback extends apb_seq_base;
    `uvm_object_utils(apb_loopback)

    function new(string name="apb_loopback");
        super.new(name);
    endfunction

    task body();
        req = apb_xtn::type_id::create("req");
        $display("<<<<<<<<----------<<<<<<<< Loopback sequence started >>>>>>>>---------->>>>>>>>");

        // DIVISOR LATCH REG - MSB
        start_item(req);
        assert(req.randomize() with {PADDR==32'h20; PWRITE==1; PWDATA==0;});
        finish_item(req);

        // DIVISOR LATCH REG - LSB
        start_item(req);
        assert(req.randomize() with {PADDR==32'h1C; PWRITE==1; PWDATA==54;});  
        finish_item(req); 

        // LINE CONTROL REG 
        start_item(req);
        assert(req.randomize() with {PADDR==32'hC; PWRITE==1; PWDATA==8'b0000_0011;});
        finish_item(req);

        // FIFO (ENABLE)CONTROL REG 
        start_item(req);
        assert(req.randomize() with {PADDR==32'h08; PWRITE==1; PWDATA==8'b0000_0110;});
        finish_item(req);

        // INTERRUPT ENABLE 
        start_item(req);
        assert(req.randomize() with {PADDR==32'h04; PWRITE==1; PWDATA==8'b0000_1101;});
        finish_item(req);

        // MCR loopback  
        start_item(req);
        assert(req.randomize() with {PADDR==32'h10; PWRITE==1; PWDATA==8'b0001_0000;});
        finish_item(req);

        // THR REG --> 
        start_item(req);
        assert(req.randomize() with {PADDR==32'h0; PWRITE==1; PWDATA==55;});
        finish_item(req); 
    endtask
endclass 


//------------------------------------------------ OVERRUN SEQUENCE ------------------------------------------------
class apb_overrun_seq extends apb_seq_base;

    `uvm_object_utils(apb_overrun_seq)

    function new(string name = "apb_overrun_seq");
        super.new(name);
    endfunction

    task body();

        req = apb_xtn::type_id::create("req");

        // DIV1 MSB
        start_item(req);
        assert(req.randomize() with { PADDR == 32'h20; PWRITE == 1; PWDATA == 0; });
        finish_item(req);

        // DIV2 LSB
        start_item(req);
        assert(req.randomize() with { PADDR == 32'h1c; PWRITE == 1; PWDATA == 54; });
        finish_item(req);

        // NORMAL_MODE_LCR
        start_item(req);
        assert(req.randomize() with { PADDR == 32'h0c; PWRITE == 1; PWDATA == 8'h0000_0111; }); // How to get the LCR from test here ?
        finish_item(req);

        // FCR
        start_item(req);
        assert(req.randomize() with { PADDR == 32'h08; PWRITE == 1; PWDATA == 8'b00000100; });
        finish_item(req);

        // IER
        start_item(req);start_item(req);
        assert(req.randomize() with { PADDR == 32'h04; PWRITE == 1; PWDATA == 8'b00000101; });
        finish_item(req);

        repeat (17) begin
            start_item(req);
            assert(req.randomize() with { PADDR == 32'h00; PWRITE == 1; });
            finish_item(req);
        end
    endtask
endclass



//------------------------------------------------ FRAMING SEQUENCE ------------------------------------------------
class apb_framing_seq extends apb_seq_base;

    `uvm_object_utils(apb_framing_seq)

    function new(string name = "apb_framing_seq");
        super.new(name);
    endfunction

    task body();

        super.body();

        req = apb_xtn::type_id::create("req");

        // DIV1 MSB
        start_item(req);
        assert(req.randomize() with { PADDR == 32'h20; PWRITE == 1; PWDATA == 0; });
        finish_item(req);

        // DIV2 LSB
        start_item(req);
        assert(req.randomize() with { PADDR == 32'h1c; PWRITE == 1; PWDATA == 54; });
        finish_item(req);

        // NORMAL_MODE_LCR
        start_item(req);
        assert(req.randomize() with { PADDR == 32'h0c; PWRITE == 1; PWDATA == 8'h0000_0011; }); // How to get the LCR from test here ?
        finish_item(req);

        // FCR
        start_item(req);
        assert(req.randomize() with { PADDR == 32'h08; PWRITE == 1; PWDATA == 8'b00000110; });
        finish_item(req);

        // IER
        start_item(req);start_item(req);
        assert(req.randomize() with { PADDR == 32'h04; PWRITE == 1; PWDATA == 8'b00000100; });
        finish_item(req);

        start_item(req);
        assert(req.randomize() with { PADDR == 32'h00; PWRITE == 1; });
        finish_item(req);
    endtask
endclass
