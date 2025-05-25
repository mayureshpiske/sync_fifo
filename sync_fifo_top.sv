module sync_fifo_top #(
  parameter logic [31:0] FIFO_DEPTH = 32'd4,
  parameter logic [31:0] FIFO_WIDTH = 32'd8,
  parameter logic [31:0] ALMOST_FULL_DEPTH = FIFO_DEPTH - 1;
  parameter logic [31:0] ALMOST_EMPTY_DEPTH = 32'd1
) (
  // input signals
  input logic                   clk,
  input logic                   rstn, //active low
  input logic                   wren,
  input logic  [FIFO_WIDTH-1:0] wrdata,
  input logic                   rden,
  // output signals
  output logic [FIFO_WIDTH-1:0] rddata;
  output logic                  full,
  output logic                  almost_full,
  output logic                  empty,
  output logic                  almost_empty
);

// localparam
  localparam  PTR_WIDTH = $clog2(FIFO_DEPTH);

// Interanl signals
  logic [PTR_WIDTH:0]          rd_ptr;
  logic [PTR_WIDTH:0]          wr_ptr;
  
  
  
