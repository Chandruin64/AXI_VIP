class mst_config extends uvm_object;

        `uvm_object_utils(mst_config)

        // Virtual interface handle
        virtual axi_if vif;

        // Controls whether the agent operates in active or passive mode
        uvm_active_passive_enum is_active = UVM_ACTIVE;


        // Constructor
        function new(string name = "mst_config");
                super.new(name);
        endfunction

endclass
