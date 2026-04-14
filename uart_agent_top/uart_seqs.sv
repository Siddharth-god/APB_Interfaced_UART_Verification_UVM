//xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx UART SEQS xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

class uart_seq_base extends uvm_sequence #(uart_xtn);
    `uvm_object_utils(uart_seq_base)

    function new(string name = "uart_seq_base");
        super.new(name); 
    endfunction 

    bit [7:0] LCR; // Getting from test (for better control over LCR and avoid repetition)

    task body();
        if(!uvm_config_db #(bit [7:0])::get(null,get_full_name(),"lcr",LCR))
            `uvm_fatal(get_type_name(),"Cannot get LCR in uart base sequence from TEST")
    endtask
endclass 

//---------------------------------------------- Uart Half Duplex -------------------------------------------------
class uart_half_duplex extends uart_seq_base;
    `uvm_object_utils(uart_half_duplex)

    function new(string name = "uart_half_duplex");
        super.new(name); 
    endfunction 

    task body(); 
        super.body();

        req = uart_xtn::type_id::create("req");
        req.LCR = LCR; // Assigning the LCR value to uart xtn LCR. why ?? To get it in the trans class and can be used eveywhere 
        start_item(req);
        assert(req.randomize() with {stop_bit == 1;}); // Stop bit can be 0 or 1 (as 0 => 1 stop bit in frame & 1 => 1.5,2 stop bits in frame, while start will be 0 always, and data to driver me randomize hoga)
        finish_item(req); 
    endtask : body
endclass 

//---------------------------------------------- Uart Full Duplex -------------------------------------------------
class uart_full_duplex extends uart_seq_base;
    `uvm_object_utils(uart_full_duplex)

    function new(string name = "uart_full_duplex");
        super.new(name); 
    endfunction 

    task body(); 
        super.body();

        req = uart_xtn::type_id::create("req");
        req.LCR = LCR; 
        start_item(req);
        assert(req.randomize() with {stop_bit == 1;}); // Stop bit can be 0 or 1 (as 0 => 1 stop bit in frame & 1 => 1.5,2 stop bits in frame, while start will be 0 always, and data to driver me randomize hoga)
        finish_item(req); 
    endtask : body
endclass 


//---------------------------------------------- Uart Overrun -------------------------------------------------
class uart_overrun_seq extends uart_seq_base;
    `uvm_object_utils(uart_overrun_seq)

    function new(string name = "uart_overrun_seq");
        super.new(name); 
    endfunction 

    static int drive_count = 0;

    task body(); 
        super.body();
        req = uart_xtn::type_id::create("req");
        req.LCR = LCR; 
        repeat(18) begin 
            //$display("Value of LCR in uart Overrun :::::::::::::::::::::::::::::::::::::: %0d",LCR);
            start_item(req); 
            assert(req.randomize() with {stop_bit == 0;}); // Stop bit can be 0 or 1 (as 0 => 1 stop bit in frame & 1 => 1.5,2 stop bits in frame, while start will be 0 always, and data to driver me randomize hoga)
            drive_count ++;
            $display("Drive count in uart overrun sequence :::::::::::::::::::::::::::::::::::::: %0d",drive_count);
            finish_item(req); 
        end
    endtask : body
endclass 


//---------------------------------------------- Uart Framing -------------------------------------------------
class uart_framing_seq extends uart_seq_base;
    `uvm_object_utils(uart_framing_seq)

    function new(string name = "uart_framing_seq");
        super.new(name); 
    endfunction 

    task body(); 
        super.body();
        req = uart_xtn::type_id::create("req");
        req.LCR = LCR; 
        repeat(4) begin 
            start_item(req); 
            assert(req.randomize() with {stop_bit == 0;}); 
            finish_item(req); 
        end
    endtask : body
endclass 
