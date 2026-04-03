//xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx TRANSACTIONS xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

//-----------------------------------------------------APB TRANSACTION-------------------------------------------------------
class apb_xtn extends uvm_sequence_item;
    `uvm_object_utils(apb_xtn)

    function new(string name="apb_xtn");
        super.new(name);
    endfunction 

    bit PRESETn;
    bit PCLK;
    rand bit [31:0] PADDR;
    bit [31:0] PRDATA;
    rand bit [31:0] PWDATA;
    bit PENABLE;
    bit PREADY; // Input to APB from the slave 
    bit PSEL;
    rand bit PWRITE;
    bit PSLVERR; // Input to APB from slave 
    bit IRQ; // from slave 

    // Registers 
    bit [7:0] THR [$];                                          
    bit [7:0] RBR [$];                                          
    bit [15:0] DIV;                                          
    bit [7:0] LCR;                                          
    bit [7:0] IER;                                          
    bit [7:0] LSR; 
    bit [7:0] IIR; // Default val of IIR is 0, Not C1. So,it cannot be MODEM CONTROL REG                                       
    bit [7:0] FCR;                                          
    bit [7:0] MSR;
    bit [7:0] MCR;    
    
    // signals 
    bit dl_access; // divisor latch access 
    bit data_in_thr; // for this we should use IIR right ???
    bit data_in_rbr;

                   
    // Print method 

    virtual function void do_print(uvm_printer printer);
        printer.print_field("PCLK",    PCLK,    1,   UVM_DEC);
        printer.print_field("PRESETn", PRESETn, 1,   UVM_DEC);
        printer.print_field("PADDR",   PADDR,   32,  UVM_DEC);
        printer.print_field("PRDATA",  PRDATA,  32,  UVM_DEC);
        printer.print_field("PWDATA",  PWDATA,  32,  UVM_DEC);
        printer.print_field("PENABLE", PENABLE, 1,   UVM_DEC);
        printer.print_field("PREADY",  PREADY,  1,   UVM_DEC);
        printer.print_field("PSEL",    PSEL,    1,   UVM_DEC);
        printer.print_field("PWRITE",  PWRITE,  1,   UVM_DEC);
        printer.print_field("PSLVERR", PSLVERR, 1,   UVM_DEC);
    endfunction 


endclass 
