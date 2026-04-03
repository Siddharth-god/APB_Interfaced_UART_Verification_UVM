//xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx SCOREBOARD xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
//-----------------------------------------------------SB-------------------------------------------------------

class sb extends uvm_scoreboard; 
    `uvm_component_utils(sb)

    function new(string name="",uvm_component parent);
        super.new(name,parent);
    endfunction 

    
endclass 