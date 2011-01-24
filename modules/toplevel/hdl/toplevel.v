`include parameters.v
`include build_parameters.v

module toplevel(

     // ROACH 2 board power-on reset
     input          sys_por_n,
     // JTAG trst input
     input          sys_trst_n,
     // Board NVM write protect
     output         sys_wp_n,
     // Power-on reset force control
     output         por_force_n,
     // PowerPC JTAG reset 
     output         ppc_trst_n,

     // Disable boot configuration controls
     output         boot_cfg_dis_n,
     // Boot configuration controls
     output  [2:0]  boot_cfg,
     
     // Configuration DIP switches
     input   [7:0]  config_dip,
     
     // EPB Bus
     input          epb_perclk,
     input          epb_pcs_n,
     input          epb_poe_n,
     input          epb_pwr_n.
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
endmodule
