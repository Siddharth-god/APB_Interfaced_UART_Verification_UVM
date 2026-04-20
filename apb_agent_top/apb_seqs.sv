
//xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx SEQUENCES xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

//-----------------------------------------------------APB SEQS-------------------------------------------------------
class apb_seq_base extends uvm_sequence #(apb_xtn);
    `uvm_object_utils(apb_seq_base)

    function new(string name="apb_seq_base");
        super.new(name);
    endfunction

    bit [7:0] LCR; // Getting from test (for better control over LCR and avoid repetition)

    task body();
        if(!uvm_config_db #(bit [7:0])::get(null,get_full_name(),"lcr",LCR))
            `uvm_fatal(get_type_name(),"Cannot get LCR in uart base sequence from TEST")

        $display("------------------------- LCR Value in apb_sequence %0d",LCR);
    endtask
endclass 

// Reset check 
class apb_rst_check extends apb_seq_base;
    `uvm_object_utils(apb_rst_check)

    function new(string name="apb_rst_check_h");
        super.new(name);
    endfunction

    task body();
        req = apb_xtn::type_id::create("req");

        // LCR
        start_item(req); 
        assert(req.randomize() with {
            PRESETn == 1;
            PADDR == 'h3; // LCR
            PWRITE == 0; 
        });
        finish_item(req);
        get_response(req);

        if(req.PADDR == 'h3 && req.PRDATA == 0)
            `uvm_info("RESET_CHECK",$sformatf("\nLCR match: %0h\n", req.PRDATA),UVM_INFO)
        else
            `uvm_error("RESET_CHECK", $sformatf("LCR mismatch: %0h", req.PRDATA));

        // LSR
        start_item(req);
        assert(req.randomize() with {
            PRESETn == 1;
            PADDR == 'h5; // LSR
            PWRITE == 0; 
        });
        finish_item(req);
        get_response(req);

        if(req.PADDR == 'h14 && req.PRDATA == 'h60)
            `uvm_info("RESET_CHECK",$sformatf("\nLSR match: %0h\n", req.PRDATA),UVM_INFO)
        else
            `uvm_error("RESET_CHECK", $sformatf("LSR mismatch: %0h", req.PRDATA));

        // IER
        start_item(req);
        assert(req.randomize() with {
            PRESETn == 1;
            PADDR == 'h1; // IER
            PWRITE == 0; 
        });
        finish_item(req);
        get_response(req);

        if(req.PADDR == 'h1 && req.PRDATA == 0)
            `uvm_info("RESET_CHECK",$sformatf("\nIER match: %0h\n", req.PRDATA),UVM_INFO)
        else
            `uvm_error("RESET_CHECK", $sformatf("IER mismatch: %0h", req.PRDATA));

        // IIR
        /* IIR mismatch — timing issue, not a value issue
IIR reset value in RTL is 4'h1, so PRDATA should be 'h1. But log shows PRDATA = 0. The reason is a clocking skew issue in your driver — you are reading PRDATA on the same clock edge that PREADY goes high, but PRDATA from the combinational readback path needs one more cycle to be stable through the clocking block.*/
        start_item(req);
        assert(req.randomize() with {
            PRESETn == 1;
            PADDR == 'h2; // IIR
            PWRITE == 0; 
        });
        finish_item(req);
        get_response(req);

        if(req.PADDR == 'h2 && req.PRDATA == 'h1)
            `uvm_info("RESET_CHECK",$sformatf("\nIIR match: %0h\n", req.PRDATA),UVM_INFO)
        else
            `uvm_error("RESET_CHECK", $sformatf("IIR mismatch: %0h", req.PRDATA));

        // MCR 
        start_item(req);
        assert(req.randomize() with {
            PRESETn == 1;
            PADDR == 'h4; // FCR
            PWRITE == 0; 
        });
        finish_item(req);
        get_response(req);

        if(req.PADDR == 'h4 && req.PRDATA == 'h0)
            `uvm_info("RESET_CHECK",$sformatf("\nMCR match: %0h\n", req.PRDATA),UVM_INFO)
        else
            `uvm_error("RESET_CHECK", $sformatf("MCR mismatch: %0h", req.PRDATA));
       
    endtask
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
        super.body();
        req = apb_xtn::type_id::create("req");
        req.LCR = LCR; // If this is not set --> Full duplex will fail. 
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
        assert(req.randomize() with {PADDR==32'hC; PWRITE==1; PWDATA==LCR;});
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
        super.body();
        $display("----------------------------- APB Overrun Sequence -----------------------------");
        req = apb_xtn::type_id::create("req");
        req.LCR = LCR;

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
        assert(req.randomize() with { PADDR == 32'h0c; PWRITE == 1; PWDATA == LCR; }); // lcr is 7 stop bit is 1
        finish_item(req);

        // FCR
        start_item(req);
        assert(req.randomize() with { PADDR == 32'h08; PWRITE == 1; PWDATA == 8'b1100_0111; }); //Once the flush is done, bits[1:2] auto-reset to 0, but bit[0] stays as you set it. That's why you need 8'b00000111 — so FIFO remains enabled after the flush.
        finish_item(req); // Changed threshold value to 14 as repeat happening 17 times 
        /*
        FCR = 8'b00000111 (0x07)

        You flush first (bits[1:2] = 1) to start from a clean empty FIFO
        You keep it enabled (bit[0] = 1) so the FIFO stays active after flush
        After flush completes, bits[1:2] auto-clear to 0, leaving FCR = 8'b00000001

            bit[0] = 1 → FIFO Enable    : Keeps FIFO active after flush
            bit[1] = 1 → RX FIFO Reset  : Flushes RX FIFO (self-clearing)
            bit[2] = 1 → TX FIFO Reset  : Flushes TX FIFO (self-clearing)

            After flush:
            - bits[1:2] auto-clear to 0
            - bit[0] stays 1 → FIFO remains enabled
            - Result: Clean empty FIFO, ready to be filled

            Why this matters for Overrun:
            - FIFO disabled → only 1 byte buffer → overrun on 2nd byte (unreliable test)
            - FIFO enabled  → 16 byte buffer → fill all 16 + 1 in shift register
                → controlled overrun on 17th write (correct test)
        */

        // IER
        //start_item(req);start_item(req);  // ← duplicate start_item! --> This will cause a sequencer hang or protocol violation — the item is started twice before being finished.
        start_item(req); // Removed repeated start_item
        assert(req.randomize() with { PADDR == 32'h04; PWRITE == 1; PWDATA == 8'b0000_0100; });
        finish_item(req);

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
        assert(req.randomize() with { PADDR == 32'h0c; PWRITE == 1; PWDATA == 8'h0000_0111; }); 
                        // LCR[2] high (2 stop bits => Receiving 1 stop bit ==> Framing error)
        finish_item(req);

        // FCR
        start_item(req);
        assert(req.randomize() with { PADDR == 32'h08; PWRITE == 1; PWDATA == 8'b00000110; }); // No need to enable fifo, not storing values => FCR=8'h06 is correct for error tests — just flushes TX/RX FIFOs and leaves FIFO disabled. One frame is enough to trigger framing/parity error so don't need FIFO enabled.
        finish_item(req);

        // IER
        // start_item(req);start_item(req); // Causing the halt in simulation. 
        start_item(req); 
        assert(req.randomize() with { PADDR == 32'h04; PWRITE == 1; PWDATA == 8'b00000100; });
        finish_item(req);

    endtask
endclass

//------------------------------------------------ PARITY SEQUENCE ------------------------------------------------
class apb_parity_seq extends apb_seq_base;

    `uvm_object_utils(apb_parity_seq)

    function new(string name = "apb_parity_seq");
        super.new(name);
    endfunction

    task body();

        super.body();

        req = apb_xtn::type_id::create("req");
        req.LCR = LCR;

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
        assert(req.randomize() with { PADDR == 32'h0c; PWRITE == 1; PWDATA == LCR; }); // LCR[3] high => 1 is even parity, 0 is odd. bad parity enabled in uart_seq. Means it should give us even parity while we want odd parity
        finish_item(req);

        // FCR
        start_item(req);
        assert(req.randomize() with { PADDR == 32'h08; PWRITE == 1; PWDATA == 8'b00000110; });
        finish_item(req);

        // IER
        start_item(req); 
        assert(req.randomize() with { PADDR == 32'h04; PWRITE == 1; PWDATA == 8'b00000100; });
        finish_item(req);

        // start_item(req);
        // assert(req.randomize() with { PADDR == 32'h00; PWRITE == 1; });
        // finish_item(req);
    endtask
endclass


//------------------------------------------------ Break SEQUENCE ------------------------------------------------
class apb_break_seq extends apb_seq_base;

    `uvm_object_utils(apb_break_seq)

    function new(string name = "apb_break_seq");
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
        assert(req.randomize() with { PADDR == 32'h0c; PWRITE == 1; PWDATA == LCR; }); // LCR[6] high => 1 is break error.
        finish_item(req);

        // FCR
        start_item(req);
        assert(req.randomize() with { PADDR == 32'h08; PWRITE == 1; PWDATA == 8'b0000_0110; }); // For time out we might need to read and store values as there will be another frame on the way but doesn't come so timeout 
        finish_item(req);

        // IER
        start_item(req); 
        assert(req.randomize() with { PADDR == 32'h04; PWRITE == 1; PWDATA == 8'b0000_0100; });
        finish_item(req);

    endtask
endclass


//------------------------------------------------ Timeout SEQUENCE ------------------------------------------------
class apb_timeout_seq extends apb_seq_base;

    `uvm_object_utils(apb_timeout_seq)

    function new(string name = "apb_timeout_seq");
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
        assert(req.randomize() with { PADDR == 32'h0c; PWRITE == 1; PWDATA == LCR; }); // LCR[6] high => 1 is break error.
        finish_item(req);

        // FCR
        start_item(req);
        assert(req.randomize() with { PADDR == 32'h08; PWRITE == 1; PWDATA == 8'b0100_0110; }); // trigger level is 4, data should not come till 4 frames.
        finish_item(req);

        // IER
        start_item(req); 
        assert(req.randomize() with { PADDR == 32'h04; PWRITE == 1; PWDATA == 8'b0000_0100; });
        finish_item(req);

    endtask
endclass


// //------------------------------------------------ THR EMPTY SEQUENCE ------------------------------------------------
// class apb_thr_empty_seq extends apb_seq_base;

//     `uvm_object_utils(apb_thr_empty_seq)

//     function new(string name = "apb_thr_empty_seq");
//         super.new(name);
//     endfunction

//     task body();

//         super.body();

//         req = apb_xtn::type_id::create("req");

//         // DIV1 MSB
//         start_item(req);
//         assert(req.randomize() with { PADDR == 32'h20; PWRITE == 1; PWDATA == 0; });
//         finish_item(req);

//         // DIV2 LSB
//         start_item(req);
//         assert(req.randomize() with { PADDR == 32'h1c; PWRITE == 1; PWDATA == 54; });
//         finish_item(req);

//         // NORMAL_MODE_LCR
//         start_item(req);
//         assert(req.randomize() with { PADDR == 32'h0c; PWRITE == 1; PWDATA == LCR; }); // LCR[6] high => 1 is break error.
//         finish_item(req);

//         // FCR
//         start_item(req);
//         assert(req.randomize() with { PADDR == 32'h08; PWRITE == 1; PWDATA == 8'b0100_0110; });
//         finish_item(req);

//         // IER
//         start_item(req); 
//         assert(req.randomize() with { PADDR == 32'h04; PWRITE == 1; PWDATA == 8'b0000_0100; });
//         finish_item(req);

//     endtask
// endclass