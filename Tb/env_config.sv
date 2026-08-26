class env_config extends uvm_object;

    `uvm_object_utils(env_config)

    // Environment component configuration flags
    bit has_virtual_sequence = 1;
    bit has_master_agent     = 1;
    bit has_slave_agent      = 1;
    bit has_scoreboard       = 1;

    // Agent configuration handles
    mst_config mst_cfg;
    slv_config slv_cfg;

    function new(string name = "env_config");
        super.new(name);
    endfunction

endclass
