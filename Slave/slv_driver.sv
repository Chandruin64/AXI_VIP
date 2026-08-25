class slv_driver extends uvm_driver #(axi_xtn);

        `uvm_component_utils(slv_driver)

        // Virtual interface and slave configuration
        virtual axi_if.SLV_DRV vif;
        slv_config cfg;

        // Transaction handles
        axi_xtn xtn, xtn1;

        // Queues used to pass captured address information
        // to dependent write/read channel tasks
        axi_xtn q1[$], q2[$], q3[$];

        // Write channel synchronization

        // Write Address -> Write Data dependency
        semaphore sem_awad = new();

        // Write Data -> Write Response dependency
        semaphore sem_wdrp = new();

        // Write Address channel access
        semaphore sem_awaddr = new(1);

        // Write Data channel access
        semaphore sem_awdata = new(1);

        // Write Response channel access
        semaphore sem_wrp = new(1);

        // Read channel synchronization

        // Read Address -> Read Data dependency
        semaphore sem_radc = new();

        // Read Address channel access
        semaphore sem_rac = new(1);

        // Read Data channel access
        semaphore sem_rdc = new(1);


        // Constructor
        function new(string name = "slv_driver", uvm_component parent);
                super.new(name, parent);
        endfunction


        // Build phase: Get slave configuration
        function void build_phase(uvm_phase phase);
                super.build_phase(phase);

                if (!uvm_config_db#(slv_config)::get(this, "", "slv_config", cfg))
                        `uvm_fatal("SLAVE DRIVER CONFIG", "FAILED")

        endfunction


        // Connect phase: Assign virtual interface
        function void connect_phase(uvm_phase phase);
                super.connect_phase(phase);

                vif = cfg.vif;
        endfunction


        // Continuously execute slave channel operations
        task run_phase(uvm_phase phase);
                super.run_phase(phase);

                forever begin
                        drive();
                end

        endtask


        // Coordinate all five AXI channels
        task drive();

                xtn = axi_xtn::type_id::create("xtn");

                fork

                        // Write Address Channel
                        begin
                                sem_awaddr.get(1);
                                drive_awaddr(xtn);
                                sem_awaddr.put(1);
                                sem_awad.put(1);
                        end


                        // Write Data Channel
                        begin
                                sem_awad.get(1);
                                sem_awdata.get(1);
                                drive_wdata(q1.pop_front());
                                sem_awdata.put(1);
                                sem_wdrp.put(1);
                        end


                        // Write Response Channel
                        begin
                                sem_wdrp.get(1);
                                sem_wrp.get(1);
                                drive_wresp(q2.pop_front());
                                sem_wrp.put(1);
                        end


                        // Read Address Channel
                        begin
                                sem_rac.get(1);
                                drive_raddr();
                                sem_radc.put(1);
                                sem_rac.put(1);
                        end


                        // Read Data Channel
                        begin
                                sem_radc.get(1);
                                sem_rdc.get(1);
                                drive_rdata(q3.pop_front());
                                sem_rdc.put(1);
                        end

                join_any

        endtask


        // Accept Write Address channel transaction from master
        task drive_awaddr(axi_xtn xtn);

                $display("Start of slave drive_awaddr");

                // Introduce randomized ready delay
                repeat ($urandom_range(1, 5)) @(vif.slv_drv_cb);

                vif.slv_drv_cb.AWREADY <= 1;

                @(vif.slv_drv_cb);

                // Wait for master to assert AWVALID
                wait (vif.slv_drv_cb.AWVALID);

                // Capture write address information
                xtn.ARESETn = vif.slv_drv_cb.ARESETn;
                xtn.AWVALID = vif.slv_drv_cb.AWVALID;
                xtn.AWID    = vif.slv_drv_cb.AWID;
                xtn.AWADDR  = vif.slv_drv_cb.AWADDR;
                xtn.AWSIZE  = vif.slv_drv_cb.AWSIZE;
                xtn.AWLEN   = vif.slv_drv_cb.AWLEN;
                xtn.AWBURST = vif.slv_drv_cb.AWBURST;

                // Store transaction for write data and response channels
                q1.push_back(xtn);
                q2.push_back(xtn);

                vif.slv_drv_cb.AWREADY <= 0;

                repeat ($urandom_range(1, 5)) @(vif.slv_drv_cb);

                $display("End of slave drive_awaddr");

        endtask


        // Accept Write Data beats from master
        task drive_wdata(axi_xtn xtn);

                $display("Start of slave drive_wdata");

                for (int i = 0; i < xtn.AWLEN + 1; i++) begin

                        vif.slv_drv_cb.WREADY <= 1;

                        @(vif.slv_drv_cb);

                        // Wait for master to provide valid write data
                        wait (vif.slv_drv_cb.WVALID);

                        vif.slv_drv_cb.WREADY <= 0;

                        repeat ($urandom_range(1, 5)) @(vif.slv_drv_cb);

                end

                $display("End of slave drive_wdata");

        endtask


        // Generate Write Response channel transaction
        task drive_wresp(axi_xtn xtn);

                $display("Start of slave drive_wresp");

                vif.slv_drv_cb.BVALID <= 1;
                vif.slv_drv_cb.BRESP  <= 0;
                vif.slv_drv_cb.BID    <= xtn.AWID;

                $display("BID sent is %0d", xtn.AWID);

                @(vif.slv_drv_cb);

                // Wait for master to accept the response
                wait (vif.slv_drv_cb.BREADY);

                vif.slv_drv_cb.BRESP  <= 'hz;
                vif.slv_drv_cb.BVALID <= 0;

                repeat ($urandom_range(1, 5)) @(vif.slv_drv_cb);

                $display("End of slave drive_wresp");

        endtask


        // Accept Read Address channel transaction from master
        task drive_raddr();

                $display("Start of slave drive_raddr");

                xtn1 = axi_xtn::type_id::create("xtn1");

                repeat ($urandom_range(1, 5)) @(vif.slv_drv_cb);

                vif.slv_drv_cb.ARREADY <= 1;

                @(vif.slv_drv_cb);

                // Wait for master to assert ARVALID
                wait (vif.slv_drv_cb.ARVALID);

                // Capture read address information
                xtn1.ARVALID = vif.slv_drv_cb.ARVALID;
                xtn1.ARID    = vif.slv_drv_cb.ARID;
                xtn1.ARADDR  = vif.slv_drv_cb.ARADDR;
                xtn1.ARSIZE  = vif.slv_drv_cb.ARSIZE;
                xtn1.ARLEN   = vif.slv_drv_cb.ARLEN;
                xtn1.ARBURST = vif.slv_drv_cb.ARBURST;

                // Store transaction for read data generation
                q3.push_back(xtn1);

                repeat ($urandom_range(1, 5)) @(vif.slv_drv_cb);

                vif.slv_drv_cb.ARREADY <= 0;

                $display("End of slave drive_raddr");

        endtask


        // Generate Read Data channel beats
        task drive_rdata(axi_xtn xtn);

                $display("Start of slave drive_rdata");

                for (int i = 0; i < xtn.ARLEN + 1; i++) begin

                        // Generate randomized read data
                        vif.slv_drv_cb.RDATA  <= $urandom;
                        vif.slv_drv_cb.RID    <= xtn.ARID;
                        vif.slv_drv_cb.RVALID <= 1;
                        vif.slv_drv_cb.RRESP  <= 0;

                        // Assert RLAST on the final beat
                        if (i == xtn.ARLEN)
                                vif.slv_drv_cb.RLAST <= 1;
                        else
                                vif.slv_drv_cb.RLAST <= 0;

                        @(vif.slv_drv_cb);

                        // Wait for master to accept read data
                        wait (vif.slv_drv_cb.RREADY);

                        vif.slv_drv_cb.RVALID <= 0;
                        vif.slv_drv_cb.RLAST  <= 0;
                        vif.slv_drv_cb.RRESP  <= 'hz;

                        repeat ($urandom_range(1, 5)) @(vif.slv_drv_cb);

                end

                $display("End of slave drive_rdata");

        endtask

endclass
