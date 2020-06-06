`timescale 1ns / 1ps

// In this testbench I focus on correctness of the SHA3 core.
// In this first test I only go for the generic non-last round.
// Also useful to observe latency.
module uut_sha3();

localparam CLOCK_RATE = 100_000_000;
localparam PERIOD = 1_000_000_000.0 / CLOCK_RATE;

// If this is nonzeroa new hash will be dispatched only after a result comes out.
// It is useful to observe latencies and signal propagation.
// It is usually better to run everything in pipeline mode as the SHA3 core can take
// one input each clock so leave this at zero! 
localparam bit STOP_AND_WAIT = 0;

bit clk = 1'b0, reset = 1, dispatching = 1'b0;

initial begin
  clk = 0;
  forever begin
    #(PERIOD/2.0) clk = ~clk;
  end
end

localparam longint unsigned give[16][5][5] = '{
    '{
        '{ 64'hed349f06686d8027, 64'h5fe39318706f6195, 64'h3c9888ad4a48c9f1, 64'h38fa73ea4c9f9798, 64'h577448dae745d880 },
        '{ 64'h49792b67cac2f946, 64'hcd1a3fc1b41acdca, 64'hae2cd84fdb59063e, 64'h8c0234bf0c1ed004, 64'h1dafb8edafddfbeb },
        '{ 64'h93b31c29b20290fb, 64'h35515c75e658acd0, 64'h14ac15b25cbc4129, 64'h0266d39310eb3bfd, 64'hfea7541b24a81f65 },
        '{ 64'hf81be0e996675e9a, 64'hf67a9fcc3213c8c9, 64'h63daa8873cca44cd, 64'h4891eb737aa589a4, 64'h0df5cd949a60cf42 },
        '{ 64'h4276a89b66dfb20c, 64'hff424609842e8507, 64'h99b6e18804c0ebdf, 64'h763d01802ba7c838, 64'h04152aba945ff0b3 }
    },
    '{
        '{ 64'h7b941b7320dda35b, 64'hf25eadb5f8c08f36, 64'hff1b5499f2ec634d, 64'ha09428a843d1c897, 64'h1cf7649293481200 },
        '{ 64'h115a7889ae3da5c0, 64'h5e8f063f5cc0ada4, 64'h4ba55482083e7df7, 64'h819cc68e974f1051, 64'h3c7ea66d3614166c },
        '{ 64'h3fd360d8cb1ace37, 64'hbe2b4278147f259e, 64'h12c1e707313040ab, 64'h3d8cd310d2d775db, 64'hcfabcd0fb4201c15 },
        '{ 64'h6634c7cd245ab13f, 64'h5411da62b3244ebb, 64'h000d71a8daac54d8, 64'h3cc046a3ef92dfc4, 64'hb9f69cd1756e48ca },
        '{ 64'h299b725f761301de, 64'hf2806ee91ea4bf77, 64'hd1ef2f367a9557de, 64'h38edb2f9479ec0cb, 64'h3e616b551b80f6fa }
    },
    '{
        '{ 64'hb1a4e205ca3f05d1, 64'h2468bbe6d4ce4b23, 64'ha19240245bc17080, 64'hfc7caabf7398f556, 64'hea940b9f91a3eaab },
        '{ 64'h89108cf07cf017c3, 64'h2ec6c2248d8e0ade, 64'hc817d9c48767ae84, 64'hae106e4e60c42db9, 64'h0735cf3ca03cb0c7 },
        '{ 64'h0cdf480ee7607157, 64'h5eb2289236f8b3d8, 64'h4585edb1a62208e9, 64'h095a427d287ef370, 64'he8cae7162f416558 },
        '{ 64'hccb4fe352e592924, 64'h93739e3a194fc875, 64'ha3d77419da5cbd01, 64'hb7693a190f8dd0aa, 64'h3532030c1f8bf186 },
        '{ 64'hde87ebdafe491143, 64'ha390021e6b3edef4, 64'h7a36a8e2522bb9bf, 64'h91d5dc017a64cacc, 64'hfdab3ccf6d1fa1e0 }
    },
    '{
        '{ 64'h0eaca5b7a796285e, 64'h271b0a52caa92b46, 64'h4c61cfa9f74fe788, 64'h2d506ec04b180d27, 64'hddd8806a187ac74b },
        '{ 64'ha2a3bcf110aab683, 64'h25516c9f66a2d9be, 64'h50f08dfea4845751, 64'ha511eba3426f03ac, 64'h30a80c5c65fe8c4f },
        '{ 64'h2e720933a0b9f102, 64'hc2edb8682756ad3f, 64'h633c63d1291568fc, 64'h5f7eefa35c3d3b2d, 64'h5a446ab2030dfd67 },
        '{ 64'h307daf61d1668025, 64'h1e8808b85e3b41c2, 64'hbad594fbab9b1ccc, 64'h7132f466c84e7c1b, 64'h64760a5ce4bbeaa9 },
        '{ 64'hf55d8a6986885fe6, 64'h29e6d66472c2b9ba, 64'h2988b0c33e013b8d, 64'h924f55ef03790ef7, 64'h4fb77c9435376a4a }
    },
    '{
        '{ 64'h1903b25d2484640f, 64'hda6040ba3d9bdb0b, 64'h15b72dd6187bc571, 64'h6f817dca85fe2b07, 64'hdab4a72cddf4bab7 },
        '{ 64'h2ca95be456e3b553, 64'h8f24f72178aec608, 64'h052e3586d2d892be, 64'he3ff51c3c0e91a05, 64'h0d3c879ccc625b7a },
        '{ 64'h38b1928c03018e32, 64'h7bbe45a71111b790, 64'ha1231a9fba298d36, 64'h68cce7df600f93f7, 64'h2d51b1f330261586 },
        '{ 64'h7e1db3284835092a, 64'h182d04b724a4616f, 64'ha9ca5360254aabbb, 64'hb403d8b254231f67, 64'h658008a816492124 },
        '{ 64'h59974cfa5b74f27e, 64'h4f9489df43b98d9b, 64'hff2eb63ab6b57ea2, 64'h0a2bf4e618c1d41a, 64'h90311ef705726b2c }
    },
    '{
        '{ 64'h93b5ec8f0690fe69, 64'hf5e9ded92133776d, 64'hd72889a462f88447, 64'hf09289347424a288, 64'h88532c4d58f06ebf },
        '{ 64'h2a1eb790b604aa27, 64'h128bb7a649ae6c34, 64'hb8f6c96db2a615b1, 64'h4247672e52c9581a, 64'h45b1d55c443d60b2 },
        '{ 64'hcdc7fb28cbeb5859, 64'h7667b73a3c95bed0, 64'h9e9b6761eb08b0df, 64'h33e68f0cbb444885, 64'hdd5d42c668bee765 },
        '{ 64'h62c848bb9d653454, 64'hc11490ce2099bb1b, 64'heab34092c7892973, 64'h73c3dbf60d2aef4f, 64'h9d31558b676411ab },
        '{ 64'he0b18478ccdfa4f3, 64'he9b24054b08db64e, 64'h6a45345f49a6561d, 64'ha715f93b7e83f0e5, 64'h8128762e7122072f }
    },
    '{
        '{ 64'hf08d09917dfc68e5, 64'h323c48655347455e, 64'h2ad246426361e5d0, 64'ha62383e62a459ac6, 64'hc92735ba0cd2ebbf },
        '{ 64'hf64874fa045f3839, 64'h5d070271f1e30d1d, 64'hc3a660c0aa097c20, 64'hc52a84a1ac3a186d, 64'h3546157a6e49120d },
        '{ 64'h5e2362a5283c013a, 64'h25b5fe3922cb8dc8, 64'h117b752846a29e8a, 64'hdfa412f248c14822, 64'h79d577d782984052 },
        '{ 64'hd48c982ae11f505a, 64'h9aec0701c9447ec3, 64'h2b0b097def771930, 64'h8700b4dc5222741d, 64'he23369c969a2758f },
        '{ 64'h2325d017f83d36f5, 64'h4af54cbe4c93e09b, 64'h08dc8757e7baa8e1, 64'h68e8b5f656216312, 64'h512513e770f9fcf1 }
    },
    '{
        '{ 64'h07da797d68c77506, 64'h60b7ef678a3b3f72, 64'h05df8b9ca207ef06, 64'ha1cfa1ee8a56fc0d, 64'haaa01228e31662c0 },
        '{ 64'h46f91f4d6d57cb4a, 64'h6ef98a0eea6aa6ed, 64'h9d62963c935db5ab, 64'h7d0c2fe42e29c7a9, 64'h4d84e4c918fbc3b8 },
        '{ 64'hc40156de5ae6f382, 64'h9f8e528ab28300f2, 64'h5258bb43d2cb89ba, 64'hd266939c93624514, 64'h06c56acdc690bd19 },
        '{ 64'h8cfb324d10ee4251, 64'he0812edbc32cdba6, 64'hc1587581acaa3af7, 64'h615f7b9be356d16d, 64'hade3438dcb78b950 },
        '{ 64'h3f4be1aab1d69dd7, 64'h022c68d3656bf8ef, 64'h7130116a1b3d756a, 64'hb1c4b75992ad9b72, 64'hb51c8e7e1425c313 }
    },
    '{
        '{ 64'h7d364b6783f36f54, 64'hd2be1aa81cb4ebe7, 64'hb0d5feb5ffc51323, 64'h4b6922bbb1d011e1, 64'hbb4c8fcc92c93d48 },
        '{ 64'h3026d7249d42dbb6, 64'hcb746bb6fc35c622, 64'h3b3317ff558e8c4b, 64'h27b94240439c0ef6, 64'h595f44ed2a9dd831 },
        '{ 64'h078f58f1402302d8, 64'hf11a592fc9a8d462, 64'h436eee4be0c6efde, 64'h7e834ab1b5cccaed, 64'h931dbbcefd121cbb },
        '{ 64'hf257f89bbfcb8e08, 64'h858576dc735dbde2, 64'h41a563143cbc8d8e, 64'h1e8acac9c5e87113, 64'h703b1eb70ecb40a5 },
        '{ 64'hfec38cb823743c71, 64'h3c335b931f402edf, 64'h6bc12ff5968a03df, 64'hd595e8cc6875f74a, 64'h5552aa73c1557f62 }
    },
    '{
        '{ 64'h668388f4d867d9c6, 64'h968777513101ba16, 64'h719ccf91f8c33b46, 64'h5710901047032990, 64'hcaa31ba38e16539e },
        '{ 64'h5b406c034816bef3, 64'he8b924a46d3d509c, 64'hda8b9a79dae4053e, 64'h762c9e193840d08c, 64'h0a94bf617ceea95f },
        '{ 64'h9fbb3f5d75993e6d, 64'hfc2747379a8a19c0, 64'heb3b645298a9d838, 64'h4e35c574356113e8, 64'h190e8ad652b71916 },
        '{ 64'h31cc452cf92d814c, 64'h33af68ee9fcd87ad, 64'h68f16d32f7214831, 64'h159bf8ba1c6a08fc, 64'h6805da125f6e78db },
        '{ 64'h75d25c8c2d5a97ad, 64'h777b6bed652cd49e, 64'ha61da740d2951701, 64'h2062f0bf2646114d, 64'h6ecacff75ca2e667 }
    },
    '{
        '{ 64'h1653a6c4aba87cfd, 64'h5b6044dfd279a2b3, 64'h736cb257ba6de249, 64'h1ade3dfde5bf61be, 64'h55bfdfdc8a42ca29 },
        '{ 64'h5cec1c6fddf17d00, 64'h24adad7fce063671, 64'haaa7efe3f2a4c898, 64'h059546854eb9dd2a, 64'h0d3af62edc82c926 },
        '{ 64'h6fec20b05acc54db, 64'ha35c3c450e726e6b, 64'h5407cf329577a6d4, 64'h00cd21ef7978474f, 64'h4e8a42f6da8e6aa7 },
        '{ 64'hbc9a82a3f36bf05c, 64'hdb5488e7174acc1f, 64'h9a8282caa68e2d1d, 64'h0cef167da891e63e, 64'hdc07d2a9b1c0bb99 },
        '{ 64'h7023ecc5205fbe66, 64'h2feec333db480c36, 64'hf08e39f9a489f68d, 64'he4ccfe1925dcb8b1, 64'ha5cd485052616006 }
    },
    '{
        '{ 64'hafa7ebff763ef067, 64'hf8e87ee9d7ee0dbd, 64'h61ba714b9bbf725c, 64'h49655fa28ca3b152, 64'hd5886a6a08b90601 },
        '{ 64'h888f4a2c62b3a9c5, 64'hff3b471910a647b7, 64'hcc255699c74a2258, 64'h5cd37b46874d697a, 64'h12fe91ac71fc0c62 },
        '{ 64'h02dafcfdc3962c4e, 64'h8d597c06e7fb4ef2, 64'hb58277fefea90dfb, 64'h5fe75f636e4b90ab, 64'h148cf4b0421c600e },
        '{ 64'h9e88ce2f45587a92, 64'hae496789360ade85, 64'h770e985ab37f5272, 64'h1964a38b15ccf5ea, 64'h23b8733cd3bcc6e8 },
        '{ 64'h7386c1e3b8093306, 64'hd4802a09c4ff21d0, 64'h5f7fb1540e5c72a9, 64'h46aab8a010a51780, 64'ha105d54a1bd372e5 }
    },
    '{
        '{ 64'haf22b41ad99ab22e, 64'h09983369e468a8a1, 64'hf9b2e7873c58c1bf, 64'h9c0cb9d3c7247783, 64'h26341c12b55133c2 },
        '{ 64'h672c56b9dfc6008e, 64'hd8f25129789326eb, 64'hbfdab4af1f509362, 64'h5c7151362805e0ed, 64'hcbf23bbdd4f6b8b2 },
        '{ 64'hbed50be92463b1e9, 64'h071f14bd3924810b, 64'hf021a44d8800a97f, 64'hebda9df89292d8f1, 64'hc6a2f883e9873274 },
        '{ 64'he1c174baa64e4e1b, 64'h4e5cd8266d455fbd, 64'h340d8dcc00766710, 64'hbf85f9e3a2827c0e, 64'hc3d33ac19acd5045 },
        '{ 64'h1c5bd984aac924b3, 64'haf942bb3a2b4b825, 64'hd550930e9ad68aee, 64'h5d8465094aeeb42a, 64'h7df5c71aeec8eb1a }
    },
    '{
        '{ 64'h80027b72574ee85e, 64'h10b11d228db1181f, 64'h8f40a6cc036e61e6, 64'h58d9003284e6fe8e, 64'hc16380db029623e4 },
        '{ 64'h7e1058e1f212f2e1, 64'h55176ae05d70ef9b, 64'h45df7bf5c5e1c118, 64'h6663ca1c7c2a440e, 64'h557bb9f75a33d295 },
        '{ 64'h58d007009f517068, 64'h30b316e0128c7d9e, 64'h34c8bb1fd3e17f6c, 64'hd7d895ae222ba39b, 64'h0efb2a1177973198 },
        '{ 64'h96ff161efa6dd142, 64'h92ad6c7bcf6de387, 64'hd6e73be07a0b01dc, 64'hae0ae1772d3949d5, 64'he2ba9bc4c5e3c4e1 },
        '{ 64'hd6244f3f9c243e2e, 64'h3fda640d9db17df4, 64'hc9f0e22d4b4468b5, 64'h0c99541bf544e96e, 64'h4fd0492c703c2532 }
    },
    '{
        '{ 64'h91c2a505ef816703, 64'h2555908ece037c40, 64'h1f593e59f4537342, 64'h5d9c2b98b67c115a, 64'h80f1bd3503c762d3 },
        '{ 64'h46dfde1efeec3a03, 64'hd4df643a1e2abc53, 64'hc868f1786bd95386, 64'he3655db96633ddd1, 64'hbc65a1a4b8c17a15 },
        '{ 64'h2666fdd7cc61b52f, 64'hb8251fce97f775e5, 64'h7e4fb43f7b294d42, 64'h527311ad6e201887, 64'h534db77af598de50 },
        '{ 64'haec68c93cba40f02, 64'hb4f42df172c7ffe7, 64'ha29207cb262eb809, 64'h4256300e9a9ae197, 64'hd61da3c8c8c232d8 },
        '{ 64'had0c545e5f80f63f, 64'h6b5e33ce0364410d, 64'h37ec97c3135eb177, 64'h0f8c7b156f366540, 64'hd46c08fd3c85e5f1 }
    },
    '{
        '{ 64'h97b2b6d35c49b843, 64'h94cef6fc175719f1, 64'h52736115b1a1ffb4, 64'hcc505050ef233321, 64'h4c2c290e8a3551a2 },
        '{ 64'h59367e76d2da525e, 64'hdef4c234eeb636dc, 64'h49d71c6d79446001, 64'h285dea563889726f, 64'haf0166a1f8553851 },
        '{ 64'h708aeb20e5b0fe3f, 64'h9574df10c534da0f, 64'ha14e128a1fe57d3d, 64'hc6236de1154564c1, 64'hbf3c6edf8b209038 },
        '{ 64'h76016314e0616cd1, 64'h3b816f30031db60d, 64'hfe445134753cd509, 64'h619a2435e840c7ac, 64'he6fd2eb0a4f14020 },
        '{ 64'h3e9edb6cc50b9474, 64'hc86723b9573ed9bb, 64'h3b68c74be155190d, 64'h299f793bc2a104de, 64'h072b6cf5994e5b7b }
    }
};

bit start = 1'b0;
int dispatch_index = 0;
wire[63:0] feeda[5], feedb[5], feedc[5], feedd[5], feede[5];
generate
    for (genvar loop = 0; loop < 5; loop++) begin
        assign feeda[loop] = give[dispatch_index][0][loop];
        assign feedb[loop] = give[dispatch_index][1][loop]; 
        assign feedc[loop] = give[dispatch_index][2][loop]; 
        assign feedd[loop] = give[dispatch_index][3][loop]; 
        assign feede[loop] = give[dispatch_index][4][loop]; 
    end
endgenerate 

wire[63:0] result[5][5];
wire ogood;

sha3 hasher(
    .clk(clk),
    .isa(feeda), .isb(feedb), .isc(feedc), .isd(feedd), .ise(feede),
    .sample(start),
    .osa(result[0]), .osb(result[1]), .osc(result[2]), .osd(result[3]), .ose(result[4]),
    .ogood(ogood)
);


initial begin
  $timeformat(-9,2," ns",14);
  $display("testbench start SHA3-1600 hasher (correctness, observe latency)");
  #150 // wait for GSR and other nonsense.
  reset = 0;
  #50
  $display("signals considered settled");
  dispatching = 1;
end
  

always @(posedge clk) if(dispatching) begin
    if(dispatch_index != $size(give, 1)) begin
        if (start) begin // 1 clock sample pulse
            dispatch_index <= dispatch_index + 1;
            start <= STOP_AND_WAIT ? 1'b0 : (dispatch_index != $size(give, 1));
        end
        else begin // when starting just pulse the first, then pulse after a result is received
            start <= dispatch_index == 0 | (STOP_AND_WAIT ? ogood : 1'b1);
        end
    end
end


localparam longint unsigned expected_result[16][5][5] = '{
    '{
        '{ 64'h30ce10fab53edc10, 64'h79eae51020809c25, 64'h14304698fc873745, 64'h9e7b50fc25013fb8, 64'h0a1483c12b5b5961 },
        '{ 64'hd8e7f6d215d229d3, 64'h92a2f9afcb663415, 64'hf036c837dacda4bb, 64'hcc2632255c7d22fa, 64'h022f6573a5529bef },
        '{ 64'h6f606d3b08cc0104, 64'h792fdba4cda71275, 64'h233c03b41c6fbea5, 64'hdfdc342dc3a4b5a3, 64'h6ac91551d4697bbf },
        '{ 64'hde475fe966a50a67, 64'hfc06155570883c4e, 64'h25d165155ea74c6b, 64'h1ad4a3f9835660c2, 64'h8a67bd6b602c5e10 },
        '{ 64'hefdb1ed57de12ae1, 64'hb6115f4bf24c97f1, 64'h1fb5f3161977b3f5, 64'hba6d3df1947ac665, 64'ha962c442470ad990 }
    },
    '{
        '{ 64'h3c0ef4d6695ce44d, 64'heb08357ccd9b1d35, 64'h845d694941e49720, 64'haabac8c8cd1cdcae, 64'h83bbe8e82edf3e98 },
        '{ 64'h1ff0e50848d1a3bf, 64'h41944c5d391fc493, 64'h9c048620587191f8, 64'hb5f2cdc266b77917, 64'h4ee86572f862e48e },
        '{ 64'h1b3df6f8d33204c1, 64'hf3de0a86d136cbb6, 64'h51075de5e81dff1a, 64'he2c7b3c35a9a281a, 64'h133eb500437e137c },
        '{ 64'hcc1a9a766197f8a1, 64'h594f11bf02535ca8, 64'h71953ed3f161152e, 64'hc7e402d722273a03, 64'h4781bc9f4167d8c6 },
        '{ 64'ha91deeb0da10f6b7, 64'hc81cb34b6b060c00, 64'haac422be70f9686e, 64'h3cf0a52f41977e3a, 64'hc2b04b2fca0dde10 }
    },
    '{
        '{ 64'hae246f09a1fda431, 64'h53efc9f261faedcc, 64'hbc864f6a20095e77, 64'h0992c623378e76af, 64'h0153f141657055cc },
        '{ 64'h60e37fefad3b76e1, 64'hd5a93bfaae198aef, 64'h09c68cd02ac6848b, 64'hf6e8543271a07a9f, 64'h88bba41cec1ea17b },
        '{ 64'h521564bc64b80f5e, 64'haa1115b5d2ee623f, 64'h20120015f292a78f, 64'hb259dce517eec2d3, 64'hf29d9b761c447341 },
        '{ 64'h9b041003ca777eb9, 64'h39363a13dd8581ce, 64'h877f593f644464f7, 64'h844a82d5567bf5c9, 64'h2340c8353b4ee3bd },
        '{ 64'h516e491a8d33deeb, 64'hbe38790183cfe341, 64'hde9a7b580ecfa85c, 64'h93d4fe89ccb70454, 64'ha2bcda4b3fbca152 }
    },
    '{
        '{ 64'h00e414a80c2bebc8, 64'h5417bd2253870ed7, 64'hb8f0d3fea25fb190, 64'hca37bc968d344609, 64'hdc6d39982a8b9e25 },
        '{ 64'h64ac58074c0561eb, 64'h07a81aeb9ea327b2, 64'h4681872e61fe0269, 64'h882747fcd858754c, 64'hbe90a26bf83fd6c2 },
        '{ 64'hda15bd860ec4fc62, 64'hf39d4b041573948b, 64'h39830df5405e791c, 64'h51f7feeefefeb771, 64'h3c5bf233afe3db65 },
        '{ 64'h2c1d315271e7673d, 64'h10a3fbf416760fea, 64'h64da73f37bf42529, 64'h54701055a2760ef0, 64'hc33851f032016a42 },
        '{ 64'h36dd4a45d73e4e03, 64'ha507c19728b5bd71, 64'h63f3b24b0825f589, 64'h99a3dfcc4a9e6100, 64'h76949dd1fe6b0944 }
    },
    '{
        '{ 64'hefc054d988fcbd96, 64'h2d8618c8512958ee, 64'h74208b1170a9994a, 64'h48f99694da509175, 64'h88e99214f25e129f },
        '{ 64'he6313342b47bd032, 64'hb9089a385cd452a1, 64'hc944bbe33b4de9ea, 64'h151ef722270d693b, 64'h7e36b302e967a6fa },
        '{ 64'hc5409fd679b84515, 64'hb98fc1ea9ce4f8bc, 64'h7471ae77e0a96a21, 64'h448c96c3f56bc2ab, 64'h472dcc0f851e0526 },
        '{ 64'h1faac4c6b8ee3c7c, 64'hd8e09a4a4aaf023a, 64'he9a23e490cdbc972, 64'h64732976b2887210, 64'hecf5a8b416efb73b },
        '{ 64'h2f0f0cc54e499aaf, 64'h7114859c863474a8, 64'h988bf041b5ce9d54, 64'h4e0133b86f3e9431, 64'h6e9a99f07e4783b8 }
    },
    '{
        '{ 64'h96a96b474c72b2ae, 64'h53111835de4c816c, 64'h5b05555ac1e51f05, 64'h3e36ed91f5b64e94, 64'hedd87380673bc2bd },
        '{ 64'h2bf2eadb50a89544, 64'h4d9c3874962404bc, 64'h428e56c59d380fab, 64'hb77fa8c9f3d8ca62, 64'h71f7747528708f49 },
        '{ 64'h5ac09da2650502aa, 64'hadf33b81845d60a2, 64'h379effa4f83e11aa, 64'hdfcb57e0ada36511, 64'h2a8ed41d4354588d },
        '{ 64'hba9c30548bf26549, 64'h7c9c84572c40f1c6, 64'hef1d7d8c43239a6c, 64'h3b37d9e578adec0e, 64'hb4b7038ab27dd219 },
        '{ 64'h832467403480e25f, 64'hed2359999329bfaa, 64'hcbfd5b9624e8dcd3, 64'h4e2427399b666e44, 64'h9ceff444ed1a4dd5 }
    },
    '{
        '{ 64'h397524ae22ce1671, 64'h722e33e2b488a24a, 64'h89b4c4b6c9852224, 64'h8e4555c7533f73bd, 64'h9bd6de3ef5333fe0 },
        '{ 64'h94ffb8bb2e36816c, 64'h24e0f25a92f95431, 64'h49c7ebaf3c5e2e4b, 64'h60c62e000de7b28a, 64'he1b3952a3b633ccb },
        '{ 64'hc9fda46719d71db0, 64'hbbe6592dabba0d52, 64'h88f5e56be093661d, 64'hab4824e58ad74fc8, 64'h542fb598f44999ec },
        '{ 64'hd6c0ae01a4745cbd, 64'he92cd6b2ae49ba94, 64'hfcd74c36bfbc1bbb, 64'ha1b209fdfb420b68, 64'ha5cc6484ca6e5a1d },
        '{ 64'h49a596016c649d48, 64'h756a5bfb6e2a0969, 64'haf6649098cc7b96a, 64'h2759af28f9174519, 64'h4f4177a36a10860f }
    },
    '{
        '{ 64'h3b09a563c2ab0ebc, 64'h51fd52e0d60efa3b, 64'h95a3e48d113336cb, 64'h4fbf170168cb559f, 64'h43ebb07bfc2d0ea9 },
        '{ 64'h0dcf9804c6a7cb16, 64'h555dfa81cf8edf52, 64'hacaaa5cdbe8def84, 64'he89dcf4d464beb0e, 64'he7ffbcff1800081e },
        '{ 64'h92f58bd0afe65fe3, 64'h321dbd190dcd2dbd, 64'h6ca1e36fa1a6745a, 64'h919d2dbe28aac130, 64'h187ac27bdc4eadc2 },
        '{ 64'hc9cfa4211168133d, 64'h3af5cda6851133e2, 64'hf6f5f1455ba0e7dd, 64'h3f9560aea2189ea5, 64'h42d77775242ca8d6 },
        '{ 64'h6f8f1d0eaea07a26, 64'h01f64e1a8216b960, 64'h5179744f51ec983c, 64'hcc0d055e97227ded, 64'h7ba5cf6571d48a41 }
    },
    '{
        '{ 64'hd48c02be088646cf, 64'h769a0cf19d643874, 64'h053a8fc9f361b90d, 64'h270b5c4088a05ae8, 64'h9e5524c4169510f3 },
        '{ 64'h97a35cc85ac9ed64, 64'h83e5022727aa4128, 64'hba680d39c42cbd24, 64'h4d0a8c372de77d3e, 64'hbb810329214e6ee3 },
        '{ 64'h9d010add1b9ca371, 64'hcfd6a29ae1bad27e, 64'h04416bff28375fc1, 64'h5bfef59665b66cf9, 64'h03e1ff87e618f651 },
        '{ 64'h02e2526d2ad06e13, 64'hef42e1b32f5a9eb3, 64'h6801705e1232b0be, 64'haa32a07ea538f597, 64'h2a59440d1ad7482d },
        '{ 64'hecc9c35086f4a8b1, 64'h3ad7e15bde3f9ac0, 64'h34bdb5f2f769ab48, 64'h4c7bc4b8350ce041, 64'h7d9559e6ae3dcd62 }
    },
    '{
        '{ 64'h83b0b30dbcd658cc, 64'h9bb41f2f6961e6dd, 64'h308d328efba9e01c, 64'h5d4164e18a4f2152, 64'hb784966bbdf2a44b },
        '{ 64'h5ce40582a18404da, 64'h6a4febe0d7265ec8, 64'hc5b52753459d45c0, 64'h915d62b8bf8baa7b, 64'h2ab6101d667a7009 },
        '{ 64'h40636eb9dd714628, 64'hbee2c76932876874, 64'h851900f01cd30f47, 64'h254a640bc864b72a, 64'h47cc34283444daa4 },
        '{ 64'h21b51512bea63d60, 64'h128cc9793cf0ae38, 64'hdcda181603199204, 64'h4d519bb5e886db05, 64'hc6f3aaf9097d71bb },
        '{ 64'habf34caf052616f2, 64'haf843ba20b225099, 64'h39a8b66a25ec8873, 64'hdf0b3cc99136fb1e, 64'hf26a7eb63d0513f6 }
    },
    '{
        '{ 64'h7c8145ed91e40f8a, 64'h60ad1508fc12abc2, 64'hb2f3b4216539b12f, 64'h59811aeb4dadf2ce, 64'hdbac2fa3868f2ac8 },
        '{ 64'hdd520bcf32c660f3, 64'h9ebea43d8f145392, 64'hb50773be374eecfb, 64'h56eb2292068b028d, 64'h1ff32f4861739c28 },
        '{ 64'h20f8555c9519f09d, 64'hcb58a7b3b62949e6, 64'h2641ee3797dd3c0b, 64'h21d1ab66f0382012, 64'h259eaf6593ec74b8 },
        '{ 64'ha745ccc78917e33a, 64'h28014448b971f48f, 64'he2fabf5dcfe1097b, 64'h739958a530790a0b, 64'h6a55825b2631c90b },
        '{ 64'hf67bf2e2cc583828, 64'h09562581159049cc, 64'h204541945ba3216a, 64'hb52e583a8c5cca51, 64'h05381357223c7c22 }
    },
    '{
        '{ 64'hae911c424fd9fa28, 64'h0ce47a41eb0b73ea, 64'hb2e2ff7e6a79cd2a, 64'h95b700d8ca6ef6ca, 64'h75068d7d5a47cfd5 },
        '{ 64'h4f20b0defbcbc020, 64'haa9faca7e4da9086, 64'h3501f020f13f4028, 64'h2a229cb3bc54086c, 64'h9b1203851f0846ad },
        '{ 64'h9150b1902851c237, 64'h197f0f4cf4e6a879, 64'h3d2c778a3965c9b5, 64'h17515c11506af78b, 64'ha6ddf185c32cbc2d },
        '{ 64'heb67e4d85f6448ca, 64'hd5ce07a80a1d04a9, 64'hd4fca111d407c09e, 64'hd9833f052e17d4f7, 64'hc8bbe04b75e5514b },
        '{ 64'h43057813f8044415, 64'h7d45492fcd8ea886, 64'hbbed06c1ac7f210f, 64'h838b83b554732ce5, 64'hc041fa275f0ef30b }
    },
    '{
        '{ 64'h1cc51eb27848a3e4, 64'h6ba1adf7459c3d5a, 64'h9c0516a9d076dbe7, 64'hbc6fe0bb10d18da9, 64'h7fe279c2a087d670 },
        '{ 64'h9a72a908519f0953, 64'hcd0a7196591eee87, 64'hd9150a6d391f152e, 64'h1420b98900b46db9, 64'h6d32c168c2fa9a3b },
        '{ 64'h7ef69736088cd0f9, 64'h64acad0c1559383a, 64'h1d71484eb4b25ef4, 64'h4bf8b102603d18ec, 64'h4ab3938398c2a486 },
        '{ 64'h50a634b70d999a68, 64'h45c8e53b37f7b255, 64'he970ea5620e01f10, 64'h45faff2e0f6ad636, 64'h3985e3284f6f8bd6 },
        '{ 64'haa6338dffa6c9a7f, 64'h85db64242dd8dc58, 64'hc31bb7a68561c88c, 64'h059a928758b9aff6, 64'hee2e5edd7ce9a783 }
    },
    '{
        '{ 64'hcc1d9cb8e4b6759a, 64'h87e91d76a57cb932, 64'haeed94fbec5c80b3, 64'h6dd189d3eef7e6bd, 64'h6ea4e56b0d10e2e4 },
        '{ 64'h236775f0ac9cd915, 64'had929ea1c06767c4, 64'h2bce0aa374c2fb72, 64'h79c924a55fbf9ffb, 64'h09404fcc06ca9690 },
        '{ 64'hdbfd8a8fcebed8b6, 64'hb06a7d8209b1a065, 64'h1b1dc46c19162cdf, 64'h90f2e531cae5b992, 64'h14f744ff582452d9 },
        '{ 64'h26d88bb9d3dc6021, 64'hfe1a489d50029f0f, 64'hc3ffa856c6bfb899, 64'hcee6b40bc85fcfdf, 64'h79053e8277932b87 },
        '{ 64'h75adc6c46af30a7f, 64'h4c106f3adb81c399, 64'hb310989eba5c5c75, 64'h4df8ddee57fff00a, 64'hc05115dd76317b2b }
    },
    '{
        '{ 64'h00945f18351aae9d, 64'h91d3d170429c4fcf, 64'h964aaad9a1001f9e, 64'h652532e0303c63dc, 64'h332a62bb5f3086fa },
        '{ 64'h850978e741575a2f, 64'h7e68059332bbaf7d, 64'h07320892665924cf, 64'hc0768c9c1c1af389, 64'hf971c9936bcc3a0b },
        '{ 64'hbf2eb85fed259a8b, 64'h24f43f561c5cc9fb, 64'hac36618f48289b83, 64'ha051cb7eae8877fe, 64'hd109775a3f874249 },
        '{ 64'h9cbcaa9086daaf40, 64'h47e7f2a217d1a9a1, 64'hf4f85115b25d8136, 64'h2aa9fea863cc78d5, 64'h5fbecb4ee961df8a },
        '{ 64'h13530d21118a06fd, 64'ha73bc7d5f31c8256, 64'hac722dd260f1a3fb, 64'hd0369df8597ccdd8, 64'ha36ae9fb809060c3 }
    },
    '{
        '{ 64'ha26cfbd8e397ea9f, 64'h6c6320046543a636, 64'h78060da52146dab5, 64'h71fc7a0292264d4a, 64'h0ceda52641e5e4d6 },
        '{ 64'h2b20387622724f0a, 64'h46d9eea9a06c03a1, 64'hdf7ce8bb7429bdc8, 64'h27f3dc43d16b5384, 64'h3659b5735e32438b },
        '{ 64'hc205f40cf7537e46, 64'hbc39e5e9d2b0cc5d, 64'hd513b18b8b063e04, 64'h24c48034340e0647, 64'h86621507b5f92055 },
        '{ 64'h0dddcf7102e91955, 64'h80efabd0e16ff7be, 64'h97ed661d36c605de, 64'h55a734fe97500621, 64'hb821a6b5158087ae },
        '{ 64'ha0be9200cafbed30, 64'h82c26b538c5171aa, 64'h565688a3fd80cb23, 64'hf97a108b0cf15478, 64'h41e3cd105d014117 }
    }

};

int result_index = 0;

always @(posedge clk) if(ogood) begin
  for (int loop = 0; loop < 5; loop++) begin
      for (int comp = 0; comp < 5; comp++) begin
          if (result[loop][comp] != expected_result[result_index][loop][comp]) begin
            $display("Result[%d][%d][%d] !! FAILED !! (expected %d, found %d)",
                     result_index, loop, comp, expected_result[result_index][loop][comp], result[loop][comp]);
            $fatal;
            $finish;
          end
      end
  end
  $display("Result[%d] %t", result_index, $realtime);
  result_index++;
  if(result_index == $size(expected_result, 1)) begin
    $display("SHA3-1600 hasher GOOD");
    $finish;
  end
end
  
endmodule
