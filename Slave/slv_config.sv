class slv_config extends uvm_object;

        `uvm_object_utils(slv_config)

        // Virtual interface handle
        virtual axi_if vif;

        // Agent operating mode
        uvm_active_passive_enum is_active = UVM_ACTIVE;


        // Constructor
        function new(string name = "slv_config");
                super.new(name);
        endfunction

endclass
