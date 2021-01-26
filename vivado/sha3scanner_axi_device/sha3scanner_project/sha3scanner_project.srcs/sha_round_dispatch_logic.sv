`timescale 1ns / 1ps

// As long as your SHA takes 25ulongs per clock maybe you can drive it using this common logic!
// I could use a SV Header to pack some of the test data but I bundle everything together.
module sha_round_dispatch_logic #(
    TESTBENCH_NAME = "<FORGOT TO SET ME>",
    // There is a major issue with the iterative hashers!
    // To use them, you need to wait till their .gimme goes hi, then keep giving them inputs
    // till their .gimme goes low. That happens because they start on the first clock and assume
    // you will provide the number of consecutive inputs they expect. That is to slightly simplify
    // logic. I could do something magic and figure out the count but for documentation reasons
    // I want you to give the burst length explicitly. I will give only full "bursts".
    // The fully unrolled hasher has no such issue and its burst is effectively 1.
    TESTS_EACH_BURST = 0
) (
    output clock, rst, 
    output sample,
    output[63:0] rowa[5], rowb[5], rowc[5], rowd[5], rowe[5],
    input hasher_can_take
);

if (TESTS_EACH_BURST <= 0) begin
  initial begin
    $display("You forgot to set burst");
    $finish();
  end
end


localparam CLOCK_RATE = 100_000_000;
localparam PERIOD = 1_000_000_000.0 / CLOCK_RATE;

// If this is nonzeroa new hash will be dispatched only after a result comes out.
// It is useful to observe latencies and signal propagation.
// It is usually better to run everything in pipeline mode as the SHA3 core can take
// one input each clock so leave this at zero! 
localparam bit STOP_AND_WAIT = 0;

bit clk = 1'b0, reset = 1, dispatching = 1'b0;
assign clock = clk;
assign rst = reset;

initial begin
  clk = 0;
  forever begin
    #(PERIOD/2.0) clk = ~clk;
  end
end

localparam longint unsigned give[29][5][5] = '{
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
    '{ // 3
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
    '{ // 7
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
    '{ // 11
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
    '{ // 15
        '{ 64'h97b2b6d35c49b843, 64'h94cef6fc175719f1, 64'h52736115b1a1ffb4, 64'hcc505050ef233321, 64'h4c2c290e8a3551a2 },
        '{ 64'h59367e76d2da525e, 64'hdef4c234eeb636dc, 64'h49d71c6d79446001, 64'h285dea563889726f, 64'haf0166a1f8553851 },
        '{ 64'h708aeb20e5b0fe3f, 64'h9574df10c534da0f, 64'ha14e128a1fe57d3d, 64'hc6236de1154564c1, 64'hbf3c6edf8b209038 },
        '{ 64'h76016314e0616cd1, 64'h3b816f30031db60d, 64'hfe445134753cd509, 64'h619a2435e840c7ac, 64'he6fd2eb0a4f14020 },
        '{ 64'h3e9edb6cc50b9474, 64'hc86723b9573ed9bb, 64'h3b68c74be155190d, 64'h299f793bc2a104de, 64'h072b6cf5994e5b7b }
    },
    '{
        '{ 64'h35b61f8c43170c83, 64'h4e8a3e405baf53e1, 64'h7739311600c01f32, 64'h4bf95c001cc62c12, 64'h5cc5749a1e3e4118 },
        '{ 64'h5fa57b5d5c0b10af, 64'h582f551619173e21, 64'h584e18976b3d38f5, 64'h3e4264ad0967627b, 64'h13e8525244f331a5 },
        '{ 64'h733c5723325c4918, 64'h141c2c1445163383, 64'h674f0c6262b93a30, 64'h62c560c9316209d9, 64'h63202af8255619bc },
        '{ 64'h4674454211e908f1, 64'h244b4a96419f65fc, 64'h46ed3ab15990149f, 64'h49de2e920c1145f2, 64'h01a7312e5e9036b5 },
        '{ 64'h10d9106606c027e4, 64'h4e503a3622f7458c, 64'h60b57a2f51d46fde, 64'h33462b276d241a81, 64'h27da312f6c06362d }
    },
    '{
        '{ 64'h2a1f4fc5304e5876, 64'h0827304b432815e5, 64'h34232cb844fe424d, 64'h536e328e149b0b5c, 64'h3ecd520c71902171 },
        '{ 64'h57f54da41dd662ad, 64'h584d3daf42b63c4d, 64'h7cf61c601ce63637, 64'h34094df633f55cd2, 64'h2f1f793620e87d1b },
        '{ 64'h7f174419282666f6, 64'h1d1348c22a9129c1, 64'h04c456b231f67f2f, 64'h43e8543f1ca75854, 64'h231054422c6640fc },
        '{ 64'h4ba734117c850d41, 64'h0f3055ad234c055d, 64'h33cf4a3c029b03bc, 64'h6a0b00b90bd03956, 64'h4fd24cea7aeb0c3b },
        '{ 64'h24bd5a924cf1446f, 64'h139660e9758e7af9, 64'h35182a4917fd7f37, 64'h2ff5442a472d2674, 64'h1a1e6b50111c39bc }
    },
    '{
        '{ 64'h7f3e0843598775ef, 64'h3087500047c65215, 64'h41b25cee4bf27ff1, 64'h574154137f485ad9, 64'h2a086a8863d238c5 },
        '{ 64'h63eb5f2a474451a5, 64'h39e93c934d2430f8, 64'h675a7749642d659a, 64'h6e743c342af663dd, 64'h4214035607cf4ddc },
        '{ 64'h3cbc3ab677eb160c, 64'h08d71d9d59c53014, 64'h5e450c0536bc43df, 64'h3913764f500016ef, 64'h6d8a313472b21ff4 },
        '{ 64'h3d6c45fe5747789d, 64'h527a12f8102e21ae, 64'h423950234bb24d53, 64'h7ef64c2a6d2123b3, 64'h5a087598412e35c9 },
        '{ 64'h7b5504495194126f, 64'h7218571e1bfc31bc, 64'h42e159f530212a90, 64'h16dd07d97932666d, 64'h70575d7536784789 }
    },
    '{ // 19
        '{ 64'h087f4fcf67387521, 64'h3a6a1b332ddb420f, 64'h1f5b7e6c6e4c619f, 64'h4041363b2ba25e9f, 64'h00804d0168ff08b5 },
        '{ 64'h25f412bf11b74bf6, 64'h223351402cb526b3, 64'h011310955f1b3196, 64'h206d7fc202296dee, 64'h152055b750604e48 },
        '{ 64'h61583e826de72d3f, 64'h601028c2502d2695, 64'h09d5075f48d00682, 64'h76cd5b7837be434b, 64'h41f91a9d289a3517 },
        '{ 64'h31b7453f5f617fff, 64'h498b4164184d6464, 64'h291e4d9f7ef96985, 64'h5c87204020c71650, 64'h01ca06c85e7f2c79 },
        '{ 64'h679e19a0213819ca, 64'h0974580a567c13ba, 64'h0cb4405777a71140, 64'h234a385b209016e9, 64'h77615a1e796b0929 }
    },
    '{
        '{ 64'h3f8f3cb632bb0271, 64'h4f6e7fcb05ab5851, 64'h77fd44d142b92406, 64'h1685458408046940, 64'h45c8002b2f015eae },
        '{ 64'h588758113b213214, 64'h5d471a391bae529e, 64'h0f553a4e44f63574, 64'h59085bd964ac488e, 64'h4b467bb7358b07ca },
        '{ 64'h2e494dc9363c683b, 64'h0fa322ed477a0dc4, 64'h71806b2d75747ee6, 64'h7f2c283770734ad7, 64'h6ad5640d78bc55d4 },
        '{ 64'h58917ffe41b83fb7, 64'h7aa36fd5105218cc, 64'h42fa355018a158e1, 64'h4dfa2fd45ec74c9c, 64'h6a7f145e1f196d12 },
        '{ 64'h631f21bd01805594, 64'h6cb064ff1c1e4bcc, 64'h5e0a222909350e0a, 64'h150e352b14455bd8, 64'h2ce87f1242756cd4 }
    },
    '{
        '{ 64'h699033803a3449bf, 64'h7c971a594e203bd1, 64'h072019c02f27464f, 64'h7d2d1c4209ec5e60, 64'h4e1c2750136c551d },
        '{ 64'h767135f348e127e7, 64'h5ed52bbb66e72afd, 64'h2c5f73f95bdd424d, 64'h6613212d398e1c8b, 64'h13a820c26a102481 },
        '{ 64'h398f56f92bed1ca6, 64'h56303724198118f1, 64'h44772c143fa34aef, 64'h278f64d407885414, 64'h43ed599877e3124f },
        '{ 64'h69911cf011511ae0, 64'h53884d4149f5576e, 64'h20b63a766c5f7954, 64'h49d213f35db3373d, 64'h38b232ca0f0708f0 },
        '{ 64'h64c954321e0c556d, 64'h18ee583568f14738, 64'h465e58a819843af5, 64'h09052c606b9b7c35, 64'h40f92aa332b24490 }
    },
    '{
        '{ 64'h654842dd62d530f4, 64'h73f33c9420c1213c, 64'h233a339e1d463604, 64'h381a24923fef60bc, 64'h26151d7c64e539fc },
        '{ 64'h5c3166d532111217, 64'h634338b247816ff3, 64'h316d503b4f0d7218, 64'h56e6795f2f3a4606, 64'h67f960c6655e29cc },
        '{ 64'h485142074b052bd6, 64'h3b73461c4a941d07, 64'h5e8c2613472c6908, 64'h6f6d66053bd148df, 64'h04d43c4c55cc03c3 },
        '{ 64'h1bed78f10e4d322e, 64'h1f18016407553735, 64'h49ed34702fd36415, 64'h0e7d4a6d730e7a0e, 64'h5fdb05b877427e74 },
        '{ 64'h05dc47602f8e1503, 64'h5e1a5c22450d5473, 64'h2e3f15981b44494c, 64'h6b8003ad73bc1afc, 64'h1b67625474ef0726 }
    },
    '{ // 23
        '{ 64'h31d60f7a1869273e, 64'h10491d3844273453, 64'h0a5b544e13433d2b, 64'h138c3acd11d30295, 64'h7a417313700e6dfb },
        '{ 64'h540c06fc70b05637, 64'h7f2e735716a006a7, 64'h5d5a079755d03c84, 64'h2bbc6dcb4b650e6f, 64'h1c3a6ed14119724d },
        '{ 64'h13fa46c67fdd5555, 64'h33241dc035c27a67, 64'h09e978c0731912a0, 64'h1ec436e202d9442b, 64'h29ff6ed72242135a },
        '{ 64'h2a7a40955bc061f5, 64'h37a86f4d091278d2, 64'h34da579e40ab4fa5, 64'h49c016083259071a, 64'h442c71a337244921 },
        '{ 64'h471a5f1118790389, 64'h6aee2fb1528830d1, 64'h32fc411555ea233b, 64'h7c4d40b70c870621, 64'h49a057e725b7098c }
    },
    '{
        '{ 64'h57c257356e34dcc2, 64'hd264544a03c85997, 64'h5dd10d1bf83bba4d, 64'hb8cdb4de869db4eb, 64'h5299e547f7c5e30b },
        '{ 64'h38c2f02bc5d260a6, 64'h565f4d213efd8682, 64'hf8c08b1bae2847ea, 64'hb95a6f920e41dcef, 64'h2a144efc4c5dc0cf },
        '{ 64'h6debd32740aeb103, 64'hbaea67a8d4404ea8, 64'h5445c3dbc6cdf5eb, 64'h7663fb850f730bb4, 64'hf2867513f8df10f4 },
        '{ 64'hc050ec1ada472d68, 64'h7ed6d143e9db13b1, 64'h6139686510cf97c5, 64'h006cf2442659c24e, 64'h9a80b9734bec13fb },
        '{ 64'haba415406699316e, 64'h86547f19e954d2c1, 64'h813d4600570c86b7, 64'h7c3454b2a3079c87, 64'h7ce4b36d3a6dacdd }
    },
    '{
        '{ 64'h035197042dc68a50, 64'hd56db727ba9b5015, 64'h921c523fa32c640e, 64'h7938a38034b25387, 64'hed80461e03f9bf80 },
        '{ 64'h9f487e4f5f877b44, 64'h5743b0d5020f4de5, 64'hefa1df8003d3dd15, 64'headbd6d12bfffad5, 64'h26aaee600ea03545 },
        '{ 64'h14d933a9eabb0734, 64'hd2c502fe20524c85, 64'hbf03997845350ac4, 64'hf3c49c28fa829198, 64'h5dd94f179c6e8d9b },
        '{ 64'h122d67c4f2be929e, 64'h56d73da88423d138, 64'ha5b9d0b46e4b89e7, 64'hd0c752baa4ef5470, 64'h500d3257a76fa6cb },
        '{ 64'habb7b19323d626c0, 64'h5e73e2d6ee2c54f9, 64'ha2df2a9d4083cb57, 64'hd11bed746dc096ea, 64'h2400a2f5d3e32158 }
    },
    '{
        '{ 64'h35a0681428f5db6f, 64'h2775ae6564fee7d2, 64'h1db01ee5cff2b12a, 64'h668ad3f9b2ccc67b, 64'hb58597916582936f },
        '{ 64'h79190509b1db50e5, 64'hce287a49f3b9c98a, 64'h84b64925489cdefa, 64'hffc5ca3379b651bb, 64'h0f7d08569e616971 },
        '{ 64'h199833e50dc8435f, 64'hd282535c21147e22, 64'h395991235b9d3bac, 64'ha912fa10d9bd923f, 64'h641fb90362c7ac08 },
        '{ 64'h25e7d8fbcdd37f63, 64'h5abca9d9aecf338e, 64'h360ae3cf08c37543, 64'h85fafe76fe7a5f29, 64'haea712eeb7bc04b2 },
        '{ 64'h7bfe9aca8faf34f9, 64'h978cf2c0a2206045, 64'hb06e0ec276618c0b, 64'h7ad1a3c28a98258e, 64'h2f7c05da4ff80f05 }
    },
    '{ // 27
        '{ 64'haa1e82aba2351fd2, 64'h662e26e45bcc4772, 64'h0deefaba75ebe56d, 64'hf255f6618cd2de62, 64'h4aada952df8a1f39 },
        '{ 64'h06b37aaebe443096, 64'hedaaa7d157a5773b, 64'hae39d8eb76207b0a, 64'hb2bc38b2c172d6f3, 64'h10fd9e232bb9a54b },
        '{ 64'he026548a8ac03856, 64'h360783809093ce0f, 64'h3de0affdca0e16f5, 64'h7946d95a69a70404, 64'h926cbf558339b6ee },
        '{ 64'hcccca1038f5dca43, 64'hfa45ebf37b3b7a54, 64'ha4acd1e220a5f72c, 64'h532e80a58a926c4d, 64'h4389ca2af2e2add7 },
        '{ 64'hf6d2ccc18fe7143d, 64'hf359c9e0674cef16, 64'he38b8119ed23dc0b, 64'h1670a3db48386192, 64'h17c6ee54ee610ae0 }
    },
    '{
        '{ 64'h4c96181581db50fd, 64'h2c9d7d92729f5390, 64'h800dbffd319591d9, 64'h86ef3860a7c1e808, 64'h4216cb18013237db },
        '{ 64'h314c3724282ec1f8, 64'h3142815b7caadffc, 64'h11a0cc78a3bbfbb1, 64'h1017d3218d43a3b8, 64'h52c802fbc5f27178 },
        '{ 64'hfd3a55112dcd5714, 64'h3603524b47c9aa1f, 64'h9cccfe9b55ccf551, 64'h041425ad1caa07a6, 64'hfba858cffee5f72a },
        '{ 64'hcecbb810a9e69fc6, 64'h4ed1befdd817fc21, 64'h6d4ac095e194a03b, 64'h7b82522e6c92091e, 64'hcd6ea9b49e73a0bf },
        '{ 64'hdcdab1e6b10d946f, 64'h36e111ce3d989cfc, 64'h593bbb83fec9aff2, 64'h17227b8b728849f6, 64'h677fff60bc658fc8 }
    }
};


localparam NUM_BURSTS = TESTS_EACH_BURST >= 1 ? $size(give, 1) / TESTS_EACH_BURST : 0;
localparam VALID_TEST_COUNT = NUM_BURSTS * TESTS_EACH_BURST;

if (NUM_BURSTS < 1) begin
  initial begin
    $display("Not enough test values to make even a single burst!");
    $finish();
  end
end

bit start = 1'b0, done = 1'b0;
assign sample = start & hasher_can_take & ~done;

int dispatch_index = 0;
for (genvar loop = 0; loop < 5; loop++) begin
	assign rowa[loop] = give[dispatch_index][0][loop];
	assign rowb[loop] = give[dispatch_index][1][loop]; 
	assign rowc[loop] = give[dispatch_index][2][loop]; 
	assign rowd[loop] = give[dispatch_index][3][loop]; 
	assign rowe[loop] = give[dispatch_index][4][loop]; 
end

initial begin
  $timeformat(-9,2," ns",14);
  $display("testbench start %s round, burst is %d so dispatching %d/%d",
           TESTBENCH_NAME, TESTS_EACH_BURST, VALID_TEST_COUNT, $size(give, 1));
  #150 // wait for GSR and other nonsense.
  reset = 0;
  #50
  dispatching = 1;
end

always @(posedge clk) if(dispatching & hasher_can_take) begin
    if(~done) begin
        if (start) begin // 1 clock sample pulse
            dispatch_index <= dispatch_index + 1;
            done <= dispatch_index + 1 == VALID_TEST_COUNT;
        end
        else start <= 1'b1;
    end
end

endmodule