class mst_monitor extends uvm_monitor;

        `uvm_component_utils(mst_monitor)

        // Virtual interface and master agent configuration
        virtual axi_if.MST_MON vif;
        mst_config cfg;

        // Transaction handles
        axi_xtn xtn, xtn1, xtn2, xtn3, xtn4;

        // Queues used to associate address information with
        // corresponding write/read data transactions
        axi_xtn q1[$], q2[$];

        // Semaphores for channel synchronization

        // Write channel dependencies
        semaphore sem_awdc = new();    // Write Address -> Write Data dependency
        semaphore sem_wdrc = new();    // Write Data -> Write Response dependency

        // Write channel access control
        semaphore sem_awc = new(1);    // Write Address channel
        semaphore sem_wdc = new(1);    // Write Data channel
        semaphore sem_wrc = new(1);    // Write Response channel

        // Read channel dependencies
        semaphore sem_ardc = new();    // Read Address -> Read Data dependency

        // Read channel access control
        semaphore sem_arc = new(1);    // Read Address channel
        semaphore sem_rdc = new(1);    // Read Data channel

        // Analysis port for broadcasting monitored transactions
        uvm_analysis_port #(axi_xtn) monitor_port;


        // Constructor
        function new(string name = "mst_monitor", uvm_component parent);
                super.new(name, parent);
        endfunction


        // Build phase: Get configuration and create analysis port
        function void build_phase(uvm_phase phase);
                super.build_phase(phase);

                if (!uvm_config_db#(mst_config)::get(this, "", "mst_config", cfg))
                        `uvm_fatal("MASTER MONITOR CONFIG", "FAILED")

                monitor_port = new("monitor_port", this);
        endfunction


        // Connect phase: Assign virtual interface
        function void connect_phase(uvm_phase phase);
                super.connect_phase(phase);
                vif = cfg.vif;
        endfunction


        // Continuously collect transactions from all AXI channels
        task run_phase(uvm_phase phase);
                super.run_phase(phase);

                forever
                        collect();
        endtask


        // Collect write and read channel transactions in parallel
        task collect();

                fork

                        // Write Address Channel
                        begin
                                sem_awc.get(1);
                                collect_waddr();
                                sem_awdc.put(1);
                                sem_awc.put(1);
                        end


                        // Write Data Channel
                        begin
                                sem_awdc.get(1);
                                sem_wdc.get(1);
                                collect_wdata(q1.pop_front());
                                sem_wdc.put(1);
                                sem_wdrc.put(1);
                        end


                        // Write Response Channel
                        begin
                                sem_wdrc.get(1);
                                sem_wrc.get(1);
                                collect_bresp();
                                sem_wrc.put(1);
                        end


                        // Read Address Channel
                        begin
                                sem_arc.get(1);
                                collect_raddr();
                                sem_ardc.put(1);
                                sem_arc.put(1);
                        end


                        // Read Data Channel
                        begin
                                sem_ardc.get(1);
                                sem_rdc.get(1);
                                collect_rdata(q2.pop_front());
                                sem_rdc.put(1);
                        end

                join_any

        endtask


        // Collect Write Address channel transaction
        task collect_waddr();

                xtn = axi_xtn::type_id::create("xtn");

                // Wait for AW channel handshake
                wait (vif.mst_mon_cb.AWVALID && vif.mst_mon_cb.AWREADY);

                xtn.AWVALID = vif.mst_mon_cb.AWVALID;
                xtn.AWADDR  = vif.mst_mon_cb.AWADDR;
                xtn.AWSIZE  = vif.mst_mon_cb.AWSIZE;
                xtn.AWID    = vif.mst_mon_cb.AWID;
                xtn.AWLEN   = vif.mst_mon_cb.AWLEN;
                xtn.AWBURST = vif.mst_mon_cb.AWBURST;
                xtn.AWREADY = vif.mst_mon_cb.AWREADY;

                // Store address transaction for corresponding write data collection
                q1.push_back(xtn);

                `uvm_info("MASTER MONITOR",
                          $sformatf("Write Address Channel: \n%s", xtn.sprint()),
                          UVM_LOW)

                monitor_port.write(xtn);

                @(vif.mst_mon_cb);

        endtask


        // Collect Write Data channel transaction
        task collect_wdata(axi_xtn xtn);

                xtn1 = axi_xtn::type_id::create("xtn1");
                xtn1 = xtn;

                // Allocate arrays based on burst length
                xtn1.WDATA = new[xtn.AWLEN + 1];
                xtn1.WSTRB = new[xtn.WDATA.size()];

                foreach (xtn1.WDATA[i]) begin

                        // Wait for W channel handshake
                        wait (vif.mst_mon_cb.WVALID && vif.mst_mon_cb.WREADY);

                        xtn1.WSTRB[i] = vif.mst_mon_cb.WSTRB;

                        // Capture valid data bytes based on write strobes
                        if (vif.mst_mon_cb.WSTRB == 15)
                                xtn1.WDATA[i] = vif.mst_mon_cb.WDATA;

                        if (vif.mst_mon_cb.WSTRB == 8)
                                xtn1.WDATA[i] = vif.mst_mon_cb.WDATA[31:24];

                        if (vif.mst_mon_cb.WSTRB == 4)
                                xtn1.WDATA[i] = vif.mst_mon_cb.WDATA[23:16];

                        if (vif.mst_mon_cb.WSTRB == 2)
                                xtn1.WDATA[i] = vif.mst_mon_cb.WDATA[15:8];

                        if (vif.mst_mon_cb.WSTRB == 1)
                                xtn1.WDATA[i] = vif.mst_mon_cb.WDATA[7:0];

                        if (vif.mst_mon_cb.WSTRB == 14)
                                xtn1.WDATA[i] = vif.mst_mon_cb.WDATA[31:8];

                        if (vif.mst_mon_cb.WSTRB == 12)
                                xtn1.WDATA[i] = vif.mst_mon_cb.WDATA[31:16];

                        if (vif.mst_mon_cb.WSTRB == 3)
                                xtn1.WDATA[i] = vif.mst_mon_cb.WDATA[15:0];

                        xtn1.WID    = vif.mst_mon_cb.WID;
                        xtn1.WLAST  = vif.mst_mon_cb.WLAST;
                        xtn1.WVALID = vif.mst_mon_cb.WVALID;
                        xtn1.WREADY = vif.mst_mon_cb.WREADY;

                        @(vif.mst_mon_cb);

                end

                `uvm_info("MASTER MONITOR",
                          $sformatf("Write Data Channel: \n%s", xtn1.sprint()),
                          UVM_LOW)

                monitor_port.write(xtn1);

        endtask


        // Collect Write Response channel transaction
        task collect_bresp();

                xtn2 = axi_xtn::type_id::create("xtn2");

                // Wait for B channel handshake
                wait (vif.mst_mon_cb.BREADY && vif.mst_mon_cb.BVALID);

                xtn2.BRESP  = vif.mst_mon_cb.BRESP;
                xtn2.BID    = vif.mst_mon_cb.BID;
                xtn2.BREADY = vif.mst_mon_cb.BREADY;
                xtn2.BVALID = vif.mst_mon_cb.BVALID;

                `uvm_info("MASTER MONITOR",
                          $sformatf("Write Response Channel: \n%s", xtn2.sprint()),
                          UVM_LOW)

                monitor_port.write(xtn2);

                @(vif.mst_mon_cb);

        endtask


        // Collect Read Address channel transaction
        task collect_raddr();

                xtn3 = axi_xtn::type_id::create("xtn3");

                // Wait for AR channel handshake
                wait (vif.mst_mon_cb.ARVALID && vif.mst_mon_cb.ARREADY);

                xtn3.ARVALID = vif.mst_mon_cb.ARVALID;
                xtn3.ARADDR  = vif.mst_mon_cb.ARADDR;
                xtn3.ARSIZE  = vif.mst_mon_cb.ARSIZE;
                xtn3.ARID    = vif.mst_mon_cb.ARID;
                xtn3.ARLEN   = vif.mst_mon_cb.ARLEN;
                xtn3.ARBURST = vif.mst_mon_cb.ARBURST;
                xtn3.ARREADY = vif.mst_mon_cb.ARREADY;

                // Store address transaction for corresponding read data collection
                q2.push_back(xtn3);

                `uvm_info("MASTER MONITOR",
                          $sformatf("Read Address Channel: \n%s", xtn3.sprint()),
                          UVM_LOW)

                monitor_port.write(xtn3);

                @(vif.mst_mon_cb);

        endtask


        // Collect Read Data channel transaction
        task collect_rdata(axi_xtn xtn);

                xtn4 = axi_xtn::type_id::create("xtn4");
                xtn4 = xtn;

                // Allocate read data array based on burst length
                xtn4.RDATA = new[xtn4.ARLEN + 1];

                foreach (xtn4.RDATA[i]) begin

                        // Wait for R channel handshake
                        wait (vif.mst_mon_cb.RVALID && vif.mst_mon_cb.RREADY);

                        xtn4.RRESP[i] = vif.mst_mon_cb.RRESP;
                        xtn4.RDATA[i] = vif.mst_mon_cb.RDATA;
                        xtn4.RID      = vif.mst_mon_cb.RID;
                        xtn4.RREADY   = vif.mst_mon_cb.RREADY;
                        xtn4.RVALID   = vif.mst_mon_cb.RVALID;

                        // Capture RLAST for the final beat
                        if (i == xtn4.RDATA.size() - 1)
                                xtn4.RLAST = vif.mst_mon_cb.RLAST;

                        @(vif.mst_mon_cb);

                end

                `uvm_info("MASTER MONITOR",
                          $sformatf("Read Data Channel: \n%s", xtn4.sprint()),
                          UVM_LOW)

                monitor_port.write(xtn4);

        endtask

endclass
