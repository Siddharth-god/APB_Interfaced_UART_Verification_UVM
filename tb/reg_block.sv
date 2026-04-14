class uart_reg_block extends uvm_reg_block;  //===> RAL models what bus sees, not what RTL stores internally
    // Register handles 
    rand uart_lcr_reg lcr; 
    rand uart_ier_reg ier; 
    rand uart_fcr_reg fcr; 
    rand uart_mcr_reg mcr; 
    rand uart_lsr_reg lsr; 
    rand uart_iir_reg iir; 

    `uvm_object_utils(uart_reg_block)

    function new(string name="uart_reg_block"); 
        super.new(name, UVM_NO_COVERAGE);
    endfunction 

    virtual function void build();
        // Create registers 
        lcr = uart_lcr_reg::type_id::create("lcr");
        ier = uart_ier_reg::type_id::create("ier");
        fcr = uart_fcr_reg::type_id::create("fcr");
        mcr = uart_mcr_reg::type_id::create("mcr");
        lsr = uart_lsr_reg::type_id::create("lsr");
        iir = uart_iir_reg::type_id::create("iir");


        // Build registers (each register class must implement build)
        lcr.build();
        ier.build();
        fcr.build();
        mcr.build();
        lsr.build();
        iir.build();

        // Configure registers
        lcr.configure(this);     // parent(this = reg_block)
                      //null,     // hdl_path(path given in slice so "null")
                      //"");      // uses name from "create()"
        ier.configure(this);
        fcr.configure(this);
        mcr.configure(this);
        lsr.configure(this);
        iir.configure(this);


        // Create default address map ==> Will be only one 
        default_map = create_map("default_map",0,4,UVM_LITTLE_ENDIAN);
        
        // Add registers to map with proper offsets
        // In add reg we provide address ==> 'h2 = address seen by the bus (do not provide bit position) (APB/AHB/etc.)
        default_map.add_reg(lcr, 'h0c, "RW"); // add_reg → bus address ex = 'h3 (from decode/spec)
        default_map.add_reg(ier, 'h04, "RW");
        default_map.add_reg(fcr, 'h08, "WO"); // fcr is write only, and making it RW - That would hide bugs, not detect them.
        default_map.add_reg(mcr, 'h10, "RW"); 
        default_map.add_reg(lsr, 'h14, "RO");
        default_map.add_reg(iir, 'h08, "RO");


        // HDL path slices (we do this for every register)
        lcr.add_hdl_path_slice("LCR", // Name    //------------> If in RTL 
                                0,    // Offset  //------------> Where it starts (bit position)
                                8);   // Size 
        ier.add_hdl_path_slice("IER",0,8);
        fcr.add_hdl_path_slice("FCR",0,8); //add_hdl_path_slice → bit position inside RTL signal - [7:0] start from 0 and 8 bits
        mcr.add_hdl_path_slice("MCR",0,8);
        lsr.add_hdl_path_slice("LSR",0,8);
        iir.add_hdl_path_slice("IIR",0,4);

        // Set backdoor path to DUT (Set only once then every reg path is set in slice path)
        add_hdl_path("top.DUT.control","RTL"); // control is NOT a keyword. It is simply a module instance name for register file in DUT. 
        // LCR passed without control (because it is an port which goes to tx rx but other registers are inside register file so we need control for them in the path so path can be found)

    endfunction 
endclass 

/*
# ============================================================
# HOW TO FIND HDL PATH SLICE (UART / UVM RAL)
# ============================================================

# RULE 1: NEVER GUESS BIT POSITION
# --------------------------------
# Always check RTL (not address map)

# ============================================================
# CASE 1: SIMPLE REGISTERS (MOST UART DESIGNS)
# ============================================================

# RTL:
reg [7:0] LCR;
reg [7:0] IER;
reg [7:0] FCR;

# MEANING:
# - Each register = separate signal
# - Bit range = [7:0]

# SLICE:
add_hdl_path_slice("LCR", 0, 8);

# ✔ offset = 0
# ✔ size   = 8


# ============================================================
# CASE 2: PACKED REGISTER BANK
# ============================================================

# RTL:
reg [31:0] uart_regs;

# INTERNAL MAPPING:
# [7:0]   → IER
# [15:8]  → FCR
# [23:16] → LCR

# SLICE:
ier → add_hdl_path_slice("uart_regs", 0, 8);
fcr → add_hdl_path_slice("uart_regs", 8, 8);
lcr → add_hdl_path_slice("uart_regs", 16, 8);

# ============================================================
# GOLDEN RULE
# ============================================================

# Bit position comes from RTL storage
# NOT from address map


# ============================================================
# IMPORTANT: OFFSET vs SIZE
# ============================================================

# add_hdl_path_slice(name, OFFSET, SIZE)

# OFFSET = starting bit position
# SIZE   = number of bits

# ============================================================
# COMMON CONFUSION
# ============================================================

# RTL: [7:0]

# ❌ WRONG:
(0, 7)

# ✅ CORRECT:
(0, 8)

# WHY?
# [7:0] = 8 bits (7 - 0 + 1)

# ============================================================
# QUICK REFERENCE TABLE
# ============================================================

# RTL RANGE     → SLICE
# [7:0]         → (0, 8)
# [15:8]        → (8, 8)
# [3:0]         → (0, 4)
# [31:16]       → (16, 16)

# ============================================================
# FINAL MEMORY LINE
# ============================================================

# "Offset = where it starts"
# "Size   = how many bits"
# "Slice uses COUNT, not MSB"
# ============================================================
*/