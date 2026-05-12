class fifo_transaction;

    typedef enum {WRITE, READ} op_t;

    rand op_t op;

    rand logic [31:0] wdata;
    logic [31:0] rdata;
    logic full;
    logic empty;

   
    rand int unsigned burst_len;
    constraint valid_burst { burst_len inside {[1:8]}; }

    function new();
        this.wdata     = 32'd0;
        this.rdata     = 32'd0;
        this.op        = WRITE;
        this.burst_len = 1;
    endfunction

    function void print(string tag = "");
        $display("%0t: %s | op = %s  wdata = %0h rdata = %0h burst = %0d full = %b empty = %b", 
                 $time, tag, op.name(), wdata, rdata, burst_len, full, empty);
    endfunction

endclass