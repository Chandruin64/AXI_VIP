class base_test extends uvm_test;

        `uvm_component_utils(base_test)

        // Environment and agent configurations
        env_config env_cfg;
        mst_config mst_cfg;
        slv_config slv_cfg;

        // Environment instance
        environment env;


        // Constructor
        function new (string name = "base_test",
                      uvm_component parent);
                super.new(name, parent);
        endfunction


        // Build Phase
        function void build_phase (uvm_phase phase);
                super.build_phase(phase);

                // Create configuration objects
                env_cfg = env_config::type_id::create("env_cfg");
                mst_cfg = mst_config::type_id::create("mst_cfg");
                slv_cfg = slv_config::type_id::create("slv_cfg");

                // Get virtual interface for master configuration
                if (!uvm_config_db#(virtual axi_if)::get(this, "", "axi_if",
                                                         mst_cfg.vif))
                        `uvm_fatal("INTERFACE CONFIG", "FAILED")

                // Get virtual interface for slave configuration
                if (!uvm_config_db#(virtual axi_if)::get(this, "", "axi_if",
                                                         slv_cfg.vif))
                        `uvm_fatal("INTERFACE CONFIG", "FAILED")

                // Pass agent configurations to environment configuration
                env_cfg.mst_cfg = mst_cfg;
                env_cfg.slv_cfg = slv_cfg;

                // Set environment configuration in config DB
                uvm_config_db#(env_config)::set(this, "*", "env_config", env_cfg);

                // Create environment
                env = environment::type_id::create("env", this);
        endfunction


        // Print UVM component hierarchy
        function void end_of_elaboration_phase (uvm_phase phase);
                super.end_of_elaboration_phase(phase);
                uvm_top.print_topology();
        endfunction

endclass


// -----------------------------------------------------------------------------
// Fixed Burst Test
// -----------------------------------------------------------------------------

class fixed_test extends base_test;

        `uvm_component_utils(fixed_test)

        fixed_vseq seq;


        // Constructor
        function new (string name = "fixed_test",
                      uvm_component parent);
                super.new(name, parent);
        endfunction


        // Run Phase
        task run_phase (uvm_phase phase);
                super.run_phase(phase);

                phase.raise_objection(this);

                // Create and start fixed burst virtual sequence
                seq = fixed_vseq::type_id::create("seq");
                seq.start(env.vseqr);

                phase.drop_objection(this);
        endtask

endclass


// -----------------------------------------------------------------------------
// Incrementing Burst Test
// -----------------------------------------------------------------------------

class incr_test extends base_test;

        `uvm_component_utils(incr_test)

        incr_vseq seq;


        // Constructor
        function new (string name = "incr_test",
                      uvm_component parent);
                super.new(name, parent);
        endfunction


        // Run Phase
        task run_phase (uvm_phase phase);
                super.run_phase(phase);

                phase.raise_objection(this);

                // Create and start incrementing burst virtual sequence
                seq = incr_vseq::type_id::create("seq");
                seq.start(env.vseqr);

                phase.drop_objection(this);
        endtask

endclass


// -----------------------------------------------------------------------------
// Wrapping Burst Test
// -----------------------------------------------------------------------------

class wrap_test extends base_test;

        `uvm_component_utils(wrap_test)

        wrap_vseq seq;


        // Constructor
        function new (string name = "wrap_test",
                      uvm_component parent);
                super.new(name, parent);
        endfunction


        // Run Phase
        task run_phase (uvm_phase phase);
                super.run_phase(phase);

                phase.raise_objection(this);

                // Create and start wrapping burst virtual sequence
                seq = wrap_vseq::type_id::create("seq");
                seq.start(env.vseqr);

                phase.drop_objection(this);
        endtask

endclass
