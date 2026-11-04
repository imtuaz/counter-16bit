`timescale 1ns / 1ps

module tb_counter_16bit;

    reg         clk;
    reg         rst_n;
    reg         enable;
    wire [15:0] count;

    // Signals used for checking
    reg  [15:0] expected;   // value count should have (reference model)
    integer     errors;     // number of mismatches

    counter_16bit uut (
        .clk   (clk),
        .rst_n (rst_n),
        .enable(enable),
        .count (count)
    );

    // 100 MHz clock (T = 10 ns)
    always #5 clk = ~clk;

    // Reference model: computes the expected count
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)      expected <= 16'd0;
        else if (enable) expected <= expected + 1'b1;
    end

    // Checker: compare on the falling edge, when count is stable
    always @(negedge clk) begin
        if (rst_n && (count !== expected)) begin
            errors = errors + 1;
            $display("[%0t] ERROR: count=%0d, expected=%0d", $time, count, expected);
        end
    end

    // Watchdog: stop if the simulation hangs (e.g. a wait() never ends)
    initial begin
        #1_000_000;
        $display("TIMEOUT: simulation did not finish");
        $finish;
    end

    // Stimulus
    initial begin
        clk    = 0;
        rst_n  = 0;
        enable = 0;
        errors = 0;
   $timeformat(-9, 0, " ns", 0);   // %t in theo ns, 0 chữ số thập phân, kèm chữ " ns"
        $dumpfile("counter_16bit.vcd");
        $dumpvars(0, tb_counter_16bit);

        // Test 1: release reset, count up to 10
        #20;
        rst_n  = 1;
        enable = 1;
        wait (count == 16'd10);
        $display("[%0t] Test 1: count reached 10", $time);

        // Test 2: asynchronous reset held for 2 clock cycles
        @(negedge clk);
        rst_n = 0;
        repeat (2) @(negedge clk);
        if (count !== 16'd0) begin
            errors = errors + 1;
            $display("[%0t] ERROR: count=%0d during reset", $time, count);
        end
        rst_n = 1;
        $display("[%0t] Test 2: reset done", $time);

        // Test 3: enable = 0 must hold the value
        wait (count == 16'd20);
        @(negedge clk);
        enable = 0;
        repeat (5) @(negedge clk);
        if (count !== 16'd20) begin
            errors = errors + 1;
            $display("[%0t] ERROR: count=%0d, should hold 20", $time, count);
        end
        enable = 1;
        $display("[%0t] Test 3: enable hold done", $time);

        // Test 4: overflow 0xFFFF -> 0x0000
$dumpoff;                        // tạm ngừng ghi sóng trong lúc đếm dài
        wait (count == 16'hFFF0);
        $dumpon;                         // ghi lại từ 16 chu kỳ trước khi tràn
        wait (count == 16'hFFFF);
        wait (count == 16'hFFFF);
        @(negedge clk);          // count is still 0xFFFF
        @(negedge clk);          // one rising edge later, count must be 0
        if (count !== 16'h0000) begin
            errors = errors + 1;
            $display("[%0t] ERROR: count=%h after overflow", $time, count);
        end
        $display("[%0t] Test 4: overflow done", $time);

        repeat (3) @(negedge clk);

        if (errors == 0) $display("RESULT: PASS");
        else             $display("RESULT: FAIL (%0d errors)", errors);
        $finish;
    end

endmodule
