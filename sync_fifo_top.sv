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

// interanl signals
  logic [PTR_WIDTH:0]          rd_ptr;
  logic [PTR_WIDTH:0]          wr_ptr;
  logic [PTR_WIDTH:0]          fifo_cnt;
  logic [DATA_WIDTH-1:0]       r_rddata;

  // FIFO memory array
  logic [FIFO_WIDTH-1:0] mem [0:FIFO_DEPTH-1];
  
// write and read ptr
  always_ff @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      wr_ptr <= '0;
      rd_ptr <= '0;
    end else begin
      wr_ptr <= !full  ? PTR_WIDTH'(wr_ptr + {{(PTR_WIDTH-1){1'b0}},wren}) : wr_ptr;
      rd_ptr <= !empty ? PTR_WIDTH'(rd_ptr + {{(PTR_WIDTH-1){1'b0}},rden}) : rd_ptr;
    end
  end  

  // write into memory
  always_ff @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      for (int i=0; i < FIFO_DEPTH; i++) begin : mem_fifo_rst
        mem[i]      <= '0;
      end : mem_fifo_rst
    end else if (wren && !full) begin
        mem[wr_ptr] <= wrdata;
    end  
  end

// read from memory
  assign rddata = mem[rd_ptr];

// wr and rd enable wrt to full and empty
logic wr_en_t;
logic rd_en_t;

assign wr_en_t = wren && !full;
assign rd_en_t = rden && !empty;
// FIFO Count (Number of Occupied Entries)
  always_ff @(posedge clk or negedge rstn) begin
    if (!rstn)
      fifo_cnt <= '0;
    else begin
      // Update FIFO count based on write and read enables.
      case ({wr_en_t, rd_en_t})
        2'b10: fifo_cnt   <= PTR_WIDTH'(fifo_cnt + {{(PTR_WIDTH-1){1'b0}},wr_en_t});   // Write only
        2'b10: fifo_cnt   <= PTR_WIDTH'(fifo_cnt + {{(PTR_WIDTH-1){1'b0}},rd_en_t});   // Read only
        default: fifo_cnt <= fifo_cnt;      // Either both or none
      endcase
    end
  end

  // Status Flags: Full, Almost Full, Empty, Almost Empty
  assign full         = (fifo_cnt == FIFO_DEPTH);
  assign almost_full  = (fifo_cnt >= (FIFO_DEPTH - ALMOST_FULL_DEPTH));
  assign empty        = (fifo_cnt == 0);
  assign almost_empty = (fifo_cnt <= ALMOST_EMPTY_DEPTH);
  
endmodule
  
  
  
