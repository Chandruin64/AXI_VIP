class virtual_sequencer extends uvm_sequencer #(uvm_sequence_item);

        `uvm_component_utils(virtual_sequencer)

        // Handles master-side sequences
        mst_sequencer mst_seqr;

        // Constructor
        function new (string name = "virtual_sequencer",
                      uvm_component parent);
                super.new(name, parent);
        endfunction

endclass
