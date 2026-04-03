//xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx SEQUENCES xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

//-----------------------------------------------------APB SEQS-------------------------------------------------------
class apb_seq_base extends uvm_sequence #(apb_xtn);
    `uvm_object_utils(apb_seq_base)

    function new(string name="apb_seq_base");
        super.new(name);
    endfunction

    // Reusable write 
    task do_write(bit[31:0]addr, bit[31:0]data);
        start_item(req);
        assert(req.randomize() with {PADDR==addr; PWRITE==1; PWDATA==data;});
        finish_item(req);
    endtask

    // Reusable read 
    task do_read(bit[31:0]addr);
        start_item(req);
        assert(req.randomize() with {PADDR==addr; PWRITE==0;});
        finish_item(req);
    endtask

    // Flexible config task
    task uart_reg_config(
        bit[7:0] lcr_val = 8'b0000_0011,
        bit[7:0] fcr_val = 8'b0000_0110,
        bit[7:0] ier_val = 8'b0000_0101,
        int divisor = 27
    );
        // DIVISOR MSB
        do_write(32'h20, divisor[15:8]); // this divisor value will be 0, as 27 is not in the range for this.

        // DIVISOR LSB
        do_write(32'h1C, divisor[7:0]);  // 27 will automatically falls inside 7:0

        // LCR REG - Flexibal
        do_write(32'hC, lcr_val); //--> Used to configure the data size and behaviour

        // FCR REG - Flexibal
        do_write(32'h08, fcr_val); // FCR = 8'b0000_0110; This resets FIFO every sequence start - This does not check real behaviour. 
 
        // IER REG - Flexibal
        do_write(32'h04, ier_val);
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

    // Why Divisor latch we have configured first ?? --> DVL decides the baud rate for the UART so it must be confgured first.
        // DIVISOR LATCH REG - MSB
        start_item(req);
        assert(req.randomize() with {PADDR==32'h20; PWRITE==1; PWDATA==0;});
        finish_item(req);

        // DIVISOR LATCH REG - LSB
        start_item(req);
        assert(req.randomize() with {PADDR==32'h1C; PWRITE==1; PWDATA==27;}); // 27 is the value of baud rate we have generated, using frequency. Another side value will be generated in the TOP module, because another UART side is not a DUT it is AGENT in our case so we cannot drive the value to agent, we have to take it from TOP using CONFIG class. 
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

        // THR REG --> 
        start_item(req);
        assert(req.randomize() with {PADDR==32'h0; PWRITE==1; PWDATA==5;});
        finish_item(req);

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

        // FIFO CONTROL REG --> 
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
        // RBR  
        start_item(req);
        assert(req.randomize() with {PADDR==32'h14; PWRITE==0;})
        finish_item(req);
        end
    endtask

// why are we not checking Line status interrupt ? Because it has errors ?? 
// We are getting the interrupts but where are we resolving them ? How we do that ? ask mam
endclass 

/*
//------------------------------------------------ FULL DUPLEX SEQUENCE ------------------------------------------------
class full_duplex extends apb_seq_base;
    `uvm_object_utils(full_duplex)

    function new(string name="full_duplex");
        super.new(name);
    endfunction

    task body();
        req = apb_xtn::type_id::create("req");

        uart_reg_config();

        // THR REG --> 
        fork
            do_write(32'h0, 32'h55); // transmit 
            do_read(32'h0); // Receive 
        join

    endtask
endclass 


//------------------------------------------------ LOOPBACK SEQUENCE ------------------------------------------------
class loopback extends apb_seq_base;
    `uvm_object_utils(loopback)

    function new(string name="loopback");
        super.new(name);
    endfunction

    task body();
        req = apb_xtn::type_id::create("req");

        uart_reg_config();

        do_write(32'h10, 8'b0001_0000); // MCR loopback enable [5th bit for loopback] (do write can take upto 32 bits but we can also give 8 bits other will become 0)

        do_write(32'h0, 32'h5A); // THR → data goes into TX → looped back internally → appears in RX 
        do_read(32'h0); // And we also need to read the value that we pass (as loopback gives same value back)
// NOTE : loop back gets read on the same UART side cannot be sent to another uart. 
    endtask
endclass 


//------------------------------------------------ PARITY ERR SEQUENCE ------------------------------------------------
class parity_seq extends apb_seq_base;
    `uvm_object_utils(parity_seq)

    function new(string name="parity_seq");
        super.new(name);
    endfunction

    task body();
        req = apb_xtn::type_id::create("req");

        uart_reg_config(.lcr_val(8'b0000_1011)); // Parity enable [odd parity]

        do_write(32'h0, 32'h33);
// NOTE : Parity is checked on another UART, so no need to read here. 
    endtask
endclass 


//------------------------------------------------ BREAK ERR SEQUENCE ------------------------------------------------
class break_req extends apb_seq_base;
    `uvm_object_utils(break_req)

    function new(string name="break_req");
        super.new(name);
    endfunction

    task body();
        req = apb_xtn::type_id::create("req");

        uart_reg_config(.lcr_val(8'b0100_0011)); // Break Enable 

        do_write(32'h0, 32'h00); // THR --> Privide 00 with parity enable to check if UART gives the break error

// NOTE : We don't read anything (check happens in another UART)
    endtask
endclass 


//------------------------------------------------ OVERRUN ERR SEQUENCE ------------------------------------------------
class overrun_seq extends apb_seq_base;
    `uvm_object_utils(overrun_seq)

    function new(string name="overrun_seq");
        super.new(name);
    endfunction

    task body();
        req = apb_xtn::type_id::create("req");

        uart_reg_config();

        repeat(17) // Flooding THR to check the Overrun error. (FIFO) capacity 16
            do_write(32'h0, $urandom_range(0,255));  

    endtask
endclass 



//------------------------------------------------ THR_EMPTY SEQUENCE ------------------------------------------------
class thr_empty_seq extends apb_seq_base;
    `uvm_object_utils(thr_empty_seq)

    function new(string name="thr_empty_seq");
        super.new(name);
    endfunction

    task body();
        req = apb_xtn::type_id::create("req");

        uart_reg_config();

        do_write(32'h0, 8'hAA);

         do_read(32'h08); // Reading IIR 
        // Alternate way => 
        // do_read(32'h14);
        get_response(req); // From Driver getting the response 

        if(req.IIR == 2) begin // Wait till IIR is 2 ==> When another side UART reads everything this will hit. 
            `uvm_info(get_type_name(), "THR EMPTY interrupt received", UVM_MEDIUM) //===? IER to enable hi nahi hoga to how we will get this interrupt 
        end
        //Alternate => 
        // if(req.IIR == 2) begin 
        //     do_read(32'h14);  // Reading LSR when IIR empty, then In SB we can check.(No need to do this way)
        // end
        
    endtask
endclass 


//------------------------------------------------ FRAMING ERR SEQUENCE ------------------------------------------------
class framing_seq extends apb_seq_base;
    `uvm_object_utils(framing_seq)

    function new(string name="framing_seq");
        super.new(name);
    endfunction

    task body();
        req = apb_xtn::type_id::create("req");

        // 2 stop bits (can mismatch with other side)
        uart_reg_config(.lcr_val(8'b0000_0111));

        do_write(32'h0, 8'hF0);
    endtask
endclass 


//------------------------------------------------ TIMEOUT ERR SEQUENCE ------------------------------------------------
class timeout_seq extends apb_seq_base;
    `uvm_object_utils(timeout_seq)

    function new(string name="timeout_seq");
        super.new(name);
    endfunction

    task body();
        req = apb_xtn::type_id::create("req");

        uart_reg_config();

        // Putting data (simulate RX pending)
        do_write(32'h0, 8'h55);

        // Not Reading Intentionally

        // checks interrupt
        do_read(32'h08);
        get_response(req);

        if(req.IIR == 8'hC) begin // Wait till interrupt - No read happens => Time out error
            `uvm_info(get_type_name(), "TIMEOUT interrupt received", UVM_MEDIUM)
        end

    endtask
endclass 
    */