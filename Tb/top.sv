module top;

        import uvm_pkg::*;
        import pkg::*;


        // Clock
        bit clock;

        // AXI Interface
        axi_if vif(clock);


        // Clock Generation
        always begin
                #5 clock = ~clock;
        end


        // UVM Configuration and Test Execution
        initial begin

                // Set virtual interface in UVM configuration database
                uvm_config_db#(virtual axi_if)::set(null, "*", "axi_if", vif);

                // Start UVM test
                run_test();

        end

endmodule
