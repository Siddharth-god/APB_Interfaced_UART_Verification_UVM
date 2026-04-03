//-----------------------------------------------------UART INTERFACE-------------------------------------------------------
interface uart_if(input bit clk);

	logic Presetn;
	logic [31:0] Paddr;
	bit Psel;
	bit Pwrite;
	bit Penable;
	logic [31:0] Pwdata;
	logic [31:0] Prdata;
	logic Pready;
	logic Pslverr;
	bit IRQ;
	logic tx;
	logic rx;
	logic baud_o;
	
	clocking drv_cb @(posedge clk);
		default input #1 output #1;  // what about txd and rxd?
		output Presetn;
		output Paddr;
		output Psel;
		output Pwrite;
		output Penable;
		output Pwdata;
	    output tx;
		
		input Pready;
		input Pslverr;
		input Prdata;
		input IRQ;
		input baud_o;
        input rx;
	endclocking

	clocking mon_cb @(posedge clk);
		default input #1 output #1;
		input Presetn;
		input Paddr;
		input Psel;
		input Pwrite;
		input Penable;
		input Pwdata;
		input Pready;
		input Pslverr;
		input Prdata;
		input tx;
        input rx;
		input baud_o;
		input IRQ;
	endclocking

	modport DRV_MP(clocking drv_cb);
	modport MON_MP(clocking mon_cb);

endinterface