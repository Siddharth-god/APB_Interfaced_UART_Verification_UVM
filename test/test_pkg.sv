package test_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // APB agent files
  `include "../apb_agent_top/apb_xtn.sv"
  `include "../apb_agent_top/apb_agent_config.sv"
  `include "../apb_agent_top/apb_seqs.sv"
  `include "../apb_agent_top/apb_seqr.sv"
  `include "../apb_agent_top/apb_drv.sv"
  `include "../apb_agent_top/apb_mon.sv"
  `include "../apb_agent_top/apb_agent.sv"
  `include "../apb_agent_top/apb_agent_top.sv"

  // UART agent files
  `include "../uart_agent_top/uart_xtn.sv"
  `include "../uart_agent_top/uart_agent_config.sv"
  `include "../uart_agent_top/uart_seqs.sv"
  `include "../uart_agent_top/uart_seqr.sv"
  `include "../uart_agent_top/uart_drv.sv"
  `include "../uart_agent_top/uart_mon.sv"
  `include "../uart_agent_top/uart_agent.sv"
  `include "../uart_agent_top/uart_agent_top.sv"

  // TB files
  `include "../tb/env_config.sv"
  `include "../tb/vseq.sv"
  `include "../tb/vseqr.sv"
  `include "../tb/sb.sv"
  `include "../tb/env.sv"

  // Test
  `include "../test/test.sv"

endpackage
