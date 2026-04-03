// Virtual seq --------------------------------------------------------------------------

class vseq extends uvm_sequence #(uvm_sequence_item);
    `uvm_object_utils(vseq)

    function new(string name="vseq");
        super.new(name);
    endfunction

endclass 