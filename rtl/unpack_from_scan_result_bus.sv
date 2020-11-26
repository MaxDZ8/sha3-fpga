`timescale 1ns / 1ps

module unpack_from_scan_result_bus(
    i_sha3_scan_result_bus.consumer from,
    output found,
    output[63:0] hash[25],
    output[31:0] nonce,
    
    // Do you prefer to get the hash as uints? Here you go!
    output[31:0] hash32_hilo[50]
);

assign found = from.found;
assign nonce = from.nonce;
assign hash = '{
    from.hash[ 0], from.hash[ 1], from.hash[ 2], from.hash[ 3], from.hash[ 4],
    from.hash[ 5], from.hash[ 6], from.hash[ 7], from.hash[ 8], from.hash[ 9],
    from.hash[10], from.hash[11], from.hash[12], from.hash[13], from.hash[14],
    from.hash[15], from.hash[16], from.hash[17], from.hash[18], from.hash[19],
    from.hash[20], from.hash[21], from.hash[22], from.hash[23], from.hash[24] 
};

    
for (genvar loop = 0; loop < 25; loop++) begin
    assign hash32_hilo[loop * 2    ] = from.hash[loop][63:32];
    assign hash32_hilo[loop * 2 + 1] = from.hash[loop][31: 0];
end

endmodule
