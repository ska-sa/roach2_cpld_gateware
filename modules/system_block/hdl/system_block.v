module system_block #(
    parameter REV_MAJOR = 0,
    parameter REV_MINOR = 0,
    parameter NUM_IRQ   = 2
  ) (
    input        wb_clk_i,
    input        wb_rst_i,
    input        wb_stb_i,
    input        wb_cyc_i,
    input        wb_we_i,
    input  [4:0] wb_adr_i,
    input  [7:0] wb_dat_i,
    output [7:0] wb_dat_o,
    output       wb_ack_o,

    input  [7:0] config_dip,
    input  [7:0] status,

    input  [3:0] irq_src,
    output       irq
  );

  localparam REG_DIP   = 0;
  localparam REG_STAT  = 1;
  localparam REG_MAJ   = 2;
  localparam REG_MIN   = 3;
  localparam REG_IRQM  = 6;
  localparam REG_IRQR  = 7;

  reg wb_ack_o_reg;

  always @(posedge wb_clk_i) begin
    wb_ack_o_reg <= wb_stb_i;
  end
  assign wb_ack_o = wb_ack_o_reg;

  wire  [7:0] rev_maj = REV_MAJOR;
  wire  [7:0] rev_min = REV_MINOR;

  reg [NUM_IRQ - 1:0] irq_m;
  reg [NUM_IRQ - 1:0] irq_r;

  reg [7:0] wb_dat_o_reg;
  always @(*) begin
    case (wb_adr_i[2:0])
      REG_DIP: begin
        wb_dat_o_reg <= config_dip;
      end
      REG_STAT: begin
        wb_dat_o_reg <= status;
      end
      REG_MAJ: begin
        wb_dat_o_reg <= rev_maj;
      end
      REG_MIN: begin
        wb_dat_o_reg <= rev_min;
      end
      REG_IRQM: begin
        wb_dat_o_reg <= irq_m;
      end
      REG_IRQR: begin
        wb_dat_o_reg <= irq_r;
      end
      default: begin
        wb_dat_o_reg  <= 8'd0;
      end
    endcase
  end
  assign wb_dat_o = wb_dat_o_reg;

  always @(posedge wb_clk_i) begin
    if (wb_rst_i) begin
      irq_r <= {NUM_IRQ{1'b0}};
      irq_m <= {NUM_IRQ{1'b0}};
    end else begin
      irq_r <= irq_src | irq_r;

      if (wb_stb_i && wb_cyc_i && wb_we_i) begin
        if (wb_adr_i[2:0] == REG_IRQM) begin
          irq_m <= wb_dat_i[NUM_IRQ-1:0];
        end
        if (wb_adr_i[2:0] == REG_IRQR) begin
          irq_r <= wb_dat_i[NUM_IRQ-1:0];
        end
      end
    end
  end

  assign irq = |(irq_r & irq_m);
endmodule
