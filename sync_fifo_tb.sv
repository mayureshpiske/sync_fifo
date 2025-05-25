`timescale 1ns / 1ps

module sync_fifo_tb;

  // Parameters
  parameter FIFO_DEPTH = 8;
  parameter FIFO_WIDTH = 8;

  // Clock and reset
  logic clk;
  logic rstn;

  // Inputs
  logic wren;
  logic rden;
  logic [FIFO_WIDTH-1:0] wrdata;

  // Outputs
  logic [FIFO_WIDTH-1:0] rddata;
  logic full;
  logic almost_full;
  logic empty;
  logic almost_empty;

  // DUT instantiation
  sync_fifo_top #(
    .FIFO_DEPTH(FIFO_DEPTH),
    .FIFO_WIDTH(FIFO_WIDTH)
  ) dut (
    .clk(clk),
    .rstn(rstn),
    .wren(wren),
    .wrdata(wrdata),
    .rden(rden),
    .rddata(rddata),
    .full(full),
    .almost_full(almost_full),
    .empty(empty),
    .almost_empty(almost_empty)
  );

  // Clock generation
  initial clk = 0;
  always #5 clk = ~clk; // 100MHz clock

  // Test sequence
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, sync_fifo_tb); // Or use (1, dut) to limit scope
    $display("Starting FIFO testbench...");
    
    // Initialize inputs
    wren   = 0;
    rden   = 0;
    wrdata = 0;
    rstn   = 0;

    // Apply reset
    #20;
    rstn = 1;

    // Write to FIFO
    repeat (FIFO_DEPTH) begin
      @(posedge clk);
      wren   = 1;
      wrdata = $random;
    end
    @(posedge clk);
    wren = 0;

    // Wait a cycle
    #10;

    // Read from FIFO
    repeat (FIFO_DEPTH) begin
      @(posedge clk);
      rden = 1;
    end
    @(posedge clk);
    rden = 0;

    // Finish
    #20;
    $display("FIFO testbench completed.");
    $finish;
  end

  // Monitor
  always @(posedge clk) begin
    $display("Time: %0t | wr_en=%0b rd_en=%0b wrdata=%0h rddata=%0h full=%0b empty=%0b",
             $time, wren, rden, wrdata, rddata, full, empty);
  end

endmodule
