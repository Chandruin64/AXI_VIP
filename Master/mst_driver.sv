//------------------------------------------------------------------------------
// AXI Master Driver
//------------------------------------------------------------------------------
class mst_driver extends uvm_driver #(axi_xtn);

    `uvm_component_utils(mst_driver)

    // Virtual interface handle
    virtual axi_if.MST_DRV vif;

    // Master agent configuration
    mst_config cfg;

    // Transaction and transaction queues for parallel AXI channels
    axi_xtn xtn;
    axi_xtn q1[$], q2[$], q3[$], q4[$], q5[$];

    // Semaphores for write channel synchronization
    semaphore sem_awdc = new();    // Write Address-to-Data dependency
    semaphore sem_wdrc = new();    // Write Data-to-Response dependency
    semaphore sem_wdc  = new(1);   // Write Data channel
    semaphore sem_awc  = new(1);   // Write Address channel
    semaphore sem_wrc  = new(1);   // Write Response channel

    // Semaphores for read channel synchronization
    semaphore sem_ardc = new();    // Read Address-to-Data dependency
    semaphore sem_arc  = new(1);   // Read Address channel
    semaphore sem_rdc  = new(1);   // Read Data channel


    // Constructor
    function new(string name = "mst_driver", uvm_component parent);
        super.new(name, parent);
    endfunction


    // Get master configuration
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db #(mst_config)::get(this, "", "mst_config", cfg))
            `uvm_fatal("MASTER DRIVER CASTING", "FAILED")
    endfunction


    // Connect virtual interface from configuration
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        vif = cfg.vif;
    endfunction


    // Get transactions from the sequencer and drive them
    task run_phase(uvm_phase phase);
        super.run_phase(phase);

        forever begin
            seq_item_port.get_next_item(req);
            drive(req);
            seq_item_port.item_done();
        end
    endtask


    // Dispatch a transaction to the five AXI channels
    task drive(axi_xtn xtn);

        // Store the transaction in separate queues for parallel channel handling
        q1.push_back(xtn);
        q2.push_back(xtn);
        q3.push_back(xtn);
        q4.push_back(xtn);
        q5.push_back(xtn);

        fork

            // Write Address Channel
            begin
                sem_awc.get(1);
                drive_awaddr(q1.pop_front());
                sem_awdc.put(1);
                sem_awc.put(1);
            end


            // Write Data Channel
            begin
                sem_awdc.get(1);
                sem_wdc.get(1);
                drive_wdata(q2.pop_front());
                sem_wdc.put(1);
                sem_wdrc.put(1);
            end


            // Write Response Channel
            begin
                sem_wdrc.get(1);
                sem_wrc.get(1);
                drive_bresp(q3.pop_front());
                sem_wrc.put(1);
            end


            // Read Address Channel
            begin
                sem_arc.get(1);
                drive_raddr(q4.pop_front());
                sem_ardc.put(1);
                sem_arc.put(1);
            end


            // Read Data Channel
            begin
                sem_ardc.get(1);
                sem_rdc.get(1);
                drive_rdata(q5.pop_front());
                sem_rdc.put(1);
            end

        join_any

    endtask


    // Drive the Write Address channel
    task drive_awaddr(axi_xtn xtn);

        $display("Start of master drive_awaddr");

        vif.mst_drv_cb.AWVALID <= 1;
        vif.mst_drv_cb.AWID    <= xtn.AWID;
        vif.mst_drv_cb.AWADDR  <= xtn.AWADDR;
        vif.mst_drv_cb.AWSIZE  <= xtn.AWSIZE;
        vif.mst_drv_cb.AWLEN   <= xtn.AWLEN;
        vif.mst_drv_cb.AWBURST <= xtn.AWBURST;

        @(vif.mst_drv_cb);
        wait (vif.mst_drv_cb.AWREADY);

        vif.mst_drv_cb.AWVALID <= 0;

        repeat ($urandom_range(1, 5))
            @(vif.mst_drv_cb);

        $display("End of master drive_awaddr");

    endtask


    // Drive the Write Data channel
    task drive_wdata(axi_xtn xtn);

        $display("Start of master drive_wdata");

        foreach (xtn.WDATA[i]) begin

            vif.mst_drv_cb.WVALID <= 1;
            vif.mst_drv_cb.WID    <= xtn.WID;
            vif.mst_drv_cb.WDATA  <= xtn.WDATA[i];
            vif.mst_drv_cb.WSTRB  <= xtn.WSTRB[i];

            // Assert WLAST for the final data beat
            if (i == xtn.AWLEN)
                vif.mst_drv_cb.WLAST <= 1;
            else
                vif.mst_drv_cb.WLAST <= 0;

            @(vif.mst_drv_cb);
            wait (vif.mst_drv_cb.WREADY);

            vif.mst_drv_cb.WVALID <= 0;
            vif.mst_drv_cb.WLAST  <= 0;

            repeat ($urandom_range(1, 5))
                @(vif.mst_drv_cb);

        end

        $display("End of master drive_wdata");

    endtask


    // Drive the Write Response channel
    task drive_bresp(axi_xtn xtn);

        $display("Start of master drive_bresp");

        vif.mst_drv_cb.BREADY <= 1;

        @(vif.mst_drv_cb);
        wait (vif.mst_drv_cb.BVALID);

        vif.mst_drv_cb.BREADY <= 0;

        repeat ($urandom_range(1, 5))
            @(vif.mst_drv_cb);

        $display("End of master drive_bresp");

    endtask


    // Drive the Read Address channel
    task drive_raddr(axi_xtn xtn);

        $display("Start of master drive_raddr");

        // Introduce a randomized delay before issuing the read address
        repeat ($urandom_range(1, 5))
            @(vif.mst_drv_cb);

        vif.mst_drv_cb.ARVALID <= 1;
        vif.mst_drv_cb.ARID    <= xtn.ARID;
        vif.mst_drv_cb.ARADDR  <= xtn.ARADDR;
        vif.mst_drv_cb.ARSIZE  <= xtn.ARSIZE;
        vif.mst_drv_cb.ARLEN   <= xtn.ARLEN;
        vif.mst_drv_cb.ARBURST <= xtn.ARBURST;

        @(vif.mst_drv_cb);
        wait (vif.mst_drv_cb.ARREADY);

        vif.mst_drv_cb.ARVALID <= 0;

        repeat ($urandom_range(1, 5))
            @(vif.mst_drv_cb);

        $display("End of master drive_raddr");

    endtask


    // Drive the Read Data channel ready signal
    task drive_rdata(axi_xtn xtn);

        $display("Start of master drive_rdata");

        // Handle all read data beats in the burst
        for (int i = 0; i < xtn.ARLEN + 1; i++) begin

            vif.mst_drv_cb.RREADY <= 1;

            @(vif.mst_drv_cb);
            wait (vif.mst_drv_cb.RVALID);

            vif.mst_drv_cb.RREADY <= 0;

            repeat ($urandom_range(1, 5))
                @(vif.mst_drv_cb);

        end

        $display("End of master drive_rdata");

    endtask

endclass
