package pkg;

        import uvm_pkg::*;

        `include "uvm_macros.svh"


        // ---------------------------------------------------------------------
        // Configuration Classes & Transaction Class
        // ---------------------------------------------------------------------

        `include "mst_config.sv"
        `include "slv_config.sv"
        `include "env_config.sv"
        `include "axi_xtn.sv"


        // ---------------------------------------------------------------------
        // Master Agent
        // ---------------------------------------------------------------------

        `include "mst_seqs.sv"
        `include "mst_sequencer.sv"
        `include "mst_driver.sv"
        `include "mst_monitor.sv"
        `include "mst_agent.sv"
        `include "mst_agt_top.sv"


        // ---------------------------------------------------------------------
        // Slave Agent
        // ---------------------------------------------------------------------

        `include "slv_driver.sv"
        `include "slv_monitor.sv"
        `include "slv_agent.sv"
        `include "slv_agt_top.sv"


        // ---------------------------------------------------------------------
        // Environment and Verification Components
        // ---------------------------------------------------------------------

        `include "scoreboard.sv"
        `include "virtual_sequencer.sv"
        `include "virtual_seqs.sv"
        `include "env.sv"
        `include "test.sv"

endpackage
