`include "parameters.v"
`include "build_parameters.v"

module toplevel(
     // ROACH 2 board power-on reset
     input          sys_por_n,
     // JTAG trst input
     input          sys_trst_n,
     // Board NVM write protect
     output         sys_wp_n,
     // Power-on reset force control
     output         por_force_n,

     // Disable boot configuration controls
     output         boot_cfg_dis_n,
     // Boot configuration controls
     output  [2:0]  boot_cfg,
     
     // Configuration DIP switches
     input   [7:0]  config_dip,
     // CPLD status LED
     output         led_n,
     
     // EPB Bus
     input          epb_perclk,
     input          epb_pcs_n,
     input          epb_poe_n,
     input          epb_pwr_n,
     input  [26:31] epb_paddr,
     inout   [0:7]  epb_pdata,
     output         epb_prdy,
     
     // MMC signals
     output         mmc_clk,
     inout          mmc_cmd,
     inout   [3:0]  mmc_dat,
     input          mmc_wp_n,
     input          mmc_cd_n,
     // Power control on MMC
     output         mmc_pwron_n,
     
     // PPC IRQ (mmc controller related)
     output         cpld_irq_n,

     // MMC DMA signals
     inout          mmc_dmaack,
     inout          mmc_dmaeot,
     inout          mmc_dmareq,
     
     // Flash busy signal
     input          flash_busy_n
  );

  /************************ Resets ****************************/

  /* system wide reset */
  wire sys_reset = !(sys_por_n);

  assign por_force_n = 1'bz;

  /******************* Fixed Assignments **********************/

  assign led_n = 1'b0;
  
  assign boot_cfg_dis_n = 1'b1; // Always enabled
  assign boot_cfg       = config_dip[0] == 1'b1 ? 3'b010 : //boot option C (default)
                                                  3'b101;  //boot option G (eeprom)
  assign sys_wp_n    = 1'b1;

  assign mmc_pwron_n = 1'b1; /* TODO: add to controller memory */
  assign mmc_dmaack = 1'b0; /* TODO: make mmc DMA ready */
  assign mmc_dmaeot = 1'b0;
  assign mmc_dmareq = 1'b0;

  /**************** PPC External Peripheral Bus ****************/

  wire wb_clk_i = epb_perclk;
  //synthesis attribute BUFG of epb_perclk is CLK
  wire wb_rst_i = sys_reset;

  wire       epb_pdata_oe;
  wire [7:0] epb_pdata_i;
  wire [7:0] epb_pdata_o;

  /* Tri-state control for data bus */
  OBUFE OBUFE_pdata[7:0](
    .E(epb_pdata_oe), .I(epb_pdata_i), .O(epb_pdata)
  );

  IBUF IBUF_pdata[7:0](
    .I(epb_pdata), .O(epb_pdata_o)
  );

  wire epb_prdy_o;
  wire epb_prdy_oe;

  /* Tri-state control for prdy bus */

  OBUFE OBUFE_prdy(
    .E(epb_prdy_oe), .I(epb_prdy_o), .O(epb_prdy)
  );

  wire       wb_stb_o;
  wire       wb_we_o;
  wire       wb_sel_o;
  wire [4:0] wb_adr_o;
  wire [7:0] wb_dat_o;
  wire [7:0] wb_dat_i;
  wire       wb_ack_i;

  epb_wb_bridge epb_wb_bridge_inst (
    .clk   (wb_clk_i),
    .reset (wb_rst_i),

    .epb_cs_n    (epb_pcs_n),
    .epb_oe_n    (epb_poe_n),
    .epb_we_n    (epb_pwr_n),
    .epb_be_n    (1'b0),
    .epb_addr    (epb_paddr),
    .epb_data_i  (epb_pdata_o),
    .epb_data_o  (epb_pdata_i),
    .epb_data_oe (epb_pdata_oe),
    .epb_rdy_o   (epb_prdy_o),
    .epb_rdy_oe  (epb_prdy_oe),

    .wb_cyc_o (),
    .wb_stb_o (wb_stb_o),
    .wb_we_o  (wb_we_o),
    .wb_sel_o (wb_sel_o),
    .wb_adr_o (wb_adr_o),
    .wb_dat_o (wb_dat_o),
    .wb_dat_i (wb_dat_i),
    .wb_ack_i (wb_ack_i)
  );

  /* V basic wishbone arbitration */
  wire wb_stb_o_0 = wb_stb_o && wb_adr_o[4] == 2'b0;
  wire wb_stb_o_1 = wb_stb_o && wb_adr_o[4] == 2'b1;

  wire wb_cyc_o_0 = wb_stb_o_0;
  wire wb_cyc_o_1 = wb_stb_o_1;

  wire [3:0] wb_adr_o_0 = wb_adr_o[3:0];
  wire [3:0] wb_adr_o_1 = wb_adr_o[3:0];

  wire [7:0] wb_dat_i_0;
  wire [7:0] wb_dat_i_1;

  assign wb_dat_i = wb_adr_o[4] ? wb_dat_i_1 : wb_dat_i_0;

  wire wb_ack_i_0;
  wire wb_ack_i_1;
  assign wb_ack_i = wb_ack_i_1 | wb_ack_i_0;

  /*********************** Revision Control Info *************************/

  localparam NUM_IRQ = 4;

  wire [NUM_IRQ - 1:0] irq_src;

  wire ppc_irq;
  system_block #(
    .REV_MAJOR (`REV_MAJOR),
    .REV_MINOR (`REV_MINOR),
    .NUM_IRQ   (NUM_IRQ)
  ) system_block (
    .wb_clk_i   (wb_clk_i),
    .wb_rst_i   (wb_rst_i),
    .wb_stb_i   (wb_stb_o_1),
    .wb_cyc_i   (wb_cyc_o_1),
    .wb_we_i    (wb_we_o),
    .wb_adr_i   (wb_adr_o_1),
    .wb_dat_i   (wb_dat_o),
    .wb_dat_o   (wb_dat_i_1),
    .wb_ack_o   (wb_ack_i_1),
    .config_dip (config_dip),
    .status     ({3'b0, mmc_wp_n, 3'b0, mmc_cd_n}),
    .irq_src    (irq_src),
    .irq        (ppc_irq)
  );
  assign cpld_irq_n = !ppc_irq;
  
  /************** MMC Interfaces **************/

  wire       mmc_cmd_o;
  wire       mmc_cmd_i;
  wire       mmc_cmd_oe;

  wire [3:0] mmc_data_o;
  wire [3:0] mmc_data_i;
  wire       mmc_data_oe;

  mmc_infrastructure mmc_infrastructure_inst(
    /* external signals */
    .mmc_cmd     (mmc_cmd),
    .mmc_data    (mmc_dat),
    /* internal signals */
    .mmc_cmd_i   (mmc_cmd_o),
    .mmc_cmd_o   (mmc_cmd_i),
    .mmc_cmd_oe  (mmc_cmd_oe),
    .mmc_data_i  (mmc_data_o),
    .mmc_data_o  (mmc_data_i),
    .mmc_data_oe (mmc_data_oe)
  );

  mmc_controller mmc_controller (
    .wb_clk_i (wb_clk_i),
    .wb_rst_i (wb_rst_i),
    .wb_cyc_i (wb_cyc_o_0),
    .wb_stb_i (wb_stb_o_0),
    .wb_we_i  (wb_we_o),
    .wb_adr_i (wb_adr_o_0),
    .wb_dat_i (wb_dat_o),
    .wb_dat_o (wb_dat_i_0),
    .wb_ack_o (wb_ack_i_0),

    .mmc_clk      (mmc_clk),
    .mmc_cmd_o    (mmc_cmd_o),
    .mmc_cmd_i    (mmc_cmd_i),
    .mmc_cmd_oe   (mmc_cmd_oe),
    .mmc_dat_i    (mmc_data_i),
    .mmc_dat_o    (mmc_data_o),
    .mmc_dat_oe   (mmc_data_oe),
    .mmc_cdetect  (mmc_cd_n),
    
    .irq_cdetect  (irq_src[0]),
    .irq_got_cmd  (irq_src[2]),
    .irq_got_dat  (irq_src[3]),
    .irq_got_busy (irq_src[1])
  );

endmodule
