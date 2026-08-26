class slv_agt_top extends uvm_env;

        `uvm_component_utils(slv_agt_top)

        // Slave agent instance
        slv_agent agent;


        // Constructor
        function new(string name = "slv_agt_top", uvm_component parent);
                super.new(name, parent);
        endfunction


        // Build phase
        function void build_phase(uvm_phase phase);
                super.build_phase(phase);

                // Create slave agent
                agent = slv_agent::type_id::create("agent", this);
        endfunction

endclass
