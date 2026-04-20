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

    //static int drive_count = 0;
    int drive_count = 0; // removed static for drive_count. 

    task body(); 
        $display("----------------------------- Uart Overrun Sequence -----------------------------");
        super.body();
        req = uart_xtn::type_id::create("req"); // ==> You create req once outside the loop and randomize it in each iteration — this is fine in UVM only if the driver doesn't hold a reference to be safe we keep it inside repeat to get fresh object everytime
        req.LCR = LCR; 

        // repeat(18) begin ---> Didn't caused any issue though
        repeat(17) begin // APB drives 17 writes to the THR. UART should respond to however many bytes APB sends. If APB sends 17, the UART side should also expect/drive 17 frames unless you intentionally have the extra one for a reason — document it clearly.
            
            
        // req = uart_xtn::type_id::create("req"); // can be used here also to get fresh object every repeat(does not causes any issue) 
        // req.LCR = LCR; 

            start_item(req); 
            assert(req.randomize() with {stop_bit == 1;}); // Stop bit was 1 ==> Lcr value passed was 3. changed => stop bit to 0.
            drive_count ++;
            $display("Drive count in uart overrun sequence =====================>  %0d",drive_count);
            $display("Data driven to the UART CORE = %0d",req.tx);
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
            start_item(req); 
            assert(req.randomize() with {
                stop_bit == 0;
                // tx is random — just the stop bit is wrong
            }); 
            finish_item(req); 
    endtask : body
endclass 


//---------------------------------------------- Uart Parity -------------------------------------------------
class uart_parity_seq extends uart_seq_base;
    `uvm_object_utils(uart_parity_seq)  // Not yet working properly 

    function new(string name = "uart_parity_seq");
        super.new(name); 
    endfunction 

    task body(); 
        super.body();
        req = uart_xtn::type_id::create("req");
        req.LCR = LCR; 
            start_item(req); 
            assert(req.randomize() with {
                stop_bit == 1; // stop bit value should be 1. valid frame/
                bad_parity == 1;
            }); 
            finish_item(req); 
    endtask : body
endclass 


//---------------------------------------------- Uart Break -------------------------------------------------
class uart_break_seq extends uart_seq_base;
    `uvm_object_utils(uart_break_seq)

    function new(string name = "uart_break_seq");
        super.new(name); 
    endfunction 

    task body(); 
        super.body();
        req = uart_xtn::type_id::create("req");
        req.LCR = LCR; 
            start_item(req); 
            assert(req.randomize() with {
                stop_bit == 0; // send_data(xtnh.stop_bit); ==> Sends the actual bit VALUE on the line - it's not 1 stop bit it's stop bit with actual values as 0
                tx == 0; // make data = 0 (break)
            }); 
            finish_item(req); 
    endtask : body
endclass 


//---------------------------------------------- Uart Time-out -------------------------------------------------
class uart_timeout_seq extends uart_seq_base;
    `uvm_object_utils(uart_timeout_seq)

    function new(string name = "uart_timeout_seq");
        super.new(name); 
    endfunction 

    task body(); 
        super.body();
        req = uart_xtn::type_id::create("req");
        req.LCR = LCR; 
        repeat(3) begin // Uart expects 4 frames but we send only 3 uart keeps waiting then gives timeout error. 
            start_item(req); 
            assert(req.randomize() with {
                stop_bit == 1; 
            }); 
            finish_item(req); 
        end
    endtask : body
endclass 