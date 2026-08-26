interface axi_if(input bit clock);

        // ------------------------------------------------------------
        // Global Signals
        // ------------------------------------------------------------
        bit   ACLK;
        logic ARESETn;


        // ------------------------------------------------------------
        // Write Address Channel
        // ------------------------------------------------------------
        logic [3:0]  AWID;
        logic [31:0] AWADDR;
        logic [7:0]  AWLEN;
        logic [2:0]  AWSIZE;
        logic [1:0]  AWBURST;
        logic        AWVALID;
        logic        AWREADY;


        // ------------------------------------------------------------
        // Write Data Channel
        // ------------------------------------------------------------
        logic [3:0]  WID;
        logic [31:0] WDATA;
        logic [3:0]  WSTRB;
        logic        WLAST;
        logic        WVALID;
        logic        WREADY;


        // ------------------------------------------------------------
        // Write Response Channel
        // ------------------------------------------------------------
        logic [3:0] BID;
        logic [1:0] BRESP;
        logic       BVALID;
        logic       BREADY;


        // ------------------------------------------------------------
        // Read Address Channel
        // ------------------------------------------------------------
        logic [3:0]  ARID;
        logic [31:0] ARADDR;
        logic [7:0]  ARLEN;
        logic [2:0]  ARSIZE;
        logic [1:0]  ARBURST;
        logic        ARVALID;
        logic        ARREADY;


        // ------------------------------------------------------------
        // Read Data Channel
        // ------------------------------------------------------------
        logic [3:0]  RID;
        logic [31:0] RDATA;
        logic [1:0]  RRESP;
        logic        RLAST;
        logic        RVALID;
        logic        RREADY;


        // Assign interface clock
        assign ACLK = clock;


        // ------------------------------------------------------------
        // Master Driver Clocking Block
        // ------------------------------------------------------------
        clocking mst_drv_cb @(posedge clock);

                default input #1 output #1;

                // Inputs driven by slave
                input AWREADY;
                input WREADY;
                input BID, BRESP, BVALID;
                input ARREADY;
                input RID, RDATA, RRESP, RLAST, RVALID;

                // Outputs driven by master
                output ARESETn, AWID, AWADDR, AWLEN, AWSIZE;
                output AWBURST, AWVALID;

                output WID, WDATA, WSTRB, WLAST, WVALID;

                output BREADY;

                output ARID, ARADDR, ARLEN, ARSIZE;
                output ARBURST, ARVALID;

                output RREADY;

        endclocking


        // ------------------------------------------------------------
        // Master Monitor Clocking Block
        // ------------------------------------------------------------
        clocking mst_mon_cb @(posedge clock);

                default input #1 output #1;

                input ARESETn, AWID, AWADDR, AWLEN, AWSIZE;
                input AWBURST, AWVALID, AWREADY;

                input WID, WDATA, WSTRB, WLAST, WVALID, WREADY;

                input BID, BRESP, BVALID, BREADY;

                input ARID, ARADDR, ARLEN, ARSIZE;
                input ARBURST, ARVALID, ARREADY;

                input RID, RDATA, RRESP, RLAST, RVALID, RREADY;

        endclocking


        // ------------------------------------------------------------
        // Slave Driver Clocking Block
        // ------------------------------------------------------------
        clocking slv_drv_cb @(posedge clock);

                default input #1 output #1;

                // Inputs driven by master
                input ARESETn, AWID, AWADDR, AWLEN, AWSIZE;
                input AWBURST, AWVALID;

                input WID, WDATA, WSTRB, WLAST, WVALID;

                input BREADY;

                input ARID, ARADDR, ARLEN, ARSIZE;
                input ARBURST, ARVALID;

                input RREADY;

                // Outputs driven by slave
                output AWREADY;

                output WREADY;

                output BID, BRESP, BVALID;

                output ARREADY;

                output RID, RDATA, RRESP, RLAST, RVALID;

        endclocking


        // ------------------------------------------------------------
        // Slave Monitor Clocking Block
        // ------------------------------------------------------------
        clocking slv_mon_cb @(posedge clock);

                default input #1 output #1;

                input ARESETn, AWID, AWADDR, AWLEN, AWSIZE;
                input AWBURST, AWVALID, AWREADY;

                input WID, WDATA, WSTRB, WLAST, WVALID, WREADY;

                input BID, BRESP, BVALID, BREADY;

                input ARID, ARADDR, ARLEN, ARSIZE;
                input ARBURST, ARVALID, ARREADY;

                input RID, RDATA, RRESP, RLAST, RVALID, RREADY;

        endclocking


        // ------------------------------------------------------------
        // Modports
        // ------------------------------------------------------------
        modport MST_DRV(clocking mst_drv_cb);
        modport MST_MON(clocking mst_mon_cb);

        modport SLV_DRV(clocking slv_drv_cb);
        modport SLV_MON(clocking slv_mon_cb);


        // ============================================================
        // Assertions
        // ============================================================

        // ------------------------------------------------------------
        // VALID signal stability checks
        // ------------------------------------------------------------

        // Write address signals must remain stable until AWREADY
        property awvalid;
                @(posedge clock)
                $rose(AWVALID) |->
                $stable(AWLEN) &&
                $stable(AWBURST) &&
                $stable(AWSIZE) &&
                $stable(AWADDR)
                until AWREADY[->1];
        endproperty


        // Write data signals must remain stable until WREADY
        property valid;
                @(posedge clock)
                $rose(WVALID) |->
                $stable(WID) &&
                $stable(WDATA) &&
                $stable(WSTRB) &&
                $stable(WLAST)
                until WREADY[->1];
        endproperty


        // Read address signals must remain stable until ARREADY
        property arvalid;
                @(posedge clock)
                $rose(ARVALID) |->
                $stable(ARLEN) &&
                $stable(ARBURST) &&
                $stable(ARSIZE) &&
                $stable(ARADDR)
                until ARREADY[->1];
        endproperty


        assert property (awvalid);
        assert property (valid);
        assert property (arvalid);


        // ------------------------------------------------------------
        // Response and read data stability checks
        // ------------------------------------------------------------

        // Write response signals must remain stable until BREADY
        property bvalid;
                @(posedge clock)
                $rose(BVALID) |->
                $stable(BID) &&
                $stable(BRESP)
                until BREADY[->1];
        endproperty


        // Read data signals must remain stable until RREADY
        property rvalid;
                @(posedge clock)
                $rose(RVALID) |->
                $stable(RID) &&
                $stable(RDATA) &&
                $stable(RLAST) &&
                $stable(RLAST) &&
                $stable(RRESP)
                until RREADY[->1];
        endproperty


        assert property (bvalid);
        assert property (rvalid);


        // ------------------------------------------------------------
        // VALID persistence checks
        // ------------------------------------------------------------

        property awvalid_awready;
                @(posedge clock)
                AWVALID && !AWREADY |=> AWVALID;
        endproperty


        property wvalid_wready;
                @(posedge clock)
                WVALID && !WREADY |=> WVALID;
        endproperty


        property arvalid_arready;
                @(posedge clock)
                ARVALID && !ARREADY |=> ARVALID;
        endproperty


        assert property (awvalid_awready);
        assert property (wvalid_wready);
        assert property (arvalid_arready);


        // ------------------------------------------------------------
        // Response VALID persistence checks
        // ------------------------------------------------------------

        property bvalid_bready;
                @(posedge clock)
                BVALID && !BREADY |=> BVALID;
        endproperty


        property rvalid_rready;
                @(posedge clock)
                RVALID && !RREADY |=> RVALID;
        endproperty


        assert property (bvalid_bready);
        assert property (rvalid_rready);


        // ------------------------------------------------------------
        // WRAP burst address alignment checks
        // ------------------------------------------------------------

        property R_wrap_type;
                @(posedge clock)
                (ARBURST == 2) |-> (ARSIZE == 1) |-> (ARADDR % 2 == 0);
        endproperty


        property R_wrap_type1;
                @(posedge clock)
                (ARBURST == 2) |-> (ARSIZE == 2) |-> (ARADDR % 4 == 0);
        endproperty


        property W_wrap_type;
                @(posedge clock)
                (AWBURST == 2) |-> (AWSIZE == 1) |-> (AWADDR % 2 == 0);
        endproperty


        property W_wrap_type1;
                @(posedge clock)
                (AWBURST == 2) |-> (AWSIZE == 2) |-> (AWADDR % 4 == 0);
        endproperty


        assert property (R_wrap_type);
        assert property (R_wrap_type1);
        assert property (W_wrap_type);
        assert property (W_wrap_type1);


        // ------------------------------------------------------------
        // Transfer size checks
        // ------------------------------------------------------------

        property ar_size;
                @(posedge clock)
                ARVALID |-> (ARSIZE < 3);
        endproperty


        property aw_size;
                @(posedge clock)
                AWVALID |-> (AWSIZE < 3);
        endproperty


        assert property (ar_size);
        assert property (aw_size);

endinterface
