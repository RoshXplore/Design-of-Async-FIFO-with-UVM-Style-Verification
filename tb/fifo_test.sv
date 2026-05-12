class fifo_test;
    fifo_env env;
    int unsigned global_ops_sent;

    function new(virtual fifo_if vif);
        env = new(vif);
        global_ops_sent = 0;
    endfunction

    // ==========================================
    // TESTCASE 1: Standard Sanity Test
    // ==========================================
    task test_sanity();
        $display("\n=== STARTING SANITY TEST ===");
        env.gen.num_writes = 15;
        env.gen.total_sent = 0;           // FIX: reset counter before each test
        env.gen.run_writes();
        env.gen.run_reads();
        global_ops_sent += env.gen.total_sent;
        wait(env.sb.pass_count + env.sb.fail_count == global_ops_sent);
        $display("=== SANITY TEST COMPLETE ===\n");
    endtask

    // ==========================================
    // TESTCASE 2: Full / Empty Stress Test
    // ==========================================
    task test_stress();
        $display("\n=== STARTING STRESS TEST ===");
        env.reset_dut();
        env.gen.total_sent = 0;
        
        // 1. Queue all writes
        env.gen.run_full_stress();
        
        // FIX: Wait for the write driver to actually fill the FIFO 
        // This prevents the read driver from draining it immediately
        wait(env.dut_if.full == 1'b1);
        $display("STRESS TEST: FIFO is FULL. Starting reads...");
        
        // 2. Queue all reads
        env.gen.run_reads();
        
        global_ops_sent += env.gen.total_sent;
        wait(env.sb.pass_count + env.sb.fail_count == global_ops_sent);
        $display("=== STRESS TEST COMPLETE ===\n");
    endtask

    // ==========================================
    // TESTCASE 3: Concurrent R/W Traffic
    // ==========================================
    task test_concurrent();
        $display("\n========================================");
        $display("=== [TEST 3] CONCURRENT R/W TRAFFIC  ===");
        $display("========================================");
        env.reset_dut();

        env.gen.num_writes = 100;         // More than FIFO depth (64)
        env.gen.total_sent = 0;           // FIX: reset counter before each test

        fork
            env.gen.run_writes();
            env.gen.run_reads();
        join

        global_ops_sent += env.gen.total_sent;
        wait(env.sb.pass_count + env.sb.fail_count == global_ops_sent);
        $display("=== [TEST 3] COMPLETE ===\n");
    endtask

    // ==========================================
    // TESTCASE 4: Starvation / Slow Write
    // ==========================================
    task test_starvation();
        $display("\n========================================");
        $display("=== [TEST 4] STARVATION / SLOW WRITE ===");
        $display("========================================");
        env.reset_dut();

        env.gen.total_sent = 0;           

        fork
            // FIX: Rely on the clean generator method
            env.gen.run_writes_staggered(3, 10, 500); // 3 bursts, 10 writes each, 500ns delay
            
            // Read aggressively 
            env.gen.run_reads();
        join

        global_ops_sent += env.gen.total_sent;
        wait(env.sb.pass_count + env.sb.fail_count == global_ops_sent);
        $display("=== [TEST 4] COMPLETE ===\n");
    endtask 

    // ==========================================
    // TESTCASE 5: Burst into Full Wall
    // ==========================================
    task test_burst_full();
        $display("\n========================================");
        $display("=== [TEST 5] BURST INTO FULL WALL    ===");
        $display("========================================");
        env.reset_dut();
        env.gen.total_sent = 0;
        
        // 25 writes * avg length of 4.5 = ~112 beats. 
        // FIFO depth is 64, so a burst WILL hit the full wall.
        env.gen.num_writes = 25; 
        
        fork
            // Queue the writes, but DO NOT block
            env.gen.run_writes();
        join_none
        
        // FIX: Route through the wr_mon_cb clocking block!
        wait(env.wr_mon.vif.wr_mon_cb.full === 1'b1);
        $display("BURST TEST: FIFO hit the FULL wall! Releasing reads...");
        
        // Now release the reads so the driver can finish its job
        env.gen.run_reads();
        
        global_ops_sent += env.gen.total_sent;
        wait(env.sb.pass_count + env.sb.fail_count == global_ops_sent);
        $display("=== [TEST 5] COMPLETE ===\n");
    endtask

    
    // MAIN EXECUTION THREAD
    
    task run();
        env.start_env();                 

        test_sanity();
        test_stress();
        test_concurrent();
        test_starvation();
        test_burst_full();

        #100;
        $display("========================================");
        $display("=== FINAL SCOREBOARD SUMMARY ===");
        $display("PASS: %0d | FAIL: %0d", env.sb.pass_count, env.sb.fail_count);
        $display("========================================");

        env.cov.report();
        $finish;
    endtask

endclass