//-----------------------------------------------------UART INTERFACE-------------------------------------------------------
interface uart_if(input bit clk);

	logic PRESETn;
    logic [31:0] PADDR;
    logic [31:0] PRDATA;
    logic [31:0] PWDATA;
    logic PENABLE;
    logic PREADY;
    logic PSEL;
    logic PWRITE;
    logic PSLVERR;  
    logic IRQ; //! IRQ is the input to the CPU/APB so it must be present in APB interface                           
                                                                                                  
	logic tx;
	logic rx;
	logic baud_o;
	
	clocking uart_drv_cb @(posedge clk);
		default input #1 output #1;  // what about txd and rxd?
		output PRESETn;
		output PADDR;
		output PSEL;
		output PWRITE;
		output PENABLE;
		output PWDATA;
	    output tx;
		
		output PREADY;
		output PSLVERR;
		output PRDATA;
		input IRQ;
		input baud_o;
        input rx;

		
		
	endclocking

	clocking uart_mon_cb @(posedge clk);
		default input #1 output #1;
		input PRESETn;
		input PADDR;
		input PSEL;
		input PWRITE;
		input PENABLE;
		input PWDATA;
		input PREADY;
		input PSLVERR;
		input PRDATA;
		input tx;
        input rx;
		input baud_o;
		input IRQ;
	endclocking

	modport DRV_MP(clocking uart_drv_cb);
	modport MON_MP(clocking uart_mon_cb);

endinterface