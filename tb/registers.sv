//xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx LCR xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
class uart_lcr_reg extends uvm_reg; 
    `uvm_object_utils(uart_lcr_reg)

    function new(string name = "");
        super.new(name, 8, UVM_NO_COVERAGE); // 8 bit reg - no coverage for now
    endfunction 

    rand uvm_reg_field data_len; 
    rand uvm_reg_field stop_bits; 
    rand uvm_reg_field parity_enb; 
    rand uvm_reg_field even_odd_parity; 
    rand uvm_reg_field stick_parity; 
    rand uvm_reg_field break_bit; 
    uvm_reg_field reserved;

/*
if [7:0] king     
split => 01 = item size // for item size lsb position is 0 
        2345 = type     // for type lsb position is 2 
        67   = depth    // for depth lsb position is 6 
//==> As out register is sliced for different fields so each field will have different lsb position where it will start from 
*/
    // Build function 
    virtual function void build();
        data_len = uvm_reg_field::type_id::create("data_len"); 
        data_len.configure(this,
                            2,  // no of bits
                            0,  // lsb position 
                            "RW", //accessibility
                            0,    //volatile
                            2'h3,  //reset value
                            1,      //has reset
                            0,      // is random
                            1      //individually accessible
                        );
        
    stop_bits = uvm_reg_field::type_id::create("stop_bits");
    stop_bits.configure(this, 1, 2, "RW", 0, 0, 1, 0, 1);  

    parity_enb = uvm_reg_field::type_id::create("parity_enb",,get_full_name());
    parity_enb.configure(this, 1, 3, "RW", 0, 0, 1, 0, 1);

    even_odd_parity = uvm_reg_field::type_id::create("even_odd_parity",,get_full_name());
    even_odd_parity.configure(this, 1, 4, "RW", 0, 0, 1, 0, 1);

    stick_parity = uvm_reg_field::type_id::create("stick_parity",,get_full_name());
    stick_parity.configure(this, 1, 5, "RW", 0, 0, 1, 0, 1);

    break_bit = uvm_reg_field::type_id::create("break_bit",,get_full_name());
    break_bit.configure(this, 1, 6, "RW", 0, 0, 1, 0, 1);

    reserved = uvm_reg_field::type_id::create("reserved",,get_full_name());
    reserved.configure(this, 1, 7, "RW", 0, 0, 1, 0, 0);

    endfunction 
endclass 


//xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx IER xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

class uart_ier_reg extends uvm_reg;  // In design ier size is 4 bit but actual size of ier is 8 bit so in design they removed reserved bits but we should use them as make them reserved it's best prac and reduces ambiguity. 
    `uvm_object_utils(uart_ier_reg)

    function new(string name = "");
        super.new(name, 8, UVM_NO_COVERAGE); 
    endfunction 

    rand uvm_reg_field erxi; // Enable rx interrupt
    rand uvm_reg_field ethri; // Enable thr empty interrupt 
    rand uvm_reg_field elsi; // Enable line status interrupt 
    rand uvm_reg_field emsi; // modem status interrupt enable 
    uvm_reg_field reserved;

