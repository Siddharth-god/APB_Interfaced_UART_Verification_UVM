//-----------------------------------------------------UART TRANSACTION------------------------------------------------------
class uart_xtn extends uvm_sequence_item;
    `uvm_object_utils(uart_xtn)

    function new(string name="uart_xtn");
        super.new(name);
    endfunction 

    rand bit [7:0] tx;
    bit [7:0] rx; 
    bit bad_parity;
    bit parity;
    rand bit stop_bit;

    int bits; 

    bit [7:0] LCR; // Line control register
                                                                      
    // Print method 
    virtual function void do_print(uvm_printer printer);
        printer.print_field("tx",      tx,      8,  UVM_DEC);
        printer.print_field("rx",      rx,      8,  UVM_DEC);
    endfunction

    function void post_randomize(); 
        bits = LCR[1:0] + 5; // data bits from LCR. if lcr = 00 => 0+5 = 5 bits. if lcr = 01 => 1+5 = 6. like that.

        if(bad_parity == 0) begin// If bad parity is 0 
            // Generate correct parity
            if(LCR[3]) begin 
                parity = 0; // First parity will be 0
                for(int i=0; i<bits; i++) begin
                    parity ^= tx[i]; // Generate parity bit from tx
                end
            end
        end
        else begin 
            parity = ~parity; // Generate bad parity for error injection 
        end
    endfunction : post_randomize
endclass 