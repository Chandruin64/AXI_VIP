class slv_agent extends uvm_agent;

        `uvm_component_utils(slv_agent)

        // Slave agent components
        slv_driver    drv;
        slv_monitor   mon;

        // Slave agent configuration
        slv_config cfg;


        // Constructor
        function new(string name = "slv_agent", uvm_component parent);
                super.new(name, parent);
        endfunction


        // Build phase
        function void build_phase(uvm_phase phase);
                super.build_phase(phase);

                // Get slave configuration from configuration database
                if (!uvm_config_db#(slv_config)::get(this, "", "slv_config", cfg))
                  `uvm_fatal("SLAVE CONFIG", "FAILED")

                // Monitor is created for both active and passive agents
                mon = slv_monitor::type_id::create("mon", this);

                // Driver is created only for an active agent
                if (cfg.is_active == UVM_ACTIVE) begin
                        drv  = slv_driver::type_id::create("drv", this);
                end
        endfunction


endclass