// Reset value decide => 8'h0000_0000
    // Build function 
    virtual function void build();
        erxi = uvm_reg_field::type_id::create("erxi"); 
        erxi.configure(this,
                            1,  // no of bits
                            0,  // lsb position 
                            "RW", //accessibility
                            1'b0,    //volatile  => if 1 - hardware updates auto | 0 - software control stable 
                            0,  //reset value
                            1,      //has reset
                            0,      // is random => depends 
                            1      //individually accessible => mostly 1 for non reserved
                        );
            
        ethri = uvm_reg_field::type_id::create("ethri");
        ethri.configure(this, 1, 1, "RW", 0, 1'b0, 1, 0, 1);  

        elsi = uvm_reg_field::type_id::create("elsi",,get_full_name());
        elsi.configure(this, 1, 2, "RW", 0, 1'b0, 1, 0, 1);

        emsi = uvm_reg_field::type_id::create("emsi",,get_full_name());
        emsi.configure(this, 1, 3, "RW", 0, 1'b0, 1, 0, 1);

        reserved = uvm_reg_field::type_id::create("reserved",,get_full_name());
        reserved.configure(this, 4, 4, "RW", 4'b0000, 0, 1, 0, 0); // => individually_accessible = 0; / is_rand = 0 / volatile = 0 always
        // You should NOT access reserved bits directly ==> No read/write via field API
    endfunction 
endclass 


//xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx FCR xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

// Reset value is decide like this : 
// If reset val = 0xc0 ==> 8'b1100_0000
//==> 7:6(2'b11) , 5:3(3'b000) , 2(1'b0) , 1(1'b0) , 0(1'b0)
// Splitting happens based on specifications (like how many bits and where they start)
// Splits like this easy from ==> [msb to lsb] 

class uart_fcr_reg extends uvm_reg;  // FCR is not a register. It is a command - in the form of register (flush tx rx)
    `uvm_object_utils(uart_fcr_reg)

    function new(string name = "");
        super.new(name, 8, UVM_NO_COVERAGE); 
    endfunction 

    rand uvm_reg_field resv1; 
    rand uvm_reg_field rx_flush; 
    rand uvm_reg_field tx_flush; 
    uvm_reg_field resv2;
    rand uvm_reg_field threshold; // modem status interrupt enable 

    // Build function 
    virtual function void build();

        resv1 = uvm_reg_field::type_id::create("resv1",,get_full_name());
        resv1.configure(this, 1, 0, "WO", 0, 0, 1, 0, 0); 

        rx_flush = uvm_reg_field::type_id::create("rx_flush"); 
        rx_flush.configure(this,
                            1,  // no of bits
                            1,  // lsb position 
                            "WO", //accessibility
                            0,    //volatile
                            2'b11,  //reset value
                            1,      //has reset
                            0,      // is random
                            1      //individually accessible
                        ); 

        tx_flush = uvm_reg_field::type_id::create("tx_flush",,get_full_name());
        tx_flush.configure(this, 1, 2, "WO", 0, 0, 1, 0, 1);

        resv2 = uvm_reg_field::type_id::create("resv2",,get_full_name());
        resv2.configure(this, 3, 3, "WO", 0, 0, 1, 0, 0);

        threshold = uvm_reg_field::type_id::create("threshold",,get_full_name());
        threshold.configure(this, 2, 6, "WO", 0, 0, 1, 0, 1);
    endfunction 
endclass 


//xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx MCR xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

class uart_mcr_reg extends uvm_reg; 
    `uvm_object_utils(uart_mcr_reg)

    function new(string name = "");
        super.new(name, 8, UVM_NO_COVERAGE); 
    endfunction 

    rand uvm_reg_field resv1; 
    rand uvm_reg_field loopback; 
    uvm_reg_field resv2;

    // Build function 
    virtual function void build();

        resv1 = uvm_reg_field::type_id::create("resv1",,get_full_name());
        resv1.configure(this, 3, 0, "RW", 0, 0, 1, 0, 0); 

        loopback = uvm_reg_field::type_id::create("loopback"); 
        loopback.configure(this,
                            1,  // no of bits
                            4,  // lsb position 
                            "RW", //accessibility
                            0,    //volatile
                            1'b0,  //reset value
                            1,      //has reset
                            0,      // is random
                            1      //individually accessible
                        ); 

        resv2 = uvm_reg_field::type_id::create("resv2",,get_full_name());
        resv2.configure(this, 3, 5, "RW", 0, 0, 1, 0, 0);
    endfunction 
endclass 


//xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx LSR xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

class uart_lsr_reg extends uvm_reg;  // rst = 0110_0000
    `uvm_object_utils(uart_lsr_reg)

    function new(string name = "");
        super.new(name, 8, UVM_NO_COVERAGE); 
    endfunction 

    rand uvm_reg_field Dready; 
    rand uvm_reg_field Overrun; 
    rand uvm_reg_field Parity; 
    rand uvm_reg_field Framing; 
    rand uvm_reg_field Break; 
    rand uvm_reg_field Tx_fifo_e; // Only for tx fifo
    rand uvm_reg_field Tx_empty; // both tx shift reg & tx fifo are empty 
    rand uvm_reg_field fifo_err; 

    // Build function 
    virtual function void build(); // LSR is status register, so: volatile = 1

        Dready = uvm_reg_field::type_id::create("Dready",,get_full_name());
        Dready.configure(this, 1, 0, "RO", 1, 0, 1, 0, 1); 

        Overrun = uvm_reg_field::type_id::create("Overrun"); 
        Overrun.configure(this,
                            1,  // no of bits
                            1,  // lsb position 
                            "RO", //accessibility
                            1,    //volatile
                            0,  //reset value
                            1,      //has reset
                            0,      // is random
                            1      //individually accessible
                        ); 

        Parity = uvm_reg_field::type_id::create("Parity",,get_full_name());
        Parity.configure(this, 1, 2, "RO", 1, 0, 1, 0, 1);

        Framing = uvm_reg_field::type_id::create("Framing",,get_full_name());
        Framing.configure(this, 1, 3, "RO", 1, 0, 1, 0, 1);

        Break = uvm_reg_field::type_id::create("Break",,get_full_name());
        Break.configure(this, 1, 4, "RO", 1, 0, 1, 0, 1);

        Tx_fifo_e = uvm_reg_field::type_id::create("Tx_fifo_e",,get_full_name());
        Tx_fifo_e.configure(this, 1, 5, "RO", 1, 1'b1, 1, 0, 1);

        Tx_empty = uvm_reg_field::type_id::create("Tx_empty",,get_full_name());
        Tx_empty.configure(this, 1, 6, "RO", 1, 1'b1, 1, 0, 1);

        fifo_err = uvm_reg_field::type_id::create("fifo_err",,get_full_name());
        fifo_err.configure(this, 1, 7, "RO", 1, 0, 1, 0, 1);
    endfunction 
endclass 

//xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx IIR xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

class uart_iir_reg extends uvm_reg; // rst = 1100_0001 (only care about 4 bits from lsb side)
    `uvm_object_utils(uart_iir_reg)

    function new(string name = "");
        super.new(name, 4, UVM_NO_COVERAGE); 
    endfunction 

    rand uvm_reg_field int_id; 
    rand uvm_reg_field pending; 

    // Build function 
    virtual function void build(); 

        pending = uvm_reg_field::type_id::create("pending");
        pending.configure(this, 1, 0, "RO", 1, 1'b1, 1, 0, 0); // pending will be 1 as reset (1 = no interrupt pending)

        int_id = uvm_reg_field::type_id::create("int_id"); 
        int_id.configure(this,
                            3,  // no of bits
                            1,  // lsb position 
                            "RO", //accessibility
                            1,    //volatile      ==> IIR is a status register, not a storage register so volatile
                            3'b000,  //reset value
                            1,      //has reset
                            0,      // is random
                            1      //individually accessible
                        ); 
    endfunction 
endclass 

/*
class uart_iir_reg extends uvm_reg;
        `uvm_object_utils(uart_iir_reg)

         rand uvm_reg_field iir;

        function new(string name = "uart_iir_reg");
                super.new(name,8, UVM_NO_COVERAGE);
        endfunction

          virtual function void build();
                iir = uvm_reg_field::type_id::create("iir");
                iir.configure(this,
                                        8,  // no of bits 3
                                        0,  // lsb position 3
                                        "RW", //accessibility
                                        0,    //volatile
                                        0,  //reset value
                                        1,      //has reset
                                        0,      // is random
                                        1      //individually accessible
                                );
          endfunction
endclass

*/