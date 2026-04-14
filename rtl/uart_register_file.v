/********************************************************************************************
Copyright 2024 - Maven Silicon Softech Pvt Ltd.  
www.maven-silicon.com

All Rights Reserved.

This source code is an unpublished work belongs to Maven Silicon Softech Pvt Ltd.
It is not to be shared with or used by any third parties who have not enrolled for our paid 
training courses or received any written authorization from Maven Silicon.

Filename                :       uart_register_file.v   

module Name             :       uart_register_file

Description             :       UART register file interfaced with an APB (Advanced Peripheral Bus). 
	                        It manages control and status registers, handles data transmission 
				and reception, and generates interrupts for various UART events.

Author Name             :       Naveen

Support e-mail          :       For any queries, reach out to us on "techsupport_vm@maven-silicon.com" 

Version                 :       1.0
*********************************************************************************************/
 module uart_register_file (
			   input PCLK,
                           input PRESETn,
                           input PSEL,
                           input PWRITE,
                           input PENABLE,
                           input[4:0] PADDR,
                           input [31:0] PWDATA,
                           output reg[31:0] PRDATA,
                           output reg PREADY,
                           output reg PSLVERR,
                           output reg[7:0] LCR,
                           // Transmitter related signals
                           output reg tx_fifo_we,
                           output tx_enable,
                           input[4:0] tx_fifo_count,
                           input tx_fifo_empty,
                           input tx_fifo_full,
                           input tx_busy,
                           // Receiver related signals
                           input [7:0] rx_data_out,
                           input rx_idle,
                           input rx_overrun,
                           input parity_error,
                           input framing_error,
                           input break_error,
			   input time_out,
                           input[4:0] rx_fifo_count,
                           input rx_fifo_empty,
                           input rx_fifo_full,
                           input push_rx_fifo,
                           output rx_enable,
                           output reg rx_fifo_re,
                           // Modem interface related signals
                           output loopback,
                           output reg irq,
                           output baud_o
                          );

   // Include defines for addresses and offsets
    `define DR 5'h0 // Data register // THR and RBR
   `define IER 5'h1
   `define IIR 5'h2
   `define FCR 5'h2
   `define LCR 5'h3
   `define MCR 5'h4
   `define LSR 5'h5
   `define MSR 5'h6
   `define DIV1 5'h7
   `define DIV2 5'h8

   parameter IDLE=2'b00;
   parameter SETUP=2'b01;
   parameter ACCESS=2'b10;
   
   reg we; //! asserted when we are in access state and it's a write transaction
   reg re; //! asserted when we are in access state and it's a read transaction
   
   // RX FIFO over its threshold:
   reg rx_fifo_over_threshold;
   
   // UART Registers:
   reg[3:0] IER;
   reg[3:0] IIR;
   reg[7:0] FCR;
   reg[4:0] MCR;
   reg[7:0] MSR;
   reg[3:0] LSR;
   reg[15:0] DIVISOR;
   
   // Baudrate counter
   reg[15:0] dlc; //! Divisor Latch Counter - counts down from the value in DIVISOR to generate baud rate enable pulses
   reg enable; //! baud rate enable signal - goes high for one clock cycle when dlc reaches 0, and is used to enable the transmitter and receiver logic
   reg start_dlc; //! asserted when divisor is written - basically a trigger to start dlc decrement
   
   reg tx_int; //! Transmitter interrupt
   reg rx_int; //! Receiver interrupt
   
   reg ls_int; //! Line status interrupt
   
   reg last_tx_fifo_empty; 
   
   // APB Bus interface FSM:
   
   reg[1:0] fsm_state;
   
   always @(posedge PCLK)
     begin : L112_APB_FSM
        if(PRESETn == 1'b0)
            begin
                we <= 1'b0;
                re <= 1'b0;
                PREADY <= 1'b0;
                fsm_state <= IDLE;
            end
       else
            case (fsm_state)
                IDLE: 
                    begin
                        we <= 1'b0;
                        re <= 1'b0;
                        PREADY <= 1'b0;
                        if(PSEL) //! GIven by CPU
                            fsm_state <= SETUP;
                    end
                SETUP: 
                    begin
                        re <= 1'b0;
                        if(PSEL && PENABLE)
                            begin
                            fsm_state <= ACCESS;
                            if(PWRITE)
                                we <= 1'b1;
                            end
                        else
                        begin
                            fsm_state <= IDLE;
                            we<=1'b0;
                        end
                    end
                ACCESS: 
                    begin
                        PREADY <= 1'b1;
                        we <= 1'b0;
                        if(PWRITE == 1'b0)
                            re <= 1'b1;
                        fsm_state <= IDLE;
                    end
                default: fsm_state <= IDLE;
                endcase
     end

   //One clock pulse per enable --> explaination below -> ~pclk used to avoid meta stability
   assign baud_o = ~PCLK && enable; // baud_o is used as the clock input to the transmitter and receiver logic, 
   // Interrupt line
   always @(posedge PCLK) 
     begin: L161_IRQ_GEN
       if(PRESETn == 1'b0) 
	 begin
           irq <= 1'b0;
         end
       else if((re == 1'b1) && (PADDR == `IIR)) 
         begin
	   irq <= 1'b0;
    	 end
       else 
	 begin
      	   irq <= (IER[0] & rx_int) | (IER[1] & tx_int) | (IER[2] & ls_int) | time_out;  // (IER[3] & ms_int)
    	 end
     end

  // Loopback:
  assign loopback = MCR[4];  //! loopback mode enabled when MCR[4] is set

  // The register implementations:

  // TX Data register strobe // Writing to FIFO (Not using THR reg instead generating tx_fifo_we and directly pushing to fifo)
  always @(posedge PCLK)
    begin
      if(PRESETn == 1'b0) 
        begin
          tx_fifo_we <= 1'b0;
        end
      else 
	begin
	  if((we == 1'b1) && (PADDR == `DR)) // we coming from APB fsm and paddr is address of THR
	    begin
              tx_fifo_we <= 1'b1;
      	    end
      	  else 
	    begin
              tx_fifo_we <= 1'b0;
      	    end
    	end
    end

  // DIVISOR - baud rate divider

    
  always @(posedge PCLK)
    begin : LL203_DIVISOR
      if(PRESETn == 1'b0) 
        begin
          DIVISOR <= 1'b0;
      	  start_dlc <= 1'b0;
        end
      else 
        begin
      	  if(we == 1'b1) // we is asserted when we are in access state and it's a write transaction
	          begin
                case(PADDR)
                    `DIV1: 
                          begin
                            DIVISOR[7:0] <= PWDATA[7:0];
                            start_dlc <= 1'b1;
                          end
                    `DIV2: 
                          begin
                            DIVISOR[15:8] <= PWDATA[7:0];
                          end
                endcase
      	    end
      	  else 
            begin
              start_dlc <= 1'b0;
            end
      	end
    end

  // LCR - Line control register
  always @(posedge PCLK)
    begin : L234_LCR
      if(PRESETn == 1'b0) 
        begin
          LCR <= 1'b0;
    	end
      else 
	begin
      	  if((we == 1'b1) && (PADDR == `LCR)) 
	    begin
              LCR <= PWDATA[7:0];
      	    end
    	end
    end

  // MCR - Control register
  always @(posedge PCLK)
    begin: L250_MCR
      if(PRESETn == 1'b0) 
	begin
      	  MCR <= 1'b0;
        end
      else 
	begin
      	  if((we == 1'b1) && (PADDR == `MCR)) 
	    begin
              MCR <= PWDATA[4:0];
      	    end
    	end
    end

  // FCR - FIFO Control Register:
  always @(posedge PCLK)
    begin: L266_FCR
      if(PRESETn == 1'b0) 
	begin
      	  FCR <= 8'hc0;
    	end
      else 
	begin
      	  if((we == 1'b1) && (PADDR == `FCR)) 
	    begin
              FCR <= PWDATA[7:0];
      	    end
    	end
    end

  // IER - Interrupt Masks:
  always @(posedge PCLK)
    begin: L292_IER
      if(PRESETn == 1'b0) 
	begin
      	  IER <= 1'b0;
    	end
      else 
	begin
      	  if((we == 1'b1) && (PADDR == `IER)) 
	    begin
              IER <= PWDATA[3:0];
      	    end
    	end
    end

  // Read back path: Basically PRDATA
  always@(*) 
    begin: L312_READBACK
      PSLVERR = 1'b0;
      case(PADDR)
      	`DR	: PRDATA = {24'h0, rx_data_out}; // Directly taking from FIFO, No RBR used. 
      	`IER	: PRDATA = {28'h0, IER};
      	`IIR	: PRDATA = {28'h0, IIR};
      	`LCR	: PRDATA = {24'h0, LCR};
      	`MCR	: PRDATA = {28'h0, MCR};
      	`LSR	: PRDATA = {24'h0, (parity_error | 
                                    framing_error | 
                                    break_error), // OR --> any one is selected = 1 bit
                                    (tx_fifo_empty & ~tx_busy), // & makes it = 1 bit
                                    tx_fifo_empty,  // 1 bit
                                    LSR, // 4 bits
                                    ~rx_fifo_empty}; // 1 bit ===> Total 8 bits
      	`MSR	: PRDATA = {24'h0, MSR};
      	`DIV1	: PRDATA = {24'h0, DIVISOR[7:0]};
      	`DIV2	: PRDATA = {24'h0, DIVISOR[15:8]};
      	default	: 
	  begin
            PRDATA = 32'h0;
	    PSLVERR = 1'b1;
          end
      endcase
    end
  
  // Read pulse to pop the Rx Data FIFO ==? Generating rx_fifo_re to fetch the data from Rx FIFO (not using RBR)
  always @(posedge PCLK)
    begin: L348_RX_FIFO_RE
      if(PRESETn == 1'b0)
    	rx_fifo_re <= 1'b0;
      else
  	if(rx_fifo_re) // restore the signal to 0 after one clock cycle // why ?? 
          rx_fifo_re <= 1'b0;
  	else
  	  if((re) && (PADDR == `DR ))
    	    rx_fifo_re <= 1'b1; // advance read pointer
    end

  // LSR RX error bits / also included ls_interrupt logic as both have same things but ls_int 1 bit so we use reducing operator
  always @(posedge PCLK)
    begin: L370_LSR
      if(PRESETn == 1'b0) 
        begin
    	  ls_int <= 1'b0;
    	  LSR <= 1'b0;
  	end
      else 
	begin
    	  if((PADDR == `LSR) && (re == 1'b1)) // When cpu reads lsr and read is high
	    begin               // Why clear ? 
      	      LSR <= 1'b0; //! Reading LSR = “CPU has acknowledged errors” -- we clear flags after read
      	      ls_int <= 1'b0;
    	    end
    	  else if(re == 1'b1) 
	    begin
              LSR<={break_error,framing_error,parity_error,rx_overrun}; // Captures/Stores current errors
              ls_int<=|{break_error,framing_error,parity_error,rx_overrun}; // ls_int = 1, if any error presernt then irq can be high  
    	    end
    	  else 
	    begin
      	      ls_int <= |LSR; // If any error bit is 1 → ls_int = 1
	      LSR<=LSR; //“keep previous value” --> not needed but for clearity of no change happens in this cycle
    	    end
  	end
    end

  // Interrupt Identification register
  always @(posedge PCLK)
    begin : L361_IIR
      if(PRESETn == 1'b0) 
	      begin
    	    IIR <= 4'h1; // No interrupt (lowest priority but reset removes all interrupts)
  	    end
      else 
        //$display("Rx interrupt = %0d",rx_int);
        begin
    	    if((ls_int == 2'b1) && (IER[2] == 1'b1)) // IER[2] line status interrupt enable
	          begin
      	      IIR <= 4'h6; // Highest priority (If ls_interrupt is read by cpu -> it gets reseted)
    	      end
    	    else if((rx_int == 1'b1) && (IER[0] == 1'b1)) // IER[0] received data available interrupt enable
	          begin
      	        IIR <= 4'h4;
    	      end
	        else if(time_out == 1'b1)
            begin
	            IIR <= 4'hc;
	          end
    	    else if((tx_int == 1'b1) && (IER[1] == 1'b1)) // IER[1] THR empty interrupt enable 
	          begin
      	      IIR <= 4'h2;
    	      end
    	    else 
	          begin
      	      IIR <= 4'h1; // Lowest priority 
    	      end
        //   $display("IIR in Design  = %0d",IIR);
        //   $display("IER  = %0d",IER[0]);
  	  end
    end
/* IIR --> Priority concept : 
if(ls_int && IER[2])       IIR = 6;
else if(rx_int && IER[0])  IIR = 4;
else if(time_out)          IIR = C;
else if(tx_int && IER[1])  IIR = 2;
else                       IIR = 1;
*/

  // Baud rate generator:
  // Frequency divider
  always @(posedge PCLK)
    begin: L410_BAUD_RATE_GEN
      if(PRESETn == 1'b0)
        dlc <= #1 0;
      else
        if(start_dlc | ~ (|dlc))   // start_dlc is set when divisor is written, and is reset after one clock cycle
          dlc <= DIVISOR - 1;           // preset counter --> If divisor = 5 => then dlc = 5-1 = 4
        else
      	  dlc <= dlc - 1;              // decrement counter if (dlc > 0 ) then decrement and if 0 then ~(|dlc) helps continue baud rate generation
    end 
/*
if DIVISOR is 27 then dlc = 26 and in 27(including 0) PCLK cycles = 1 enable pulse.    
*/

  // Enable signal generation logic
/*
|DIVISOR = 1 → if ANY bit is 1 → DIVISOR ≠ 0
|DIVISOR = 0 → if ALL bits are 0 → DIVISOR = 0
We do NOT care about the exact value (27, 50, etc)
We only check: is DIVISOR zero or non-zero
If DIVISOR = 0 → invalid (no counting / divide-by-zero case)
→ disable enable signal

dlc = down counter
→ counts PCLK cycles
→ when it reaches 0 → generates one enable pulse
*/
  always @(posedge PCLK)
    begin
      if(PRESETn == 1'b0)
    	enable <= 1'b0;
      else
    	if(|DIVISOR & ~(|dlc))     // DIVISOR >0 & dlc==0 (when dlc == 0 ==> 1 enable pulse)
      	  enable <= 1'b1; // enable pulse = baud tick (baud pulse) 1 enable = 1 bit of data sample in register ==> Oversampling will be done in Tx & Rx when we use bit_counter. so when enable is one we increment bit counter once, so when bit counter = 16 | enable also 16 ==> So, in RX & TX 16 enable / baud pulses = 1 bit of data sample. 
   	else
      	  enable <= 1'b0;
    end

  assign tx_enable = enable;

  assign rx_enable = enable;

  // Interrupts
  // TX Interrupt - Triggered when TX FIFO contents below threshold
  //                Cleared by a write to the interrupt clear bit
  always @(posedge PCLK) 
    begin
      if(PRESETn == 1'b0) 
	begin
      	  tx_int <= 1'b0;
      	  last_tx_fifo_empty <= 1'b0;
        end
      else 
	begin
      	  last_tx_fifo_empty <= tx_fifo_empty;
      	  if((re == 1) && (PADDR == `IIR) && (PRDATA[3:0] == 4'h2)) // Tx fifo empty in IIR = 4'h2 (3rd priority)
	    begin
              tx_int <= 1'b0;
      	    end
      	  else 
	    begin
              tx_int <= (tx_fifo_empty & ~last_tx_fifo_empty) | tx_int; // tx fifo currently empty and previously not empty then tx_fifo empty interrupt
      	    end
        end
    end

  // RX Interrupt - Triggered when RX FIFO contents above threshold
  //                Cleared by a write to the interrupt clear bit
  always @(posedge PCLK)
    begin
      if(PRESETn == 1'b0) 
	begin
      	  rx_int <= 1'b0;
    	end
      else 
	begin
      	  rx_int <= rx_fifo_over_threshold; // FCR decides the threshold value using last 2 bits. 
    	end
    end

  // RX FIFO over its threshold
  always@(*)
    case(FCR[7:6]) // FCR[7:6] will decide the threshold value and whatever the value is will give the intrrupt 
      2'h0	: rx_fifo_over_threshold = (rx_fifo_count >= 1);
      2'h1	: rx_fifo_over_threshold = (rx_fifo_count >= 4);
      2'h2	: rx_fifo_over_threshold = (rx_fifo_count >= 8);
      2'h3	: rx_fifo_over_threshold = (rx_fifo_count >= 14);
      default	: rx_fifo_over_threshold = 0;
    endcase

 endmodule


 //baud_o is generated by gating the PCLK with the enable signal. 
// what happens if we dont use PCLK here and directly use enable as the clock for transmitter and receiver logic? 
  // Answer: If we directly use the 'enable' signal as the clock for the transmitter and receiver logic without gating it with PCLK,
  // it could lead to timing and synchronization issues. The 'enable' signal is generated based on the baud rate counter
  // and may not be synchronized with the main clock (PCLK). This could cause metastability problems in the transmitter and receiver logic, 
  //as they would be triggered by an asynchronous signal. By gating 'enable' with PCLK, we ensure that the transmitter and receiver logic 
  //are only triggered on the edges of PCLK, maintaining proper synchronization and avoiding potential timing issues.
// what happens if we use PCLK instead of ~PCLK here?
  // Answer: If we use PCLK instead of ~PCLK, the baud_o signal would be active low instead of active high. This means that the transmitter and receiver logic would be enabled on the falling edge of PCLK instead of the rising edge. This could lead to timing issues and incorrect operation of the UART, as the logic would be triggered at the wrong time. By using ~PCLK, we ensure that the transmitter and receiver logic are enabled on the rising edge of PCLK, which is the standard practice for synchronous logic design.
// when we use PCLK && enable then baud will be high during pclk is high and enable is high, so the baud will be active high isnt it?
  // Answer: Yes, if we use PCLK && enable, the baud_o signal would be active high when both PCLK and enable are high. However, in the original code, baud_o is defined as ~PCLK && enable, which means it will be active high when PCLK is low and enable is high. This is likely done to ensure that the baud_o signal is active during the low phase of PCLK, which may be required for the timing of the transmitter and receiver logic. The choice between using PCLK && enable or ~PCLK && enable depends on the specific timing requirements of the UART design and how the transmitter and receiver logic is implemented. 