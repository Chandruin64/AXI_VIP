//------------------------------------------------------------------------------
// Base sequence for AXI Master transactions
//------------------------------------------------------------------------------
class mst_base extends uvm_sequence #(axi_xtn);

    `uvm_object_utils(mst_base)

    // Constructor
    function new(string name = "mst_base");
        super.new(name);
    endfunction

endclass


//------------------------------------------------------------------------------
// AXI FIXED Burst Master Sequence
//------------------------------------------------------------------------------
class mst_fixed_seq extends mst_base;

    `uvm_object_utils(mst_fixed_seq)

    // Constructor
    function new(string name = "mst_fixed_seq");
        super.new(name);
    endfunction

    // Generate FIXED burst transactions
    task body();

        // Generate randomized FIXED burst transactions
        repeat (40) begin

            req = axi_xtn::type_id::create("req");

            start_item(req);

            assert(req.randomize() with {
                AWBURST == 2'b00;
                ARBURST == 2'b00;
            });

            finish_item(req);

        end

        // FIXED burst with specific write burst length
        req = axi_xtn::type_id::create("req");

        start_item(req);

        assert(req.randomize() with {
            AWBURST == 2'b00;
            ARBURST == 2'b00;
            AWLEN   == 8'd2;
        });

        finish_item(req);


        // FIXED burst with larger write burst length
        req = axi_xtn::type_id::create("req");

        start_item(req);

        assert(req.randomize() with {
            AWBURST == 2'b00;
            ARBURST == 2'b00;
            AWLEN   == 8'd4;
        });

        finish_item(req);

    endtask

endclass


//------------------------------------------------------------------------------
// AXI INCR Burst Master Sequence
//------------------------------------------------------------------------------
class mst_incr_seq extends mst_base;

    `uvm_object_utils(mst_incr_seq)

    // Constructor
    function new(string name = "mst_incr_seq");
        super.new(name);
    endfunction

    // Generate INCR burst transactions
    task body();

        // Generate randomized INCR burst transactions
        repeat (40) begin

            req = axi_xtn::type_id::create("req");

            start_item(req);

            assert(req.randomize() with {
                AWBURST == 2'b01;
                ARBURST == 2'b01;
            });

            finish_item(req);

        end

        // INCR burst with specific write and read burst lengths
        req = axi_xtn::type_id::create("req");

        start_item(req);

        assert(req.randomize() with {
            AWBURST == 2'b01;
            ARBURST == 2'b01;
            AWLEN   == 8'd14;
            ARLEN   == 8'd3;
        });

        finish_item(req);

    endtask

endclass


//------------------------------------------------------------------------------
// AXI WRAP Burst Master Sequence
//------------------------------------------------------------------------------
class mst_wrap_seq extends mst_base;

    `uvm_object_utils(mst_wrap_seq)

    // Constructor
    function new(string name = "mst_wrap_seq");
        super.new(name);
    endfunction

    // Generate WRAP burst transactions
    task body();

        // Generate randomized WRAP burst transactions
        repeat (40) begin

            req = axi_xtn::type_id::create("req");

            start_item(req);

            assert(req.randomize() with {
                AWBURST == 2'b10;
                ARBURST == 2'b10;
            });

            finish_item(req);

        end

    endtask

endclass
