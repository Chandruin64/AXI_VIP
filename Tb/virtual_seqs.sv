//------------------------------------------------------------------------------
// Base Virtual Sequence
//------------------------------------------------------------------------------
class virtual_seqs extends uvm_sequence #(uvm_sequence_item);

    `uvm_object_utils(virtual_seqs)

    // Virtual and physical sequencer handles
    virtual_sequencer vr_seqr;
    mst_sequencer     mst_seqr;
    slv_sequencer     slv_seqr;


    function new(string name = "virtual_seqs");
        super.new(name);
    endfunction


    task body();

        // Cast the generic m_sequencer to the virtual sequencer
        if (!$cast(vr_seqr, m_sequencer))
            `uvm_fatal("VIRTUAL SEQUENCER CASTING", "FAILED")

        // Get handles to the master and slave sequencers
        mst_seqr = vr_seqr.mst_seqr;

    endtask

endclass


//------------------------------------------------------------------------------
// Fixed Burst Virtual Sequence
//------------------------------------------------------------------------------
class fixed_vseq extends virtual_seqs;

    `uvm_object_utils(fixed_vseq)

    mst_fixed_seq mst;


  function new(string name = "fixed_vseq");
        super.new(name);
    endfunction


    task body();

        super.body();

        // Create and start the fixed burst sequence on the master sequencer
        repeat (1) begin
            mst = mst_fixed_seq::type_id::create("mst");
            mst.start(mst_seqr);
        end

        #1000;

    endtask

endclass


//------------------------------------------------------------------------------
// Incrementing Burst Virtual Sequence
//------------------------------------------------------------------------------
class incr_vseq extends virtual_seqs;

    `uvm_object_utils(incr_vseq)

    mst_incr_seq mst;


  function new(string name = "incr_vseq");
        super.new(name);
    endfunction


    task body();

        super.body();

        // Create and start the incrementing burst sequence
        // on the master sequencer
        repeat (1) begin
            mst = mst_incr_seq::type_id::create("mst");
            mst.start(mst_seqr);
        end

        #1000;

    endtask

endclass


//------------------------------------------------------------------------------
// Wrapping Burst Virtual Sequence
//------------------------------------------------------------------------------
class wrap_vseq extends virtual_seqs;

    `uvm_object_utils(wrap_vseq)

    mst_wrap_seq mst;


  function new(string name = "wrap_vseq");
        super.new(name);
    endfunction


    task body();

        super.body();

        // Create and start the wrapping burst sequence
        // on the master sequencer
        repeat (1) begin
            mst = mst_wrap_seq::type_id::create("mst");
            mst.start(mst_seqr);
        end

        #1000;

    endtask

endclass
