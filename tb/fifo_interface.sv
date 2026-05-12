interface fifo_if (input wr_clk, input rd_clk);
    logic wr_rstn, rd_rstn;
    logic wr_en, rd_en;
    logic [31:0] wdata;
    logic [31:0] rdata;
    logic full, empty;

    clocking wr_cb @(posedge wr_clk);
        output wr_en;
        output wdata;
        input  full;
    endclocking

    clocking rd_cb @(posedge rd_clk);
        output rd_en;
        input  rdata;
        input  empty;
    endclocking

    clocking wr_mon_cb @(posedge wr_clk);
        input wr_en;
        input wdata;
        input full;
    endclocking

    clocking rd_mon_cb @(posedge rd_clk);
        input rd_en;
        input rdata;
        input empty;
    endclocking

    modport WRITE_DRV (clocking wr_cb, output wr_rstn, input wr_clk);
    modport READ_DRV  (clocking rd_cb, output rd_rstn, input rd_clk);
    modport WR_MON    (clocking wr_mon_cb, input wr_clk);
    modport RD_MON    (clocking rd_mon_cb, input rd_clk);

   
    // SYSTEMVERILOG ASSERTIONS

    
    // 1. Write Domain Check: Never write if the FIFO was full last cycle
    property p_no_wr_on_full;
        @(posedge wr_clk) disable iff (!wr_rstn)
        full |=> !wr_en; 
    endproperty
    assert property (p_no_wr_on_full) 
        else $error("SVA VIOLATION: Write attempted while FIFO is full!");

    // 2. Read Domain Check: Never read if the FIFO was empty last cycle
    property p_no_rd_on_empty;
        @(posedge rd_clk) disable iff (!rd_rstn)
        empty |=> !rd_en; 
    endproperty
    assert property (p_no_rd_on_empty) 
        else $error("SVA VIOLATION: Read attempted while FIFO is empty!");

endinterface