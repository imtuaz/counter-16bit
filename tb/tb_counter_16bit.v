`timescale 1ns / 1ps

module tb_counter_16bit;

    reg        clk;
    reg        rst_n;
    reg        enable;
    wire [15:0] count;

    // Khởi tạo khối mạch
    counter_16bit uut (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .count(count)
    );

    // Tạo xung Clock 100MHz (Chu kỳ T = 10ns)
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 0;
        enable = 0;

        // Xuất file dạng sóng VCD
        $dumpfile("counter_16bit.vcd");
        $dumpvars(0, tb_counter_16bit);

        $display("\n=========================================================");
        $display("   DEM -> 10 -> RESET 2 CHU KY -> DEM TIEP 300,000 ns");
        $display("=========================================================\n");

        // 1. Cho mạch thoát Reset và bật Enable
        #20;
        rst_n = 1;
        enable = 1;

        // 2. Chờ mạch đếm đúng đến giá trị 10 (16'd10)
        wait (count == 16'd10);
        $display("[Thời điểm %0t ns] Mạch đạt giá trị 10! Bắt đầu RESET...", $time);

        // 3. Kích hoạt Reset trong đúng 2 chu kỳ clock (20ns)
        #10;          // Đồng bộ theo nhịp clock
        rst_n = 0;    // Đưa rst_n xuống 0 (reset count về 0)
        #20;          // Giữ Reset đúng 2 chu kỳ clock (20ns)

        // 4. Giải phóng Reset để mạch đếm tiếp từ 0 -> 1 -> 2 -> ...
        $display("[Thời điểm %0t ns] Hết 2 chu kỳ Reset! Nhả Reset và chạy đếm tiếp...", $time);
        rst_n = 1;

        // 5. Cho mạch đếm tiếp suốt 300,000 ns (đếm lên khoảng 30,000)
        #300000;

        $display("\n=========================================================");
        $display("   MO PHONG HOAN THANH!");
        $display("=========================================================\n");
        $finish;
    end

endmodule
