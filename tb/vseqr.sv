// Virtual seqr --------------------------------------------------------------------------

class vseqr extends uvm_sequencer #(uvm_sequence_item);
    `uvm_component_utils(vseqr)

    function new(string name="",uvm_component parent);
        super.new(name, parent);
    endfunction

endclass 