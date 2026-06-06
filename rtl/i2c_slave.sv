`timescale 1ns / 1ps
module i2c_slave
(
    input scl,
    inout sda,
    input rst
);

typedef enum bit [2:0] {
    s_idle, s_get_addr, s_send_ack1,
    s_get_data, s_send_ack2, s_send_data
} slave_state_t;

slave_state_t s_state;

reg [7:0] mem [128];
reg [7:0] s_addr_reg;
reg [7:0] s_data_reg;
reg [3:0] s_count;
reg       s_en;
reg       s_sdat;

assign sda = (s_en) ? s_sdat : 1'bz;

reg sda_delayed;

always @(posedge scl or posedge rst) begin
    if (rst) sda_delayed <= 1'b1;
    else     sda_delayed <= sda;
end

wire start_detect = (scl && sda_delayed && !sda && (s_state == s_idle));

always @(posedge rst or posedge scl or negedge scl) begin

    if (rst) begin
        s_state    <= s_idle;
        s_count    <= 0;
        s_en       <= 1'b0;
        s_sdat     <= 1'b1;
        s_addr_reg <= 0;
        s_data_reg <= 0;
        for (int i = 0; i < 128; i++) mem[i] <= 0;

    end else if (start_detect) begin
        s_state <= s_get_addr;
        s_count <= 0;
        s_en    <= 1'b0;

    end else begin
        case (s_state)

            s_idle: begin
            end

            s_get_addr: begin
                if (scl) begin
                    if (s_count <= 7) begin
                        s_addr_reg <= {s_addr_reg[6:0], sda};
                        s_count    <= s_count + 1;
                    end
                end else if (!scl && (s_count == 8)) begin
                    s_state <= s_send_ack1;
                    s_en    <= 1'b1;
                    s_sdat  <= 1'b0;
                    s_count <= 0;
                end
            end

            s_send_ack1: begin
                if (!scl) begin
                    s_en <= 1'b0;

                    if (s_addr_reg[0] == 1'b0) begin
                        // WRITE — slave receives data (Display statement removed)
                        s_state <= s_get_data;
                    end else begin
                        // READ — slave sends data
                        s_data_reg <= mem[s_addr_reg[7:1]];
                        s_sdat     <= mem[s_addr_reg[7:1]][7]; // bit7 NOW
                        s_count    <= 1;                        // start from 1
                        s_state    <= s_send_data;
                        s_en       <= 1'b1;
                        $display("[TIME: %0t] [SLAVE READ BRANCH] Master READ from Addr: 7'h%h | Data loaded from array: 8'b%b (8'h%h) | Prefetched Bit 7 immediately on SDA = %b", $time, s_addr_reg[7:1], mem[s_addr_reg[7:1]], mem[s_addr_reg[7:1]], mem[s_addr_reg[7:1]][7]);
                    end
                end
            end

            s_get_data: begin
                if (scl) begin
                    if (s_count <= 7) begin
                        s_data_reg <= {s_data_reg[6:0], sda};
                        s_count    <= s_count + 1;
                    end
                end else if (!scl && (s_count == 8)) begin
                    mem[s_addr_reg[7:1]] <= s_data_reg;
                    s_state <= s_send_ack2;
                    s_en    <= 1'b1;
                    s_sdat  <= 1'b0;
                end
            end

            s_send_ack2: begin
                if (scl) begin
                    s_en   <= 1'b1;
                    s_sdat <= 1'b0;
                end else if (!scl) begin
                    s_en    <= 1'b0;
                    s_state <= s_idle;
                end
            end

            s_send_data: begin
                if (!scl) begin
                    if (s_count <= 7) begin
                        s_sdat  <= s_data_reg[7 - s_count];
                        $display("[TIME: %0t] [SLAVE SEND DATA (SCL=0)] Driving out bit index %0d | s_sdat assigned = %b | Complete source byte = 8'b%b", $time, s_count, s_data_reg[7 - s_count], s_data_reg);
                        s_count <= s_count + 1;
                    end else begin
                        s_en    <= 1'b0;
                        s_state <= s_idle;
                        $display("[TIME: %0t] [SLAVE SEND DATA COMPLETE] All bits driven out | Returning to S_IDLE", $time);
                    end
                end
            end

            default: s_state <= s_idle;

        endcase
    end
end
endmodule

