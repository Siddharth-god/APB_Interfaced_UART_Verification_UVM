//-----------------------------------------------------UART SEQR------------------------------------------------------

class uart_seqr extends uvm_sequencer #(uart_xtn);
    `uvm_component_utils(uart_seqr)

    function new(string name="",uvm_component parent);
        super.new(name,parent);
    endfunction 

endclass 