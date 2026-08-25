class mst_agent extends uvm_agent;

        `uvm_component_utils(mst_agent)

        // Agent components
        mst_driver    drv;
        mst_sequencer seqr;
        mst_monitor   mon;

        // Master agent configuration
        mst_config cfg;


        // Constructor
        function new(string name = "mst_agent", uvm_component parent);
                super.new(name, parent);
        endfunction


        // Build phase: Get configuration and create agent components
        function void build_phase(uvm_phase phase);
                super.build_phase(phase);

                if (!uvm_config_db#(mst_config)::get(this, "", "mst_config", cfg))
                        `uvm_fatal("MASTER CONFIG", "FAILED")

                // Monitor is created for both active and passive agents
                mon = mst_monitor::type_id::create("mon", this);

                // Driver and sequencer are created only for an active agent
                if (cfg.is_active == UVM_ACTIVE) begin
                        drv  = mst_driver::type_id::create("drv", this);
                        seqr = mst_sequencer::type_id::create("seqr", this);
                end

        endfunction


        // Connect driver to sequencer for active agent operation
        function void connect_phase(uvm_phase phase);
                super.connect_phase(phase);

                if (cfg.is_active == UVM_ACTIVE)
                        drv.seq_item_port.connect(seqr.seq_item_export);

        endfunction

endclass
