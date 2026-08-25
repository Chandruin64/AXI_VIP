class mst_agt_top extends uvm_env;

        `uvm_component_utils(mst_agt_top)

        // Master agent instance
        mst_agent agent;


        // Constructor
        function new(string name = "mst_agt_top", uvm_component parent);
                super.new(name, parent);
        endfunction


        // Build phase: Create the master agent
        function void build_phase(uvm_phase phase);
                super.build_phase(phase);

                agent = mst_agent::type_id::create("agent", this);
        endfunction

endclass
