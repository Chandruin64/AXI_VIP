```systemverilog
class axi_xtn extends uvm_sequence_item;

    `uvm_object_utils(axi_xtn)

    //============================================================
    // Global Signals
    //============================================================
    bit ARESETn;

    //============================================================
    // Write Address Channel
    //============================================================
    rand bit [3:0]  AWID;
    rand bit [31:0] AWADDR;
    rand bit [7:0]  AWLEN;
    rand bit [2:0]  AWSIZE;
    rand bit [1:0]  AWBURST;

    bit   AWVALID;
    logic AWREADY;

    //============================================================
    // Write Data Channel
    //============================================================
    rand bit [3:0]  WID;
    rand bit [31:0] WDATA [];
    bit  [3:0]      WSTRB [];

    logic WLAST;
    logic WVALID;
    logic WREADY;

    //============================================================
    // Write Response Channel
    //============================================================
    rand bit [3:0] BID;
    bit  [1:0]     BRESP;

    logic BVALID;
    logic BREADY;

    //============================================================
    // Read Address Channel
    //============================================================
    rand bit [3:0]  ARID;
    rand bit [31:0] ARADDR;
    rand bit [7:0]  ARLEN;
    rand bit [2:0]  ARSIZE;
    rand bit [1:0]  ARBURST;

    bit   ARVALID;
    logic ARREADY;

    //============================================================
    // Read Data Channel
    //============================================================
    rand bit [3:0]  RID;
    rand bit [31:0] RDATA [];
    bit  [1:0]      RRESP [];

    logic RLAST;
    logic RVALID;
    logic RREADY;

    //============================================================
    // Write Address Calculation Variables
    //============================================================
    bit [31:0] addr [];
    int no_bytes;
    int aligned_addr;
    int start_addr;

    //============================================================
    // Read Address Calculation Variables
    //============================================================
    bit [31:0] raddr [];
    int no_rbytes;
    int aligned_raddr;
    int start_raddr;

    //============================================================
    // Randomization Constraints
    //============================================================

    // Data array size corresponds to burst length
    constraint wdata_c {
        WDATA.size() == AWLEN + 1;
    }

    constraint rdata_c {
        RDATA.size() == ARLEN + 1;
    }

    // Burst type distribution:
    // FIXED = 0, INCR = 1, WRAP = 2
    constraint wburst {
        AWBURST dist {0 := 10, 1 := 10, 2 := 10};
    }

    constraint rburst {
        ARBURST dist {0 := 10, 1 := 10, 2 := 10};
    }

    // Maintain ID consistency across dependent channels
    constraint write_id {
        WID == AWID;
        BID == WID;
    }

    constraint read_id {
        ARID == RID;
    }

    // Transfer size distribution
    constraint wsize {
        AWSIZE dist {0 := 10, 1 := 10, 2 := 10};
    }

    constraint rsize {
        ARSIZE dist {0 := 10, 1 := 10, 2 := 10};
    }

    // Burst length limited to 16 transfers
    constraint wlen {
        AWLEN inside {[0:15]};
    }

    constraint rlen {
        ARLEN inside {[0:15]};
    }

    // WRAP bursts support 2, 4, 8 or 16 transfers
    constraint wwrap {
        (AWBURST == 2'b10) ->
        AWLEN + 1 inside {2, 4, 8, 16};
    }

    constraint rwrap {
        (ARBURST == 2'b10) ->
        ARLEN + 1 inside {2, 4, 8, 16};
    }

    // Address alignment constraints
    constraint walign1 {
        ((AWBURST == 2'b10 || AWBURST == 2'b00) &&
         AWSIZE == 1) -> (AWADDR % 2 == 0);
    }

    constraint walign2 {
        ((AWBURST == 2'b10 || AWBURST == 2'b00) &&
         AWSIZE == 2) -> (AWADDR % 4 == 0);
    }

    constraint ralign1 {
        ((ARBURST == 2'b10 || ARBURST == 2'b00) &&
         ARSIZE == 1) -> (ARADDR % 2 == 0);
    }

    constraint ralign2 {
        ((ARBURST == 2'b10 || ARBURST == 2'b00) &&
         ARSIZE == 2) -> (ARADDR % 4 == 0);
    }

    // Limit total burst transfer size to below 4KB
    constraint wmax_limit {
        ((2**AWSIZE) * (AWLEN + 1)) < 4096;
    }

    constraint rmax_limit {
        ((2**ARSIZE) * (ARLEN + 1)) < 4096;
    }

    //============================================================
    // Constructor
    //============================================================
    function new(string name = "axi_xtn");
        super.new(name);
    endfunction

    //============================================================
    // Print Transaction
    //============================================================
    function void do_print(uvm_printer printer);

        super.do_print(printer);

        printer.print_field("ARESETn", ARESETn, 1, UVM_BIN);

        // Write Address Channel
        printer.print_field("AWID",    AWID,    4, UVM_DEC);
        printer.print_field("AWADDR",  AWADDR,  32, UVM_HEX);
        printer.print_field("AWLEN",   AWLEN,   8, UVM_DEC);
        printer.print_field("AWSIZE",  AWSIZE,  3, UVM_DEC);
        printer.print_field("AWBURST", AWBURST, 2, UVM_DEC);

        // Write Data Channel
        printer.print_field("WID", WID, 4, UVM_DEC);

        foreach (WDATA[i]) begin
            printer.print_field("WDATA", WDATA[i], 32, UVM_HEX);
            printer.print_field("WSTRB", WSTRB[i], 4, UVM_BIN);
            printer.print_field("WLAST", WLAST, 1, UVM_DEC);
        end

        // Write Response Channel
        printer.print_field("BID",   BID,   4, UVM_DEC);
        printer.print_field("BRESP", BRESP, 2, UVM_DEC);

        // Read Address Channel
        printer.print_field("ARID",    ARID,    4, UVM_DEC);
        printer.print_field("ARADDR",  ARADDR,  32, UVM_HEX);
        printer.print_field("ARLEN",   ARLEN,   8, UVM_DEC);
        printer.print_field("ARSIZE",  ARSIZE,  3, UVM_DEC);
        printer.print_field("ARBURST", ARBURST, 2, UVM_DEC);

        // Read Data Channel
        printer.print_field("RID", RID, 4, UVM_DEC);

        foreach (RDATA[i]) begin
            printer.print_field("RDATA", RDATA[i], 32, UVM_HEX);
            printer.print_field("RRESP", RRESP[i], 2, UVM_DEC);
            printer.print_field("RLAST", RLAST, 1, UVM_DEC);
        end

    endfunction

    //============================================================
    // Compare Transactions
    //============================================================
    function bit do_compare(uvm_object rhs, uvm_comparer comparer);

        axi_xtn rhs_;
        bit result;

        if (!$cast(rhs_, rhs))
            `uvm_fatal("OBJECT CASTING", "FAILED")

        result = super.do_compare(rhs, comparer);

        if (WDATA.size() !== 0) begin

            result &= AWID    == rhs_.AWID &&
                      AWADDR  == rhs_.AWADDR &&
                      AWLEN   == rhs_.AWLEN &&
                      AWSIZE  == rhs_.AWSIZE &&
                      AWBURST == rhs_.AWBURST &&
                      WID     == rhs_.WID &&
                      WDATA   == rhs_.WDATA &&
                      WSTRB   == rhs_.WSTRB &&
                      BID     == rhs_.BID &&
                      BRESP   == rhs_.BRESP;

        end

        result &= ARID    == rhs_.ARID &&
                  ARADDR  == rhs_.ARADDR &&
                  ARLEN   == rhs_.ARLEN &&
                  ARSIZE  == rhs_.ARSIZE &&
                  ARBURST == rhs_.ARBURST &&
                  RID     == rhs_.RID &&
                  RDATA   == rhs_.RDATA &&
                  RRESP   == rhs_.RRESP;

        return result;

    endfunction

    //============================================================
    // Post-Randomization Processing
    //============================================================
    function void post_randomize();

        no_bytes     = 2**AWSIZE;
        aligned_addr = (int'(AWADDR / no_bytes)) * no_bytes;
        start_addr   = AWADDR;

        WSTRB = new[AWLEN + 1];

        no_rbytes     = 2**ARSIZE;
        aligned_raddr = (int'(ARADDR / no_rbytes)) * no_rbytes;
        start_raddr   = ARADDR;

        cal_addr();
        strb_cal();
        cal_raddr();

    endfunction

    //============================================================
    // Calculate Write Burst Addresses
    //============================================================
    function void cal_addr();

        bit wb;

        int burst_len;
        int wrap_boundary;

        burst_len    = AWLEN + 1;
        wrap_boundary = (int'(AWADDR / (no_bytes * burst_len)))
                        * (no_bytes * burst_len);

        addr = new[AWLEN + 1];
        addr[0] = AWADDR;

        for (int i = 2; i < (burst_len + 1); i++) begin

            if (AWBURST == 0)
                addr[i-1] = AWADDR;

            if (AWBURST == 1)
                addr[i-1] = aligned_addr + (i-1) * no_bytes;

            if (AWBURST == 2) begin

                if (wb == 0) begin

                    addr[i-1] = aligned_addr + (i-1) * no_bytes;

                    if (addr[i-1] ==
                        (wrap_boundary + (no_bytes * burst_len))) begin

                        addr[i-1] = wrap_boundary;
                        wb++;
                    end

                end
                else begin

                    addr[i-1] = start_addr +
                                ((i-1) * no_bytes) -
                                (no_bytes * burst_len);

                end

            end

        end

    endfunction

    //============================================================
    // Calculate Write Strobe Values
    //============================================================
    function void strb_cal();

        int data_bus_bytes = 4;
        int lower_byte_lane;
        int upper_byte_lane;

        int lower_byte_lane_0 =
            start_addr -
            ((int'(start_addr / data_bus_bytes)) * data_bus_bytes);

        int upper_byte_lane_0 =
            (aligned_addr + (no_bytes - 1)) -
            ((int'(start_addr / data_bus_bytes)) * data_bus_bytes);

        for (int i = lower_byte_lane_0;
                 i <= upper_byte_lane_0;
                 i++)
            WSTRB[0][i] = 1;

        for (int i = 1; i < (AWLEN + 1); i++) begin

            lower_byte_lane =
                addr[i] -
                ((int'(addr[i] / data_bus_bytes)) * data_bus_bytes);

            upper_byte_lane =
                lower_byte_lane + no_bytes - 1;

            for (int j = lower_byte_lane;
                     j <= upper_byte_lane;
                     j++)
                WSTRB[i][j] = 1;

        end

    endfunction

    //============================================================
    // Calculate Read Burst Addresses
    //============================================================
    function void cal_raddr();

        bit wb;

        int burst_len;
        int wrap_boundary;

        burst_len    = ARLEN + 1;
        wrap_boundary = (int'(ARADDR / (no_rbytes * burst_len)))
                        * (no_rbytes * burst_len);

        raddr = new[ARLEN + 1];

        raddr[0] = ARADDR;

        for (int i = 2; i < (burst_len + 1); i++) begin

            if (ARBURST == 0)
                raddr[i-1] = ARADDR;

            if (ARBURST == 1)
                raddr[i-1] =
                    aligned_raddr + (i-1) * no_rbytes;

            if (ARBURST == 2) begin

                if (wb == 0) begin

                    raddr[i-1] =
                        aligned_raddr + (i-1) * no_rbytes;

                    if (raddr[i-1] ==
                        (wrap_boundary + (no_rbytes * burst_len))) begin

                        raddr[i-1] = wrap_boundary;
                        wb++;

                    end

                end
                else begin

                    raddr[i-1] =
                        start_raddr +
                        ((i-1) * no_rbytes) -
                        (no_rbytes * burst_len);

                end

            end

        end

    endfunction

endclass
```
