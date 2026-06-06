`timescale 1ns / 1ps
module i2c_master
(
    input clk, rst, wr,
    input [6:0] addr,
    input [7:0] din,
    output reg [7:0] datard,
    output reg done,
    output reg scl,
    inout sda
);

typedef enum bit [3:0] {
    idle, start, send_addr, get_ack1,
    send_data, get_ack2, read_data, stop
} master_state_t;

master_state_t state;

reg [7:0] tx_reg;
reg [3:0] bit_count;
reg       m_en;
reg       m_sdat;
reg       scl_prev;

assign sda = (m_en) ? m_sdat : 1'bz;

always @(posedge clk) begin
    if (rst) begin
        scl       <= 1'b1;
        scl_prev  <= 1'b1;
        m_sdat    <= 1'b1;
        m_en      <= 1'b1;
        state     <= idle;
        bit_count <= 0;
        done      <= 1'b0;
        datard    <= 0;
        tx_reg    <= 0;
    end else begin
        scl_prev <= scl;

        case (state)

            idle: begin
                scl    <= 1'b1;
                m_en   <= 1'b1;
                m_sdat <= 1'b1;
                done   <= 1'b0;
                state  <= start;
            end

            start: begin
                scl       <= 1'b1;
                m_en      <= 1'b1;
                m_sdat    <= 1'b0;
                tx_reg    <= {addr, ~wr};
                bit_count <= 0;
                done      <= 1'b0;
                state     <= send_addr;
            end

            send_addr: begin
                scl <= ~scl;
                if (!scl_prev) begin
                    if (bit_count < 8) begin
                        m_sdat    <= tx_reg[7 - bit_count];
                        bit_count <= bit_count + 1;
                    end else begin
                        m_en      <= 1'b0;
                        bit_count <= 0;
                        state     <= get_ack1;
                    end
                end
            end

            get_ack1: begin
                scl <= ~scl;
                if (scl) begin
                    if (sda == 1'b0) begin
                        if (wr) begin
                            // WRITE path
                            m_en      <= 1'b1;
                            m_sdat    <= din[7];
                            bit_count <= 1;
                            state     <= send_data;
                        end else begin
                            // READ path
                            // bit_count=0 so read_data captures all 8 bits
                            // slave already has bit7 on SDA from s_send_ack1
                            m_en      <= 1'b0;
                            m_sdat    <= 1'b1;
                            bit_count <= 0;    // FIX — was 1, now 0
                            scl       <= 1'b0;
                            state     <= read_data;
                        end
                    end
                end
            end

            send_data: begin
                scl <= ~scl;
                if (!scl_prev) begin
                    if (bit_count < 8) begin
                        m_sdat    <= din[7 - bit_count];
                        bit_count <= bit_count + 1;
                    end else begin
                        m_en      <= 1'b0;
                        bit_count <= 0;
                        state     <= get_ack2;
                    end
                end
            end

            get_ack2: begin
                scl <= ~scl;
                if (scl) begin
                    if (sda == 1'b0) begin
                        m_en   <= 1'b1;
                        m_sdat <= 1'b0;
                        state  <= stop;
                    end
                end
            end

            // ----------------------------------------
            // READ_DATA
            // m_en=0 — master releases SDA
            // slave drives each bit
            // master samples on SCL HIGH
            // bit_count starts at 0 — captures all 8
            // ----------------------------------------
            read_data: begin
                scl  <= ~scl;
                m_en <= 1'b0;

                if (scl) begin
                    if (bit_count < 8) begin
                        datard    <= {datard[6:0], sda};
                        bit_count <= bit_count + 1;
                    end else begin
                        bit_count <= 0;
                        state     <= stop;
                    end
                end
            end

            stop: begin
                scl    <= 1'b1;
                m_en   <= 1'b1;
                m_sdat <= 1'b1;
                done   <= 1'b1;
                state  <= idle;
            end

            default: state <= idle;

        endcase
    end
end
endmodule
