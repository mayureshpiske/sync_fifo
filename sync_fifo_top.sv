module sync_fifo_top #(
  parameter logic [31:0] FIFO_DEPTH = 32'd4,
  parameter logic [31:0] FIFO_WIDTH = 32'd8,
  parameter logic [31:0] ALMOST_FULL_DEPTH = FIFO_DEPTH - 1;
  parameter logic [31:0] ALMOST_EMPTY_DEPTH = 32'd1,
  parameter logic        EN_ALMOST_FLG = 1'b1,
  parameter logic        WR_MEM_NOT_RST_FLOPS = 1'b0
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

generate
  // write into memory
  if (WR_MEM_NON_RST_FLOPS) begin: wr_mem_non_rst_flops_1
     always_ff @(posedge clk or negedge rstn) begin
      if (wren && !full) begin
        mem[wr_ptr] <= wrdata;
      end  
     end
  end else begin : wr_mem_non_rst_flops_0  
     always_ff @(posedge clk or negedge rstn) begin
      if (!rstn) begin
        for (int i=0; i < FIFO_DEPTH; i++) begin : mem_fifo_rst
          mem[i]      <= '0;
        end : mem_fifo_rst
      end else if (wren && !full) begin
          mem[wr_ptr] <= wrdata;
      end  
  end
endgenerate

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
    assign full         = (fifo_cnt[PTR_WIDTH:0] == FIFO_DEPTH[PTR_WIDTH:0]);
    assign empty        = (fifo_cnt[PTR_WIDTH:0] == (PTR_WIDTH+1{1'b0}});
 
  generate
    if (EN_ALMOST_FLG) begin : en_almost_flag_1
        assign almost_full  = (fifo_cnt[PTR_WIDTH:0] >= ALMOST_FULL_DEPTH[PTR_WIDTH:0]);
        assign almost_empty = (fifo_cnt[PTR_WIDTH:0] <= ALMOST_EMPTY_DEPTH[PTR_WIDTH:0]);
    end else begin  : en_almost_flag_0
        assign almost_full  = 1'b0;
        assign almost_empty = 1'b0;
    end
  endgenerate

endmodule
  
  
  
