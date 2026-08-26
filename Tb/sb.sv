class scoreboard extends uvm_scoreboard;

    `uvm_component_utils(scoreboard)

    // Analysis FIFOs for transactions from master and slave monitors
    uvm_tlm_analysis_fifo #(axi_xtn) mst_fifo;
    uvm_tlm_analysis_fifo #(axi_xtn) slv_fifo;

    // Environment configuration
    env_config env_cfg;

    // Transaction handles
    axi_xtn wr_xtn;
    axi_xtn rd_xtn;
    axi_xtn mst_xtn;
    axi_xtn slv_xtn;

    // Packet statistics
    static int pkt_rcvd;
    static int pkt_cmprd;


    // Write address and response coverage
    covergroup write_cg;

        option.per_instance = 1;

        awaddr: coverpoint wr_xtn.AWADDR {
            bins awaddr_bin = {[0:'hffff_ffff]};
        }

        awburst: coverpoint wr_xtn.AWBURST {
            bins awburst_bin[] = {[0:2]};
        }

        awlen: coverpoint wr_xtn.AWLEN {
            ignore_bins awlen_bin1 = {0, 2, 4, 5, 6, [8:14]}
                                     iff (wr_xtn.AWBURST == 2'b10);
            bins awlen_bin[] = {[0:15]};
        }

        awsize: coverpoint wr_xtn.AWSIZE {
            bins awsize_bin = {[0:2]};
        }

        bresp: coverpoint wr_xtn.BRESP {
            bins bresp_bin = {0};
        }

        // Cross coverage for write burst configuration
        Write_x_Addr: cross awburst, awsize, awlen;

    endgroup


    // Write data and write strobe coverage
    covergroup write_cg1 with function sample(int i);

        option.per_instance = 1;

        wdata: coverpoint wr_xtn.WDATA[i] {
            bins wdata = {[0:'hffff_ffff]};
        }

        wstrp: coverpoint wr_xtn.WSTRB[i] {
            bins wstrobe0 = {4'b1111};
            bins wstrobe1 = {4'b1100};
            bins wstrobe2 = {4'b0011};
            bins wstrobe3 = {4'b1000};
            bins wstrobe4 = {4'b0100};
            bins wstrobe5 = {4'b0010};
            bins wstrobe6 = {4'b0001};
            bins wstrobe7 = {4'b1110};
        }

    endgroup


    // Read address coverage
    covergroup read_cg;

        option.per_instance = 1;

        araddr: coverpoint rd_xtn.ARADDR {
            bins araddr_bin = {[0:'hffff_ffff]};
        }

        arburst: coverpoint rd_xtn.ARBURST {
            bins arburst_bin[] = {[0:2]};
        }

        arlen: coverpoint rd_xtn.ARLEN {
            ignore_bins arlen_bin1 = {0, 2, 4, 5, 6, [8:14]}
                                      iff (rd_xtn.ARBURST == 2'b10);
            bins arlen_bin[] = {[0:15]};
        }

        arsize: coverpoint rd_xtn.ARSIZE {
            bins arsize_bin = {[0:2]};
        }

        // Cross coverage for read burst configuration
        Read_x_Addr: cross arburst, arsize, arlen;

    endgroup


    // Read data and response coverage
    covergroup read_cg1 with function sample(int i);

        option.per_instance = 1;

        rdata: coverpoint rd_xtn.RDATA[i] {
            bins rdata = {[0:'hffff_ffff]};
        }

        rresp: coverpoint rd_xtn.RRESP[i] {
            bins rresp = {0};
        }

    endgroup


    function new(string name = "scoreboard", uvm_component parent);

        super.new(name, parent);

        // Create coverage groups
        write_cg  = new();
        write_cg1 = new();
        read_cg   = new();
        read_cg1  = new();

    endfunction


    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        // Get environment configuration
        if (!uvm_config_db#(env_config)::get(this, "", "env_config", env_cfg))
            `uvm_fatal("SCOREBOARD ENV CONFIG", "FAILED")

        // Create analysis FIFOs
        mst_fifo = new("mst_fifo", this);
        slv_fifo = new("slv_fifo", this);

    endfunction


    task run_phase(uvm_phase phase);

        forever begin

            // Receive transactions from master and slave monitors
            mst_fifo.get(mst_xtn);
            slv_fifo.get(slv_xtn);

            pkt_rcvd++;

            // Compare master and slave transactions
            if (mst_xtn.compare(slv_xtn)) begin

                wr_xtn = mst_xtn;
                rd_xtn = slv_xtn;

                pkt_cmprd++;

                // Sample write and read address coverage
                write_cg.sample();
                read_cg.sample();

                // Sample write data and strobe coverage
                if (mst_xtn.WVALID)
                    foreach (mst_xtn.WDATA[i])
                        write_cg1.sample(i);

                // Sample read data and response coverage
                if (mst_xtn.RVALID)
                    foreach (mst_xtn.RDATA[i])
                        read_cg1.sample(i);

                `uvm_info(
                    "SCOREBOARD",
                    "DATA MATCH SUCCESSFULLY",
                    UVM_LOW
                )

            end
            else begin

                `uvm_error("SCOREBOARD", "DATA MISMATCH")

                $display(
                    "Master packet: \n%s",
                    mst_xtn.sprint()
                );

                $display(
                    "Slave packet: \n%s",
                    slv_xtn.sprint()
                );

            end

        end

    endtask


    function void report_phase(uvm_phase phase);

        `uvm_info(
            "SCOREBOARD",
            $sformatf("No of packets received: %0d", pkt_rcvd),
            UVM_LOW
        )

        `uvm_info(
            "SCOREBOARD",
            $sformatf("No of packets compared: %0d", pkt_cmprd),
            UVM_LOW
        )

    endfunction

endclass
