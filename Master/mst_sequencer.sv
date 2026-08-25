//------------------------------------------------------------------------------
// AXI Master Sequencer
//------------------------------------------------------------------------------
class mst_sequencer extends uvm_sequencer #(axi_xtn);

    `uvm_component_utils(mst_sequencer)

    // Constructor
    function new(string name = "mst_sequencer",
                 uvm_component parent);
        super.new(name, parent);
    endfunction

endclass
