class slv_monitor extends uvm_monitor;

        `uvm_component_utils(slv_monitor)

        // Virtual interface and configuration
        virtual axi_if.SLV_MON vif;
        slv_config cfg;

        // Transaction handles
        axi_xtn xtn, xtn1, xtn2, xtn3, xtn4;

        // Queues for channel dependency tracking
        axi_xtn q1[$], q2[$];

        // Write channel synchronization
        semaphore sem_awdc = new();      // Write Data Dependency
        semaphore sem_wdrc = new();      // Write Response Dependency
        semaphore sem_awc  = new(1);     // Write Address Channel
        semaphore sem_wdc  = new(1);     // Write Data Channel
        semaphore sem_wrc  = new(1);     // Write Response Channel

        // Read channel synchronization
        semaphore sem_ardc = new();      // Read Data Dependency
        semaphore sem_arc  = new(1);     // Read Address Channel
        semaphore sem_rdc  = new(1);     // Read Data Channel

        // Monitor analysis port
        uvm_analysis_port #(axi_xtn) monitor_port;


        // Constructor
        function new (string name = "slv_monitor", uvm_component parent);
                super.new(name, parent);
        endfunction


        // Build phase
        function void build_phase (uvm_phase phase);
                super.build_phase(phase);

                if (!uvm_config_db#(slv_config)::get(this, "", "slv_config", cfg))
                        `uvm_fatal("SLAVE MONITOR CONFIG", "FAILED")

                monitor_port = new("monitor_port", this);
        endfunction


        // Connect virtual interface from configuration
        function void connect_phase (uvm_phase phase);
                super.connect_phase(phase);

                vif = cfg.vif;
        endfunction


        // Continuously collect transactions
        task run_phase (uvm_phase phase);
                super.run_phase(phase);

                forever
                        collect();
        endtask


        // Fork channel collection processes with dependency control
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


        // Collect Write Address Channel transaction
        task collect_waddr();

                xtn = axi_xtn::type_id::create("xtn");

                wait (vif.slv_mon_cb.AWVALID && vif.slv_mon_cb.AWREADY);

                xtn.AWVALID = vif.slv_mon_cb.AWVALID;
                xtn.AWADDR  = vif.slv_mon_cb.AWADDR;
                xtn.AWSIZE  = vif.slv_mon_cb.AWSIZE;
                xtn.AWID    = vif.slv_mon_cb.AWID;
                xtn.AWLEN   = vif.slv_mon_cb.AWLEN;
                xtn.AWBURST = vif.slv_mon_cb.AWBURST;
                xtn.AWREADY = vif.slv_mon_cb.AWREADY;

                q1.push_back(xtn);

                `uvm_info("SLAVE MONITOR",
                          $sformatf("Write Address Channel: \n%s", xtn.sprint()),
                          UVM_LOW)

                monitor_port.write(xtn);

                @(vif.slv_mon_cb);

        endtask


        // Collect Write Data Channel transaction
        task collect_wdata(axi_xtn xtn);

                xtn1 = axi_xtn::type_id::create("xtn1");
                xtn1 = xtn;

                xtn1.WDATA = new [xtn.AWLEN + 1];
                xtn1.WSTRB = new [xtn.AWLEN + 1];

                foreach (xtn1.WDATA[i]) begin

                        wait (vif.slv_mon_cb.WVALID && vif.slv_mon_cb.WREADY);

                        xtn1.WSTRB[i] = vif.slv_mon_cb.WSTRB;

                        if (vif.slv_mon_cb.WSTRB == 15)
                                xtn1.WDATA[i] = vif.slv_mon_cb.WDATA;

                        if (vif.slv_mon_cb.WSTRB == 8)
                                xtn1.WDATA[i] = vif.slv_mon_cb.WDATA[31:24];

                        if (vif.slv_mon_cb.WSTRB == 4)
                                xtn1.WDATA[i] = vif.slv_mon_cb.WDATA[23:16];

                        if (vif.slv_mon_cb.WSTRB == 2)
                                xtn1.WDATA[i] = vif.slv_mon_cb.WDATA[15:8];

                        if (vif.slv_mon_cb.WSTRB == 1)
                                xtn1.WDATA[i] = vif.slv_mon_cb.WDATA[7:0];

                        if (vif.slv_mon_cb.WSTRB == 14)
                                xtn1.WDATA[i] = vif.slv_mon_cb.WDATA[31:8];

                        if (vif.slv_mon_cb.WSTRB == 12)
                                xtn1.WDATA[i] = vif.slv_mon_cb.WDATA[31:16];

                        if (vif.slv_mon_cb.WSTRB == 3)
                                xtn1.WDATA[i] = vif.slv_mon_cb.WDATA[15:0];

                        xtn1.WID    = vif.slv_mon_cb.WID;
                        xtn1.WLAST  = vif.slv_mon_cb.WLAST;
                        xtn1.WVALID = vif.slv_mon_cb.WVALID;

                        @(vif.slv_mon_cb);

                end

                `uvm_info("SLAVE MONITOR",
                          $sformatf("Write Data Channel: \n%s", xtn1.sprint()),
                          UVM_LOW)

                monitor_port.write(xtn1);

        endtask


        // Collect Write Response Channel transaction
        task collect_bresp();

                xtn2 = axi_xtn::type_id::create("xtn2");

                wait (vif.slv_mon_cb.BREADY && vif.slv_mon_cb.BVALID);

                xtn2.BRESP  = vif.slv_mon_cb.BRESP;
                xtn2.BREADY = vif.slv_mon_cb.BREADY;
                xtn2.BVALID = vif.slv_mon_cb.BVALID;
                xtn2.BID    = vif.slv_mon_cb.BID;

                `uvm_info("SLAVE MONITOR",
                          $sformatf("Write Response Channel: \n%s", xtn2.sprint()),
                          UVM_LOW)

                monitor_port.write(xtn2);

                @(vif.slv_mon_cb);

        endtask


        // Collect Read Address Channel transaction
        task collect_raddr();

                xtn3 = axi_xtn::type_id::create("xtn3");

                wait (vif.slv_mon_cb.ARVALID && vif.slv_mon_cb.ARREADY);

                xtn3.ARVALID = vif.slv_mon_cb.ARVALID;
                xtn3.ARADDR  = vif.slv_mon_cb.ARADDR;
                xtn3.ARSIZE  = vif.slv_mon_cb.ARSIZE;
                xtn3.ARID    = vif.slv_mon_cb.ARID;
                xtn3.ARLEN   = vif.slv_mon_cb.ARLEN;
                xtn3.ARBURST = vif.slv_mon_cb.ARBURST;
                xtn3.ARREADY = vif.slv_mon_cb.ARREADY;

                q2.push_back(xtn3);

                `uvm_info("SLAVE MONITOR",
                          $sformatf("Read Address Channel: \n%s", xtn3.sprint()),
                          UVM_LOW)

                monitor_port.write(xtn3);

                @(vif.slv_mon_cb);

        endtask


        // Collect Read Data Channel transaction
        task collect_rdata(axi_xtn xtn);

                xtn4 = axi_xtn::type_id::create("xtn4");
                xtn4 = xtn;

                xtn4.RDATA = new [xtn4.ARLEN + 1];

                foreach (xtn4.RDATA[i]) begin

                        wait (vif.slv_mon_cb.RVALID && vif.slv_mon_cb.RREADY);

                        xtn4.RRESP[i] = vif.slv_mon_cb.RRESP;
                        xtn4.RDATA[i] = vif.slv_mon_cb.RDATA;
                        xtn4.RID      = vif.slv_mon_cb.RID;
                        xtn4.RREADY   = vif.slv_mon_cb.RREADY;
                        xtn4.RVALID   = vif.slv_mon_cb.RVALID;

                        if (i == xtn4.RDATA.size() - 1)
                                xtn4.RLAST = vif.slv_mon_cb.RLAST;

                        @(vif.slv_mon_cb);

                end

                `uvm_info("SLAVE MONITOR",
                          $sformatf("Read Data Channel: \n%s", xtn4.sprint()),
                          UVM_LOW)

                monitor_port.write(xtn4);

        endtask

endclass
