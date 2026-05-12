`timescale 1ns/1ps

module tb_top;

    logic wr_clk, rd_clk;

    initial wr_clk = 0;
    initial rd_clk = 0;

    always #5  wr_clk = ~wr_clk;   
    always #7  rd_clk = ~rd_clk;   

    fifo_if dut_if (
        .wr_clk(wr_clk),
        .rd_clk(rd_clk)
    );

    async_fifo #(
        .DEPTH(64),
        .WIDTH(32)
    ) dut (
        .wr_clk  (wr_clk),
        .rd_clk  (rd_clk),
        .wr_rstn (dut_if.wr_rstn),
        .rd_rstn (dut_if.rd_rstn),
        .data_in (dut_if.wdata),
        .data_out(dut_if.rdata),
        .wr_en   (dut_if.wr_en),
        .rd_en   (dut_if.rd_en),
        .full    (dut_if.full),
        .empty   (dut_if.empty)
    );

    fifo_test test;

    initial begin
        // Dump waves for EPWave / GitHub documentation
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_top);
        
        test = new(dut_if);
        test.run();
    end

endmodule