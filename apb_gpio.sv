module apb_gpio (
// assume data size is 32

  input                         PRESETn,
                                PCLK,
  input                         PSEL,
  input                         PENABLE,
  input      [             3:0] PADDR,
  input                         PWRITE,
  input      [            3 :0] PSTRB,
  input      [            31:0] PWDATA,
  output reg [            31:0] PRDATA,
  output                        PREADY,
  output                        PSLVERR,

  output reg                    irq_o,

  input      [            31:0] gpio_i,
  output reg [            31:0] gpio_o,
                                gpio_oe
);


  localparam PADDR_SIZE = $bits(PADDR);


  localparam MODE      = 0,
             DIRECTION = 1,
             OUTPUT    = 2,
             INPUT     = 3,
             TR_TYPE   = 4,
             TR_LVL0   = 5,
             TR_LVL1   = 6,
             TR_STAT   = 7,
             IRQ_ENA   = 8;

  //number of synchronisation flipflop stages on GPIO inputs
  localparam INPUT_STAGES = 2;


  //////////////////////////////////////////////////////////////////
  //
  // Variables
  //

  //Control registers
  logic [31:0] mode_reg,
                         dir_reg,
                         out_reg,
                         in_reg,
                         tr_type_reg,
                         tr_lvl0_reg,
                         tr_lvl1_reg,
                         tr_stat_reg,
                         irq_ena_reg;

  //Trigger registers
  logic [31:0] tr_in_dly_reg,
                         tr_rising_edge_reg,
                         tr_falling_edge_reg,
                         tr_status;


  //Input register, to prevent metastability
  logic [31:0] input_regs [INPUT_STAGES];


  //////////////////////////////////////////////////////////////////
  //
  // Functions
  //

  //Is this a valid read access?
  function automatic is_read();
    return PSEL & PENABLE & ~PWRITE;
  endfunction : is_read

  //Is this a valid write access?
  function automatic is_write();
    return PSEL & PENABLE & PWRITE;
  endfunction : is_write

  //Is this a valid write to address 0x...?
  //Take 'address' as an argument
  function automatic is_write_to_adr(input [PADDR_SIZE-1:0] address);
    return is_write() & (PADDR == address);
  endfunction : is_write_to_adr

  //What data is written?
  //- Handles PSTRB, takes previous register/data value as an argument
  function automatic [31:0] get_write_value (input [31:0] orig_val);
    for (int n=0; n < 4; n=n+1)
       get_write_value[n*8 +: 8] = PSTRB[n] ? PWDATA[n*8 +: 8] : orig_val[n*8 +: 8];
  endfunction : get_write_value

  //Clear bits on write
  //- Handles PSTRB
  function automatic [31:0] get_clearonwrite_value (input [31:0] orig_val);
    for (int n=0; n < 4; n=n+1)
       get_clearonwrite_value[n*8 +: 8] = PSTRB[n] ? orig_val[n*8 +: 8] & ~PWDATA[n*8 +: 8] : orig_val[n*8 +: 8];
  endfunction : get_clearonwrite_value


  //////////////////////////////////////////////////////////////////
  //
  // Module Body
  //

  /*
   * APB accesses
   */
  //The core supports zero-wait state accesses on all transfers.
  //It is allowed to drive PREADY with a hard wired signal
  assign PREADY  = 1'b1; //always ready
  assign PSLVERR = 1'b0; //Never an error


  /*
   * APB Writes
   */
  //APB write to Mode register
  always @(posedge PCLK,negedge PRESETn)
    if      (!PRESETn              ) mode_reg <= {32{1'b0}};
    else if ( is_write_to_adr(MODE)) mode_reg <= get_write_value(mode_reg);


  //APB write to Direction register
  always @(posedge PCLK,negedge PRESETn)
    if      (!PRESETn                   ) dir_reg <= {32{1'b0}};
    else if ( is_write_to_adr(DIRECTION)) dir_reg <= get_write_value(dir_reg);


  //APB write to Output register
  //treat writes to Input register same
  always @(posedge PCLK,negedge PRESETn)
    if      (!PRESETn                  ) out_reg <= {32{1'b0}};
    else if ( is_write_to_adr(OUTPUT) ||
              is_write_to_adr(INPUT )  ) out_reg <= get_write_value(out_reg);


  //APB write to Trigger Type register
  always @(posedge PCLK,negedge PRESETn)
    if      (!PRESETn                 ) tr_type_reg <= {32{1'b0}};
    else if ( is_write_to_adr(TR_TYPE)) tr_type_reg <= get_write_value(tr_type_reg);


  //APB write to Trigger Level/Edge0 register
  always @(posedge PCLK,negedge PRESETn)
    if      (!PRESETn                 ) tr_lvl0_reg <= {32{1'b0}};
    else if ( is_write_to_adr(TR_LVL0)) tr_lvl0_reg <= get_write_value(tr_lvl0_reg);


  //APB write to Trigger Level/Edge1 register
  always @(posedge PCLK,negedge PRESETn)
    if      (!PRESETn                 ) tr_lvl1_reg <= {32{1'b0}};
    else if ( is_write_to_adr(TR_LVL1)) tr_lvl1_reg <= get_write_value(tr_lvl1_reg);


  //APB write to Trigger Status register
  //Writing a '1' clears the status register
  always @(posedge PCLK,negedge PRESETn)
    if      (!PRESETn                 ) tr_stat_reg <= {32{1'b0}};
    else if ( is_write_to_adr(TR_STAT)) tr_stat_reg <= get_clearonwrite_value(tr_stat_reg) | tr_status;
    else                                tr_stat_reg <= tr_stat_reg | tr_status;


  //APB write to Interrupt Enable register
  always @(posedge PCLK,negedge PRESETn)
    if      (!PRESETn                 ) irq_ena_reg <= {32{1'b0}};
    else if ( is_write_to_adr(IRQ_ENA)) irq_ena_reg <= get_write_value(irq_ena_reg);


  /*
   * APB Reads
   */
  always @(posedge PCLK)
    case (PADDR)
      MODE     : PRDATA <= mode_reg;
      DIRECTION: PRDATA <= dir_reg;
      OUTPUT   : PRDATA <= out_reg;
      INPUT    : PRDATA <= in_reg;
      TR_TYPE  : PRDATA <= tr_type_reg;
      TR_LVL0  : PRDATA <= tr_lvl0_reg;
      TR_LVL1  : PRDATA <= tr_lvl1_reg;
      TR_STAT  : PRDATA <= tr_stat_reg;
      IRQ_ENA  : PRDATA <= irq_ena_reg;
      default  : PRDATA <= {32{1'b0}};
    endcase


  /*
   * Internals
   */
  always @(posedge PCLK)
    for (int n=0; n<INPUT_STAGES; n= n+1)
       if (n==0) input_regs[n] <= gpio_i;
       else      input_regs[n] <= input_regs[n-1];

  always @(posedge PCLK)
    in_reg <= input_regs[INPUT_STAGES-1];


  // mode
  // 0=push-pull    drive out_reg value onto transmitter input
  // 1=open-drain   always drive '0' onto transmitter
  always @(posedge PCLK)
    for (int n=0; n<32; n=n+1)
      gpio_o[n] <= mode_reg[n] ? 1'b0 : out_reg[n];


  // direction  mode          out_reg
  // 0=input                           disable transmitter-enable (output enable)
  // 1=output   0=push-pull            always enable transmitter
  //            1=open-drain  1=Hi-Z   disable transmitter
  //                          0=low    enable transmitter
  always @(posedge PCLK)
    for (int n=0; n<32; n=n+1)
      gpio_oe[n] <= dir_reg[n] & ~(mode_reg[n] ? out_reg[n] : 1'b0);


  /*
   * Triggers
   */

  //delay input register
  always @(posedge PCLK)
    tr_in_dly_reg <= in_reg;


  //detect rising edge
  always @(posedge PCLK, negedge PRESETn)
    if (!PRESETn) tr_rising_edge_reg <= {32{1'b0}};
    else          tr_rising_edge_reg <= in_reg & ~tr_in_dly_reg;


  //detect falling edge
  always @(posedge PCLK, negedge PRESETn)
    if (!PRESETn) tr_falling_edge_reg <= {32{1'b0}};
    else          tr_falling_edge_reg <= tr_in_dly_reg & ~in_reg;


  //trigger status
  always_comb
    for (int n=0; n<32; n=n+1)
      case (tr_type_reg[n])
        0: tr_status[n] = (tr_lvl0_reg[n] & ~in_reg[n]) |
                          (tr_lvl1_reg[n] &  in_reg[n]);
        1: tr_status[n] = (tr_lvl0_reg[n] & tr_falling_edge_reg[n]) |
                          (tr_lvl1_reg[n] & tr_rising_edge_reg [n]);
      endcase


  /*
   * Interrupt
   */
  always @(posedge PCLK, negedge PRESETn)
    if (!PRESETn) irq_o <= 1'b0;
    else          irq_o <= |(irq_ena_reg & tr_stat_reg);
endmodule
