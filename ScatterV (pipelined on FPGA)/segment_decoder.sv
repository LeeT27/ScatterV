module segment_decoder(
    input        [3:0] current_sample_digit,
    input        [3:0] current_hit_digit,
    output logic [7:0] sample_seg,
    output logic [7:0] hit_seg
);
    always @(*) begin
        case(current_sample_digit)
            4'd0: sample_seg = 8'b11000000;
            4'd1: sample_seg = 8'b11111001;
            4'd2: sample_seg = 8'b10100100;
            4'd3: sample_seg = 8'b10110000;
            4'd4: sample_seg = 8'b10011001;
            4'd5: sample_seg = 8'b10010010;
            4'd6: sample_seg = 8'b10000010;
            4'd7: sample_seg = 8'b11111000;
            4'd8: sample_seg = 8'b10000000;
            4'd9: sample_seg = 8'b10010000;
            default: sample_seg = 8'b11111111; // blank
        endcase
    end

    always @(*) begin
        case(current_hit_digit)
            4'd0: hit_seg = 8'b11000000;
            4'd1: hit_seg = 8'b11111001;
            4'd2: hit_seg = 8'b10100100;
            4'd3: hit_seg = 8'b10110000;
            4'd4: hit_seg = 8'b10011001;
            4'd5: hit_seg = 8'b10010010;
            4'd6: hit_seg = 8'b10000010;
            4'd7: hit_seg = 8'b11111000;
            4'd8: hit_seg = 8'b10000000;
            4'd9: hit_seg = 8'b10010000;
            default: hit_seg = 8'b11111111; // blank
        endcase
    end
endmodule