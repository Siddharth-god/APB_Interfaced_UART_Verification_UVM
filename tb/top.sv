
//xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx TOP xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

//-----------------------------------------------------TOP-------------------------------------------------------
module top;
    
    import test_pkg::*;
    import uvm_pkg::*;

    bit clk1 = 0;
    bit clk2 = 0;
    bit PRESETn = 0; 
    // CLK 1 ==> 100 MHz freq --> 10ns TIme Period 
    always #5 clk1 = ~clk1; 

    // CLK 2 ==> 50 MHz freq --> 20ns TIme Period 
    always #10 clk2 = ~clk2; 

    // Initialization of RESET and CLK
    initial begin 
        clk1 = 0;
        clk2 = 0; 
        PRESETn = 0;
        #100; 
        PRESETn = 1;
    end

    // Instantiate interfaces 
    apb_if APB_IF(clk1); // APB interface for DUT
    uart_if UART_IF(clk2);  // UART interface for VIP 

    // UART VIP Baud rate generator
    /*
    In DUT, baud rate is generated internally using the divisor register, but in the UART agent, 
    since it is a verification model without baud generation logic, 
    we generate the baud tick externally in the testbench to maintain correct timing for driving and sampling.
    */
    localparam int clk_freq  = 50000000;  // 50 MHz 
    localparam int BAUD_RATE = 115200;    // Target Baud rate 
    localparam int SAMPLE    = 16;        // Oversampling factor 

    // Baud rate divisor 
    localparam int DIVISOR = clk_freq / (BAUD_RATE * SAMPLE);

    int baud_cnt; // Count used for checking if baud tick happened (after 16 pulses of baud)

    // Generating Baud tick for UART VIP  ==> We did not write any logic for Baud tick in Sequence ?? 
    always_ff@(posedge clk2 or negedge PRESETn)
        begin 
            if(!PRESETn) begin 
                baud_cnt       <= 0; 
                UART_IF.baud_o <= 0;
            end
            else if(baud_cnt == DIVISOR - 1) begin 
                baud_cnt       <= 0;
                UART_IF.baud_o <= 1; 
            end
            else begin 
                baud_cnt++;
                UART_IF.baud_o <= 0; 
            end
        end

    // DUT Instantiation (UART)
    uart_16550 DUT(
        .PCLK    (clk1),
        .PRESETn (APB_IF.PRESETn),
        .PENABLE (APB_IF.PENABLE),
        .PWRITE  (APB_IF.PWRITE),
        .PADDR   (APB_IF.PADDR),
        .PRDATA  (APB_IF.PRDATA),
        .PWDATA  (APB_IF.PWDATA),
        .PSEL    (APB_IF.PSEL),
        .PREADY  (APB_IF.PREADY),
        .PSLVERR (APB_IF.PSLVERR),
        .IRQ     (APB_IF.IRQ),
        .TXD     (UART_IF.rx), // DUT transmit to VIP receive
        .RXD     (UART_IF.tx),  // VIP transmit to DUT receive 
        .baud_o  ()
    );


    initial begin 
        // Set virtual interfaces in UVM virtual db
        uvm_config_db #(virtual uart_if)::set(null, "*", "uart_if", UART_IF);
        uvm_config_db #(virtual apb_if)::set(null, "*", "apb_if", APB_IF);
        run_test();
    end
endmodule 


