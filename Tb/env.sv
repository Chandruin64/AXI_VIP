class environment extends uvm_env;

    `uvm_component_utils(environment)

    // Environment configuration
    env_config env_cfg;

    // Virtual sequencer
    virtual_sequencer vseqr;

    // Agent top-level components
    mst_agt_top mst_top;
    slv_agt_top slv_top;

    // Scoreboard
    scoreboard sb;


    function new(string name = "environment", uvm_component parent);
        super.new(name, parent);
    endfunction


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Get environment configuration
        if (!uvm_config_db#(env_config)::get(this, "", "env_config", env_cfg))
            `uvm_fatal("ENVIRONMENT CONFIG", "FAILED")

        // Create master agent and set its configuration
        if (env_cfg.has_master_agent) begin
            mst_top = mst_agt_top::type_id::create("mst_top", this);
            uvm_config_db#(mst_config)::set(
                this, "*", "mst_config", env_cfg.mst_cfg
            );
        end

        // Create slave agent and set its configuration
        if (env_cfg.has_slave_agent) begin
            slv_top = slv_agt_top::type_id::create("slv_top", this);
            uvm_config_db#(slv_config)::set(
                this, "*", "slv_config", env_cfg.slv_cfg
            );
        end

        // Create scoreboard
        if (env_cfg.has_scoreboard)
            sb = scoreboard::type_id::create("sb", this);

        // Create virtual sequencer
        if (env_cfg.has_virtual_sequence)
            vseqr = virtual_sequencer::type_id::create("vseqr", this);

    endfunction


    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // Connect physical sequencers to the virtual sequencer
        if (env_cfg.has_virtual_sequence) begin
            vseqr.mst_seqr = mst_top.agent.seqr;
            vseqr.slv_seqr = slv_top.agent.seqr;
        end

        // Connect master and slave monitors to the scoreboard
        if (env_cfg.has_scoreboard) begin
            mst_top.agent.mon.monitor_port.connect(
                sb.mst_fifo.analysis_export
            );

            slv_top.agent.mon.monitor_port.connect(
                sb.slv_fifo.analysis_export
            );
        end

    endfunction

endclass
