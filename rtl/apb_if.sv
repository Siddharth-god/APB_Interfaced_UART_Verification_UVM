//xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx INTERFACE xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

//-----------------------------------------------------APB INTERFACE-------------------------------------------------------
interface apb_if(input bit PCLK);
    
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
                                                                                             
                                                                                             
    clocking apb_drv_cb@(posedge PCLK);

        output PRESETn;
        output PADDR;
        output PWDATA;
        output PENABLE;
        output PSEL;
        output PWRITE;
        // Signals are input so that driver can put the response back to the sequence
        input  PREADY;
        input  IRQ;
        input  PRDATA;
    endclocking 

    clocking apb_mon_cb@(posedge PCLK);
        
        input PRESETn;
        input PADDR;
        input PWDATA;
        input PENABLE;
        input PSEL;
        input PWRITE;
        input PSLVERR;
        input PREADY;
        input PRDATA;
        input IRQ;
    endclocking 
                                                                                             
                                                                                             
    modport APB_DRV_MD(clocking apb_drv_cb);
    modport APB_MON_MD(clocking apb_mon_cb);                                     
                                             
endinterface 