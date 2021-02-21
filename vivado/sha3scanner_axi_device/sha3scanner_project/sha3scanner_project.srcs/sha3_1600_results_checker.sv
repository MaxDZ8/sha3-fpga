`timescale 1ns / 1ps

// Spiritual companion of sha3_round_dispatch_logic, check the corresponding results.
module sha3_1600_results_checker #(
    TESTBENCH_NAME = "<FORGOT TO SET ME>",
    // See the dispatch logic for this one!
    TESTS_EACH_BURST = 0
) (
    input clk,
    input qsample,
    input[63:0] qrowa[5], qrowb[5], qrowc[5], qrowd[5], qrowe[5],
    input samplep,
    input[63:0] rowpa[5], rowpb[5], rowpc[5], rowpd[5], rowpe[5]
);

if (TESTS_EACH_BURST <= 0) begin
  initial begin
    $display("You forgot to set burst");
    $finish();
  end
end


localparam longint unsigned qexpected_result[29][5][5] = '{
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
    },
    '{
        '{ 64'hc4d1fa6a6e5c49d0, 64'h6f3f75ac3c2873b1, 64'h3d170aee6ed8d6e0, 64'hde5d8e8303828ff3, 64'hd74df092f9b82dda },
        '{ 64'h6f122104f5343a08, 64'h28f8a543115c3883, 64'h9d8a6cad90b3b212, 64'h16d707606f23e76a, 64'hc2205a0f40406e98 },
        '{ 64'h15009c518626476b, 64'h654fec8209e2442a, 64'h0d5f5e0952e1adb1, 64'h25d6a524983339ae, 64'h67e08d166196fa78 },
        '{ 64'he442350be3eb597d, 64'h0f42d79762b5dc54, 64'h4a4072c4a1482c66, 64'h09be927e3fd32765, 64'h28e2b9d00fc561d9 },
        '{ 64'h830238c61ef40f2b, 64'h64167fbc2a9f6e52, 64'h3bb8362549264b7b, 64'hbce5690f2536d548, 64'he551069250675c9e }
    },
    '{
        '{ 64'hebbdaf2b750794f3, 64'h7c1d5fe277fa0989, 64'hef159ca942c6ee99, 64'h03eb93300bb5e614, 64'h5170757b95fbef46 },
        '{ 64'h4effcb37f9dfe252, 64'h2c13c1431fba030f, 64'hb1ca3724db1b3e72, 64'h4277030a1473a1f6, 64'h0d389743387c0ea8 },
        '{ 64'h633932054d978b91, 64'hb895b71a1ab71e2e, 64'h7d0079f5f1cfcfab, 64'h733293724ccdefd7, 64'haed203c1460ac404 },
        '{ 64'h09b1e2abfd811791, 64'h589f3c3ebd5f5c91, 64'h0786209cab3df4d6, 64'h0c26c15bb4805037, 64'h021b6614a300c610 },
        '{ 64'hc4a49dbb2a4fe4e1, 64'h670f189c079bb716, 64'hd4e5302680c2c418, 64'h81de69d282b5af48, 64'h81c70d3665616981 }
    },
    '{
        '{ 64'h1af18f3714edc46e, 64'ha60a56b74be8ed3e, 64'h7ea3a0f7c5a3f3a0, 64'h66e7acc089ee6778, 64'h202b80209ca86280 },
        '{ 64'h96c51425e961380b, 64'h279993c4eebba515, 64'haadc5db835636906, 64'h8840db7ed33f305b, 64'h95941791b6cb68d2 },
        '{ 64'hf66a36e1633079fb, 64'h992624dd8528aa5d, 64'h65efe2a3d7056793, 64'hb50703d5d3e8a47c, 64'hbc8d847a479e37b2 },
        '{ 64'h76314659749762f0, 64'h954508519b2cce88, 64'h5512891b905b0602, 64'h5bd9938c3e916ffb, 64'hcae24856778d2f08 },
        '{ 64'hba0c902e953b6a15, 64'he69459644c541d1b, 64'h8d4e4d298d1dd2e3, 64'h8227222c32e1b490, 64'hd3c96f2464847ecf }
    },
    '{
        '{ 64'he9408f435a3b8caf, 64'h850c2288432ea91e, 64'had416e1e234b0d81, 64'h43078bacf7d248a3, 64'h7df6975ca6a2a79e },
        '{ 64'hebe16747f594f0c1, 64'hf06afc4016604c09, 64'h909d84e0fc61b730, 64'h412d3525f30a7f2c, 64'hf0114814b9187466 },
        '{ 64'h754254d3c76be596, 64'ha568f8e35e7e4039, 64'h2433ba6d0eef6e9b, 64'hf999a7684bc1aeda, 64'hf9239447750d62b9 },
        '{ 64'hdd93c204fb3c229b, 64'hafa22161e69b6703, 64'h91d10679f4b96c20, 64'h4746471f10ca179c, 64'h99ca5e6b3ba4601b },
        '{ 64'h1da81dd2f5e7814a, 64'hf7ee9f522c29c64e, 64'h042a5ecdfc8f162a, 64'he207bbcafee7c364, 64'h6fa99e0f202afae5 }
    },
    '{
        '{ 64'ha172c7a6b74afe4b, 64'hebbbb27b03caae38, 64'heabea7254599bc5a, 64'h43fa04566328678b, 64'h4a32e585795110f8 },
        '{ 64'hb5f00997e8d85f24, 64'h5287130c4ca4c44e, 64'h500be4670af61a5c, 64'h0b5918b47f05fbb0, 64'h314c48093b911f41 },
        '{ 64'h2bf2bc467200da8d, 64'h10ab7b58d8e844d4, 64'hd30982912303137b, 64'h09ea59f1d6cefa64, 64'h54b74446b3235f06 },
        '{ 64'hdc714bcd4f8b24ec, 64'h66a5b408a8b77d58, 64'hcddaff4d3f033611, 64'he7be2bf5028ad7c8, 64'h17acaf7e7f938210 },
        '{ 64'hcbc71955865cde1b, 64'h068edd2003801a1d, 64'hf7c9368400213efe, 64'hc41f81b845e7d849, 64'h3ab843feed486e3c }
    },
    '{
        '{ 64'hcb3c49e40e33fc86, 64'h2f143484819cb520, 64'h4a1855abfa542e94, 64'haca0d9f4ac77c051, 64'hc4a901c52cd28a52 },
        '{ 64'hcbabdca283bc8b5f, 64'hfd46471d435c5da8, 64'h6b3ab2fff902e1b7, 64'h6d64fd50c2be6b68, 64'hbb8de28c3fd08652 },
        '{ 64'he5c0dcc7d3311bdf, 64'had03fc593e0ce379, 64'hcc9a8868f58a61e4, 64'h21f6b59d79d1fdd2, 64'hd43f84043785a36c },
        '{ 64'hf316255d5d1c1c11, 64'hbb2e2c4ef139bc90, 64'h9b20f6487a279c2c, 64'ha7f9a5b222cea012, 64'he1eb24470c36b969 },
        '{ 64'h15f3084251149c02, 64'hfc4f5f5c591330b1, 64'h09375feac1162b8f, 64'h281523513b9c1206, 64'hd7c7ba821c462c6f }
    },
    '{
        '{ 64'h749804acd3b6427c, 64'h9a0d905cb45c2635, 64'h72bde12c0414b5d2, 64'h13ba6c49aebd4f69, 64'hfee3d6430d6a92d8 },
        '{ 64'hcb73c50b0b9020b3, 64'hd126872c0348417c, 64'ha7424141657c16ca, 64'h0b5b28fdf5329640, 64'hf5a0ee345e2673b1 },
        '{ 64'h0e6343e16de83810, 64'h7538e08df74ffa99, 64'h3c73c87b50890e0c, 64'hdf495260bd0ca3bf, 64'h0cee34dee1657f45 },
        '{ 64'h9c4d5ecddb3c9373, 64'hd50e525e84fe9110, 64'h23e7aa027e97e94e, 64'h591d3af129eb6a50, 64'h8db7f0ba788b654d },
        '{ 64'hcc768a9bc46ee4d7, 64'h63ee7f525a2d909e, 64'ha411b40e0f421031, 64'h16c5fc27d69ff22d, 64'hf77f9c283e72a950 }
    },
    '{
        '{ 64'h1ce02f77630abcd0, 64'he851087f00317d94, 64'h60b9b872e8e1b7d2, 64'hf2f1fd7d4f7a8bbb, 64'h542545d4b07d7f75 },
        '{ 64'h7ea36a9238b075d3, 64'h4f0ed0a859a219c8, 64'h09c4e920770c86ad, 64'h8cd77ae45414b6a3, 64'hae41ecd6dd717bce },
        '{ 64'h4d9b183b95423ea8, 64'haec2c53c0c783aff, 64'he81295f3944733f7, 64'hcaa6b0bca587d0f4, 64'h11b2c77c5e5bbc3c },
        '{ 64'haccf21718bad92db, 64'h0057b9f723448223, 64'h3727faf5ef7ab1d4, 64'ha3c5f6e30f6eaa1d, 64'h24ade96423cbbff9 },
        '{ 64'h498a44dcad4be9db, 64'h56e7f01139cae190, 64'h9efcb46b1a771671, 64'h7c9873469d28dab1, 64'h92faeb3a1ab2876c }
    },
    '{
        '{ 64'h345254b94e0911fd, 64'heb77d056bf6062df, 64'hbd96717741fca0f2, 64'hc7d2bd9bd8694fec, 64'he09399731e922029 },
        '{ 64'h3be82c4d3205e64e, 64'h4f9b90bb09cc5cd3, 64'hc8973003514be3f1, 64'hc8bfb598a8268144, 64'h3de0531e4b814c53 },
        '{ 64'h90d725a56530ce2a, 64'h5dec2a06b608bc59, 64'h16eb1d2f6eaa2a4a, 64'h65f28cbf072a4c07, 64'h10527e310a8b6cc9 },
        '{ 64'h2d2aee12da3cbcde, 64'h54f4be97aa5f8b1e, 64'h46ff634fc14fd1cb, 64'h424c0bb98c3df59f, 64'haa37ca48c741661b },
        '{ 64'h1d8b9bee4912cd7f, 64'h6aa640562e98ddde, 64'h3021608954bd4277, 64'h49be4a860ab795e7, 64'h4ea0a9b9de2f91e0 }
    },
    '{
        '{ 64'hc8526205dbfc3e39, 64'hb8abb03d5bbad619, 64'h85a7f58ecd3c9cd4, 64'hfafc6ea8c0074a47, 64'h4802ca9cebddad62 },
        '{ 64'h42a152da8559c032, 64'h935c2336aaa912ed, 64'h595fbacea080e521, 64'he344c9f75f0a06e3, 64'hcce3de8929a3c988 },
        '{ 64'hdd02ed807cc569a2, 64'h26adbaf457d43765, 64'h75feb3d37a06d68d, 64'h41548a37d1809ea0, 64'hd342244b44a44dd9 },
        '{ 64'hf74159a111231572, 64'h46fd167308cd289b, 64'hafb35d58a0f52678, 64'h9a985f3429c75832, 64'h7996ad96e5a2bcc3 },
        '{ 64'h834bc44ec14fbaec, 64'h4e3f6812a53b7d06, 64'hed9120a9ce8ff505, 64'h41b9f64d60511602, 64'h7e1097fc5415e2f4 }
    },
    '{
        '{ 64'h57d46d862b185873, 64'hcf156a294b36cd28, 64'ha50dd1a3275b8846, 64'h0c71988334f2b3c6, 64'hb9a1e8ba48f106de },
        '{ 64'h63fb49f472020d24, 64'h67c97ad385508de4, 64'h64e58973a79b9361, 64'hb6f8e2b134e3417e, 64'he10077727c1acead },
        '{ 64'h276b04d28b5f58c5, 64'h82f2d5f1c12d9434, 64'h6a2172a82daebbb3, 64'h1aeac46cd8d81133, 64'h2659c50ca465d6c3 },
        '{ 64'h851315fcb3898c6c, 64'hbf2f7e696b3452e3, 64'h98b58dd4cada27ab, 64'h4f902feafce33f53, 64'hecd7541a17d715d6 },
        '{ 64'hdf631cdf23baabf4, 64'hf3c209232ab23f02, 64'h15f72c55d88ecd4e, 64'h695e8f01067f08d7, 64'h28c9369a6e2d3266 }
    },
    '{
        '{ 64'h6240102d6df6af02, 64'h08a93dc06bd1e9b1, 64'h018b0a9f086f7e0d, 64'h6e088eb3fef8a399, 64'h7b7f25de172c7b7a },
        '{ 64'h20f3b529502da6af, 64'h305f5904655dc36d, 64'hb144d0f277e810b6, 64'hcae6c3087d44aec7, 64'h8e34c01c47e25311 },
        '{ 64'h3d1aca78ba6fd68e, 64'he3dcc311e1002f50, 64'h61338aab5f9974d9, 64'h23cc019f16e5ff19, 64'h12d5730ebd7dcc3d },
        '{ 64'h23a57384e84a9dc8, 64'ha7d9a06a9caabcc7, 64'h75d1ec6899dea570, 64'hc551c5caeb96f11d, 64'h4249441e9953a2d7 },
        '{ 64'h659c8e407c9272b2, 64'hdf175c0993a1a3cd, 64'ha5bd316a0eed5729, 64'hf851ed655a7db997, 64'he597ba2e3cf0713e }
    },
    '{
        '{ 64'h4ee6c8f5e773bac3, 64'h4423e39e784de064, 64'hbfa9104fec02b1ab, 64'h88bdcee660ee1296, 64'h51d154e013a1eee3 },
        '{ 64'h80a6b2e65480b23c, 64'h6fc504874713d495, 64'hb5a71b11511130ce, 64'he8cd2e521c4f3538, 64'h125d06494f02a680 },
        '{ 64'he062db86f4f8505f, 64'h4f1206860d467712, 64'h4ea5dba63b1bb1ac, 64'hc59b11a86447555a, 64'h3baedbe42f739c9c },
        '{ 64'h08f3b8d812d65e52, 64'h7f2cd33324889ebb, 64'h2d7edcaa7f8875b2, 64'h9b9741e0fc7bccc0, 64'h4b429eebc0e0bed1 },
        '{ 64'hfc1ab144efe07c17, 64'h4bcd116222644129, 64'h7a18db7b98f415f1, 64'hac2903fd1d7aa5ed, 64'h018f00ab03e2c8c0 }
    }
};

// Note: in line of theory we have the same inputs so quirk test count is as proper test count... but we don't know so I just double the check.
localparam QNUM_BURSTS = TESTS_EACH_BURST >= 1 ? $size(qexpected_result, 1) / TESTS_EACH_BURST : 0;
localparam QVALID_TEST_COUNT = QNUM_BURSTS * TESTS_EACH_BURST;

if (QNUM_BURSTS < 1) begin
  initial begin
    $display("Not enough quirky tests values to make even a single burst!");
    $finish();
  end
end

int qresult_index = 0;
wire[63:0] qresult[5][5] = '{ qrowa, qrowb, qrowc, qrowd, qrowe };

always @(posedge clk) if(qsample) begin
  for (int loop = 0; loop < 5; loop++) begin
      for (int comp = 0; comp < 5; comp++) begin
          if (qresult[loop][comp] != qexpected_result[qresult_index][loop][comp]) begin
            $display("ResultQ[%d][%d][%d] !! FAILED !! (expected %h, found %h)",
                     qresult_index, loop, comp, qexpected_result[qresult_index][loop][comp], qresult[loop][comp]);
            $fatal;
            $finish;
          end
      end
  end
  $display("ResultQ[%d] %t", qresult_index, $realtime);
  qresult_index++;
  if(qresult_index == QVALID_TEST_COUNT) begin
    $display("%s GOOD (QUIRKY)", TESTBENCH_NAME);
  end
end

localparam longint unsigned expected_resultp[29][5][5] = '{
    '{
        '{ 64'h30ce10fab53edc10, 64'h79eae51020809c25, 64'h1434c599f6dd7704, 64'h2ab140cee52119a0, 64'h493566c52bdbd9e4 },
        '{ 64'hb8f3f6c2055ba979, 64'h9ea2cbafcf563655, 64'hf23f8d657bcf3dbe, 64'h14e6a0a54cfd02ea, 64'h002f6c5e6f768feb },
        '{ 64'h6d706d2b1884ad84, 64'ha5efefad0e271377, 64'h033d02e40826f4b9, 64'hdafc5c07cb20b5a3, 64'h7ac687d5114a69ce },
        '{ 64'hdf963fe968824a46, 64'he60297bdf1d81cce, 64'ha5f279173e8f527b, 64'h4ed4e17985d760a5, 64'haa67bd7f70246a18 },
        '{ 64'he67fbec174d20ae5, 64'h165953aa7644d3f1, 64'h1eb733145a77aa65, 64'hfcf42764ac9be404, 64'hb9628548c5064c80 }
    },
    '{
        '{ 64'h3c0ef4d6695ce44d, 64'heb08357ccd9b1d35, 64'h855c49696327b530, 64'h92fadcdf0c3c1ceb, 64'hc21be9c02e5c2f22 },
        '{ 64'h83f0672808b1b2d7, 64'h6066059f1f99ac94, 64'hd60ca610c0311570, 64'ha4e24dca66267a26, 64'h0eec6d27c96ca08e },
        '{ 64'h1b3ca399fb3b30c9, 64'h511ea884c3b4cbb6, 64'h403f59e5e979ec7e, 64'heac6f13bca9a2c9b, 64'hf3fcbd06437ad84a },
        '{ 64'hec8ab43690b7f9a7, 64'hdf2f11bb005576a9, 64'h719482dbb021d5ea, 64'h4ffe00b702b71a22, 64'h56c4bd164327dcce },
        '{ 64'h8bddee04cae996d9, 64'hdc2c364a6a001a10, 64'h68c468befaf1e86e, 64'h15fd01bf51875e9d, 64'h82b05a64eb0bd610 }
    },
    '{
        '{ 64'hae246f09a1fda431, 64'h53efc9f261faedcc, 64'hbcc77e2a60795f37, 64'h8bb6ce23370254ad, 64'h5188f1b333709c88 },
        '{ 64'h68a5fbefadfd72e1, 64'h23816bd8ff39f0fb, 64'h01d52cdca6d805eb, 64'h96a80fd170812c1f, 64'h1db3a40cee1e2975 },
        '{ 64'h521764bc44a88ade, 64'h3858c955d782226f, 64'h60960307fa92968f, 64'hb259b86d7756cecd, 64'h5a9d8a778e021360 },
        '{ 64'h1d4d512fea371a88, 64'h3936b8d3cfbe10c6, 64'ha47f111f4d4066c3, 64'h1c4e92d7964ae9c9, 64'h0372e2252ece62fb },
        '{ 64'h11ec4b428133d6f7, 64'hbf7cfd8043ffe741, 64'hfeb27b1a3dc7095e, 64'hc296ff994cb45afd, 64'h0cacea4a3d708052 }
    },
    '{ // 3
        '{ 64'h00e414a80c2bebc8, 64'h5417bd2253870ed7, 64'hacb8d2f680d429b4, 64'hea37faf2894406c9, 64'hca7db89a780f9e3b },
        '{ 64'h24addd032d5961a2, 64'h8f8e5a3b06a352b6, 64'h7011272d41d980eb, 64'hc80b1ff8dc585465, 64'hbd90a0836a9dd0d2 },
        '{ 64'hd217b9774ec89576, 64'hb3e9b90eabd312ea, 64'h158b0de4415f3118, 64'h93f3f36afefa9373, 64'h1dd3b033bed0dbec },
        '{ 64'h484531511867473c, 64'h0083fbf09674053a, 64'he7d232536bf5452b, 64'h78753057e3900bcd, 64'hd39a9b5434116280 },
        '{ 64'h742d780dd73e0e8b, 64'h3d078c136a2fbd71, 64'h05e7b25abc44fdcd, 64'h99ea9dc84b8a2703, 64'hf7961c43d6eab834 }
    },
    '{
        '{ 64'hefc054d988fcbd96, 64'h2d8618c8512958ee, 64'hf4208b1150a79bc0, 64'h7ff9d35cd2703d75, 64'h88f69a10215f52de },
        '{ 64'ha675128197727978, 64'had12de3858d452b0, 64'ha364bbe3f32f6f2a, 64'h951ff7623315393b, 64'h673e3b3aa1e3a47b },
        '{ 64'h8130b1c319b14714, 64'hb903d16a89a67836, 64'h7750e67be0bd6f25, 64'hc4cc85138dcb82ba, 64'h7fa28c27015abd8e },
        '{ 64'h3ea8e0c7bcbef53c, 64'hdcb19b7cf8af303a, 64'h6126bec908bc4c59, 64'h77796d341a887a54, 64'h2cb5b2bc54eeb539 },
        '{ 64'ha7847c847f8313fb, 64'h37148624cc047489, 64'hb8117801a58f9edc, 64'h4f0437bd6f368c36, 64'h3e8a18e8fe73e7b8 }
    },
    '{
        '{ 64'h96a96b474c72b2ae, 64'h53111835de4c816c, 64'h9acd475ac3ec9f2c, 64'h2c13e19c7d766296, 64'h8cdae330453703e5 },
        '{ 64'h29f0ac5a59b09e47, 64'hf8ed907cf4e4c4fc, 64'h020e02f195180aa2, 64'hbd7f2243a350da66, 64'h35fb6451ae748ff1 },
        '{ 64'h48cc59861d2713a2, 64'h65b23bc181dc04b3, 64'h179a7fb9ba6a0926, 64'h8f8b5e4289a26733, 64'h8fbdf61cc30c388d },
        '{ 64'h399d49dcc8d16f61, 64'h6cbe043614cc95c4, 64'h6b9d7f86c173887d, 64'h313fe9b1712fc94e, 64'hf0b78789967d429f },
        '{ 64'h81f865461040a20e, 64'he9237db0082f9dae, 64'h5b368bd240f0dd42, 64'h4d2424398be6cc4e, 64'hf0ececdd6e335075 }
    },
    '{
        '{ 64'h397524ae22ce1671, 64'h722e33e2b488a24a, 64'h98264e8e6d852e64, 64'hae64754759f7f3a0, 64'hdfdcdc3ff1035e62 },
        '{ 64'hddf8b11e0230ab26, 64'h04e0f65a9358c4b1, 64'hc8f67a850e5e220a, 64'h748a069109f333ae, 64'hc1b3d76aabaa68da },
        '{ 64'hc9ec002559d67fbd, 64'h98ee59a9a1fe0492, 64'hdcd27473949bf639, 64'h2298248283414bd8, 64'h662dec90566199ae },
        '{ 64'hc213a605b5c05d96, 64'he80cd77bee0bbad4, 64'hf89b2836bf904bae, 64'hf3b283fcdf520fc8, 64'h8ce03436c067f81d },
        '{ 64'hc3a19601eca12d4a, 64'h7573fddb1f3a4d78, 64'he766198a8ec73b6c, 64'h27fd2f28fd735c59, 64'h7b0b3e59681a862e }
    },
    '{ // 7
        '{ 64'h3b09a563c2ab0ebc, 64'h51fd52e0d60efa3b, 64'h95e344f785173ceb, 64'h73bf16056b59d5cb, 64'h430bf0fb40693fa2 },
        '{ 64'ha56d9d48f6a6eb92, 64'h1548b0818fccdf58, 64'habc8957fa68def94, 64'he09dcf4d80ec280e, 64'hb7efde7e11081c5e },
        '{ 64'hde55c9b60fc40fa1, 64'ha301b18905c5ac9d, 64'h64c3212e75e25898, 64'h1318243e0b0a9311, 64'h3872f672dc478dde },
        '{ 64'h0dcf94604bc8d720, 64'h33f5cd0c25092bc2, 64'hb6b7e6145f84c78f, 64'hb69de0aeb3588d8c, 64'h70e73ef3a03d8814 },
        '{ 64'h3f862d4bff487a3a, 64'h8df24f0a0414dca1, 64'h62d9be6e31381a3c, 64'hc807155419020dcb, 64'h7bd58d7571c20b01 }
    },
    '{
        '{ 64'hd48c02be088646cf, 64'h769a0cf19d643874, 64'h9d6eaf4de574b91e, 64'h66a3dd7260a21de4, 64'h9e46788503f528e3 },
        '{ 64'hafab51d09acd5160, 64'hc6e782210e690132, 64'h08e90e31c424bfe5, 64'h4928d0f77766fc3a, 64'hbbc5010e046c6eeb },
        '{ 64'h9d0043b81399aef0, 64'h9468369aa43af246, 64'h044061feaa3fcdc1, 64'hc7fef5ce7c326dd9, 64'h41375f85063aa65f },
        '{ 64'h02e342213af04e1f, 64'h6d7061938a52dbb2, 64'h6848345f08f5b896, 64'haa90b21e8538d385, 64'hc759e59f1fddd88d },
        '{ 64'he8e1d7f0a7b489b9, 64'h7295a153de3bdac1, 64'h0539acb47d58a66a, 64'hcc3346a835ccc0d0, 64'h6f8379edf636df22 }
    },
    '{
        '{ 64'h83b0b30dbcd658cc, 64'h9bb41f2f6961e6dd, 64'h9209a084ce196415, 64'h5d786565884379d6, 64'h63c0de29fcd38350 },
        '{ 64'hd9540191a11d05da, 64'h7a07ab486d24f4f3, 64'hef17375605ed15c0, 64'hc51d673a3e0faea9, 64'h08bdfa7d30582a09 },
        '{ 64'h417a6e29d121412b, 64'h9ea0a362f2a3d85c, 64'hc79d10d028d347c3, 64'h25692e9a0155b322, 64'hf94cb56816c2f2f0 },
        '{ 64'hede70514bdaf2d64, 64'h138d4ad8d476e739, 64'h5e78385e0260b2be, 64'h6c558eb75e04d745, 64'hd4fb6290092df3a3 },
        '{ 64'hbbdbc8e721ea9e90, 64'h698733239b302395, 64'h19c8f45c09ed8893, 64'hd69a3cc09114ff1e, 64'hf66e4db6370553ff }
    },
    '{
        '{ 64'h7c8145ed91e40f8a, 64'h60ad1508fc12abc2, 64'h30df9121e73bb92f, 64'h7dd2daa75ded67e9, 64'hda8035a1629d4ac8 },
        '{ 64'hfc53584d028ccc9a, 64'hdc56a43d8f955196, 64'hbc177ef6563e70db, 64'h96eb2215140f625e, 64'h1d5f8b78ec638f28 },
        '{ 64'h04f91d5894cdc494, 64'hcac8a6f3d60949f6, 64'h224fea36941968a3, 64'h21b1fb7ef429a017, 64'hee9e0dc6b1cc7dda },
        '{ 64'h65bf77d2cf97ea4a, 64'h390004e88969f68f, 64'heabe3d07c9e1c87b, 64'hf6991421b97f283b, 64'h625582531651dd8e },
        '{ 64'hd67ab2f6867b180a, 64'h9c7c3dab91cc83dd, 64'h205542d179831548, 64'h476db89a401cca59, 64'h0c3c165633bc3de6 }
    },
    '{ // 11
        '{ 64'hae911c424fd9fa28, 64'h0ce47a41eb0b73ea, 64'hd2e2725b7a78c43f, 64'h1d2610d84fc6c6ea, 64'h7466effc7a43cedf },
        '{ 64'h5a20e0deeaee8008, 64'ha0bda034e89a98c2, 64'ha411f324f23706a9, 64'h6e022ce95c97886c, 64'h3b8d0fa41b18562b },
        '{ 64'hb550c112215083b3, 64'h1b2e075db4ec9e73, 64'h9da0d60eba61c191, 64'h06515c01783bb599, 64'haef2ffc9178a9465 },
        '{ 64'heb5744c98b6688dc, 64'hdccd19ac200d10c8, 64'hd4c4615b85e7c196, 64'hfac73b952417dc77, 64'hdc33e36b75fc556a },
        '{ 64'hc1ad7ed3d875451c, 64'h7d47c81b9d8ea466, 64'hfbad7ec3a773f205, 64'h808f83a5f47328f1, 64'hfc01fb0b5a845b89 }
    },
    '{
        '{ 64'h1cc51eb27848a3e4, 64'h6ba1adf7459c3d5a, 64'hdf850fe9707089b7, 64'hbc6ee48358f9aca0, 64'h3ce83887a592ce62 },
        '{ 64'h8a67a361719e187b, 64'hc92ac01659be8616, 64'hb0074a0dfb55872c, 64'h8660918911b16cf9, 64'h283a91fecafa7cbf },
        '{ 64'h67a7d774a82e963d, 64'h26241c0c55543832, 64'h1d724acf2c70faf6, 64'h7fbcb53660314895, 64'h4abbbb8b8d938c84 },
        '{ 64'hf8963ef30d999768, 64'h4142f01338fd7273, 64'hd175ea5660e516d0, 64'h05d8ebb90ffac61e, 64'h3ccd22207d09abc3 },
        '{ 64'he863ab5d7a4d9afb, 64'h815b64257540fb2a, 64'h293ffbfea121c88d, 64'h05dbb285dabdb78a, 64'hebb61afd7979e383 }
    },
    '{
        '{ 64'hcc1d9cb8e4b6759a, 64'h87e91d76a57cb932, 64'hacc9f0d3ed5c80f3, 64'h6dc891c3ce51f3ae, 64'hec44e52d8e59e8c8 },
        '{ 64'h212b75f2981c4127, 64'hfd93baa5cb5a634d, 64'h2bce41eb7482fb72, 64'h5bee1495f7abd6fe, 64'h85d0c5cd46a9b050 },
        '{ 64'hd0e80ae3deb8d42c, 64'h30885c93cb503165, 64'h1f18c4a209166e96, 64'h5bfa6f314c7f31b4, 64'h34f531ff59257298 },
        '{ 64'h273d2bfb556140b1, 64'hf21a5c945842d849, 64'hf2fea2d6f13f9899, 64'hc83e353248138fff, 64'ha1077e867791b489 },
        '{ 64'hc6ad56404aaf161b, 64'h00f82a5a9e226393, 64'h3311988f9a5c5754, 64'h78541fee5f3df05e, 64'hc8413ce7e731baab }
    },
    '{
        '{ 64'h00945f18351aae9d, 64'h91d3d170429c4fcf, 64'h8440eac2ee009bbc, 64'he1b127e030365bd9, 64'h4348e2fb1d9087f0 },
        '{ 64'h841b70e705175aad, 64'hbe2c819f2ab97c7d, 64'h3e334991059d2ccd, 64'hc47ebcf81c09b3ad, 64'h8311cc8359649f5b },
        '{ 64'h372cf8d6ad05888b, 64'h24b5b526badcad87, 64'hfd3e558f592f9b82, 64'h8e77437b6ea8ef7c, 64'hd1d9705a2fdf0339 },
        '{ 64'h2ca4ab8526d6af56, 64'h4de65c0a5651d160, 64'ha1ee50533a7c063c, 64'haaa9de3865565895, 64'h1cfd9b6cf860df2b },
        '{ 64'h1b132523116b2754, 64'hf73f57fdea10ce56, 64'h8f3a4dd1e07183f8, 64'hc02799f84876cbe4, 64'h07422b2f6284e0c1 }
    },
    '{ // 15
        '{ 64'ha26cfbd8e397ea9f, 64'h6c6320046543a636, 64'h7407888160877a21, 64'h43fc285bb0345f4a, 64'h417ea520d58565be },
        '{ 64'hb20438647673f342, 64'h665afae9212e41a5, 64'hcf74c98b7a39bdc3, 64'h2ed3d447f12b5f84, 64'h728073fade3e432a },
        '{ 64'h8307e40efe554c46, 64'h9cfde5dde6b8cc1e, 64'h5731a4880af71e14, 64'h64c1603c760c5845, 64'hba5a14e6b559a04c },
        '{ 64'h1add8b7c14691915, 64'hc0edbb32607ff59f, 64'h3fede41c36468450, 64'h507b7dbe95391e70, 64'h38038635f4866104 },
        '{ 64'hf4aa12a0bb7b6731, 64'h2bea7b5b8c2065f2, 64'h56d745b3ac80ca24, 64'h5966028b8e0bf858, 64'h43a3a4435901519d }
    },
    '{
        '{ 64'hc4d1fa6a6e5c49d0, 64'h6f3f75ac3c2873b1, 64'h3c177afe96e0f6e8, 64'hdecd8eab0786cff3, 64'h7e6bf117e89a1ff8 },
        '{ 64'hfa1069a87597b818, 64'h2aada6037e5c7deb, 64'h5daa34a290f3ba82, 64'h3bc52660da17f76a, 64'hc2c8de4c40086e1b },
        '{ 64'h1d108e58d427eefa, 64'h45cf4da681f05424, 64'h4f7f561b33656fe1, 64'h35d6b5651e133cad, 64'h07afed946856fa78 },
        '{ 64'ha442154b62a3795f, 64'h0efc57ad7c26df55, 64'h6a005b44a14c6cfe, 64'hcdbe9675dff93f41, 64'h23e27b440fd1e5d9 },
        '{ 64'h98aa38c75fd40e02, 64'he05336b60e8ffa52, 64'h7aa830b5196743ed, 64'hbee7514b2ba6d669, 64'h814541aa706c3cce }
    },
    '{
        '{ 64'hebbdaf2b750794f3, 64'h7c1d5fe277fa0989, 64'hbf05f8e2d68ce7db, 64'hab6699306bb5f6bd, 64'h453225ab9f33e642 },
        '{ 64'hdf37fd1339dede22, 64'h6e26c1491bda828b, 64'hbcc2a365f317307a, 64'h00b04b3ed5f041a4, 64'h2d3897033e5c0fa5 },
        '{ 64'h26397ae0acdf4a10, 64'hbaa7351816b73e7a, 64'hf1c07974f3cdcfab, 64'h321ba3764558e446, 64'h365686db542ad02a },
        '{ 64'h0eb1e22bffa1b7d7, 64'h50bffd7da9df5cb0, 64'h059f0698a83d72d6, 64'h058641f0e80141b6, 64'h52157a00a35e8e10 },
        '{ 64'h5444bd99aa0fa4e9, 64'h6615514c05ae9c56, 64'hd4e43402e5828499, 64'hc5fef95b88bb2b28, 64'ha2cc0d3260f17a97 }
    },
    '{
        '{ 64'h1af18f3714edc46e, 64'ha60a56b74be8ed3e, 64'h7eaba0d7d1a3f320, 64'ha4b7839789a8731e, 64'h0425d0a0dfa8cb80 },
        '{ 64'h1e81581df8217009, 64'h279911822ca7b54c, 64'hbf48593911a32186, 64'h8a01db5a9a1f2052, 64'hb48c9451b051edc6 },
        '{ 64'h92a3f4c331353c79, 64'h0926258985c02a31, 64'h6d676689d3137411, 64'hf7653154f3c8ec35, 64'hb5898466c396b5b6 },
        '{ 64'h3623c75374c462f2, 64'h9f8c1ad5b5aca771, 64'hd530c149d1570602, 64'h6fc895853e832f0b, 64'h4ba64056fca5a300 },
        '{ 64'hb34694271432a8f5, 64'he4b57b607eb4390b, 64'hdc860029c91998ac, 64'haa23b226a3dab480, 64'h975926642cc06bc5 }
    },
    '{ // 19
        '{ 64'he9408f435a3b8caf, 64'h850c2288432ea91e, 64'h91b17a4e236baa9d, 64'h4306cbadaf8a4083, 64'hfbfcb774a3264686 },
        '{ 64'heb7467e71d9543f1, 64'hb14acd45156a0405, 64'h208dccf0f471b772, 64'h4acd1266b78effad, 64'he01bd014bb78786e },
        '{ 64'h755156dfc7eacb14, 64'h7ce0fde31f7ec079, 64'h2411aa6a3ae32eba, 64'hfdd9e7f8c9a32bdc, 64'h790b3c676d196290 },
        '{ 64'hcdc2c41ceb1c2abb, 64'he9a46067e6d9749f, 64'h09591e19df9d0c23, 64'h0357c71bd0d2151c, 64'hbbea7f0a3f27251b },
        '{ 64'h1da85d5f2561916a, 64'h15eb3e502e49070a, 64'h09825ac8fc872eab, 64'hf207ba1a2b22c26e, 64'h8def1c0f2822bce1 }
    },
    '{
        '{ 64'ha172c7a6b74afe4b, 64'hebbbb27b03caae38, 64'he2be46a45dc8ac2a, 64'h62be06746122098a, 64'h80bbd58c79f19140 },
        '{ 64'hb5f8edf4ea8a4534, 64'h59d70b9c39a525ee, 64'h600fa46e0a661e1d, 64'h8fe91922bf4dbb94, 64'h734b5a013fb59f0b },
        '{ 64'he8f23cc75103c9a6, 64'h184922380c24acd0, 64'h871c869702221679, 64'h22aae1f196ce7aed, 64'h44be075e3bcb5b56 },
        '{ 64'h552b0088588b26ed, 64'h4481b4b8a83fbc90, 64'hddda7b4742123601, 64'h2fef6b740282f324, 64'h35281b7edfa7db00 },
        '{ 64'h3a863bd1867dfaf9, 64'h06985c184646da1c, 64'hcd6974c2a82918ca, 64'h055899b947f3484a, 64'h3eb087deecc86e38 }
    },
    '{
        '{ 64'hcb3c49e40e33fc86, 64'h2f143484819cb520, 64'h0a1155aafad42496, 64'ha7b4d1fe7c56b459, 64'h4429b5d52d5e8b33 },
        '{ 64'hc9936c403bbe2b48, 64'hf9020a1d41e057e0, 64'hf9b3b073c44265a5, 64'h2d46e17242926265, 64'h8fc9e1917f90d2f2 },
        '{ 64'ha558dce712b31b5b, 64'h8c67c9cc365d7f6b, 64'h18938868f38e63c8, 64'h0036ed5eb9e1e541, 64'hdc3ca41c1b89434c },
        '{ 64'hf316f75d571a1c3d, 64'h9ff72dfcf1f19c82, 64'hdb22f60d76178545, 64'hb5eda4aa73c6a402, 64'he9c32c45ac1719e9 },
        '{ 64'h14c308e0d110970c, 64'hdc4f7f4d639b20b1, 64'hdef5c768c55407e6, 64'h282523117a8c8206, 64'h3fcbed9e14450cde }
    },
    '{
        '{ 64'h749804acd3b6427c, 64'h9a0d905cb45c2635, 64'h9efc732e05562542, 64'h13b24dc5fc290e4f, 64'hf5e44e52012bbed0 },
        '{ 64'hed33854a6fa43631, 64'hd93faf90934ac17c, 64'h53e287416f78777b, 64'h010829f6f4a29642, 64'he5a4ec105e6e32fd },
        '{ 64'h06204b936d683c14, 64'hb630f28d5a4b5b2a, 64'h3cd5ece510e8524c, 64'hdd481141b184a3af, 64'h7df694d27362bdcc },
        '{ 64'hbeacf6cda13dfb3d, 64'h8d1642af85969300, 64'ha7456a082e97ec43, 64'h495534b4aadff862, 64'hccb5f0a87c49654d },
        '{ 64'h48670a97c12ce4f6, 64'h712a37738ab07292, 64'h452bb40627221961, 64'h1ec5feb41693b6aa, 64'hd4f7e9682473b958 }
    },
    '{ // 23
        '{ 64'h1ce02f77630abcd0, 64'he851087f00317d94, 64'h64bdb8f258e4c396, 64'h7ab9675e44f80b31, 64'h363405d4b45c3e50 },
        '{ 64'h7e6343921ebcf3f6, 64'hcb1dc26c59b229ca, 64'h2bc46d32fe6dcfe1, 64'hdc7578e47494b2b2, 64'haf4d7cfe9c7373c6 },
        '{ 64'h0d8b08f805453fa8, 64'hac66e5302df8faff, 64'hf902d2b3ce1f1fff, 64'h86afa8bf2487d274, 64'hb3f202785663bc6b },
        '{ 64'h9bef63714797a30f, 64'h8097bdf52340882a, 64'h330ff3f1cffba434, 64'h2b87f6f2874aaa1f, 64'h24bd71e2038bbfd9 },
        '{ 64'hc19240b6af7effba, 64'h36e7b315bcc22910, 64'h1c9e3c5318e5133d, 64'h359877823861b222, 64'h849f5b3b0a32876c }
    },
        '{
        '{ 64'h345254b94e0911fd, 64'heb77d056bf6062df, 64'h9d977117476e80f3, 64'hc792d913586c5e38, 64'he9b691353ff20c2b },
        '{ 64'hbbec0c4d6206456e, 64'h4fb31523a1e85cd7, 64'hfdd7720512caafe2, 64'hcab799d998222348, 64'h79f3c3ac424954c2 },
        '{ 64'h92d4308c2d92cc28, 64'h3cfcaa96b708f85c, 64'h06eb6f2f662b0a82, 64'he5778d3b621ace25, 64'h5d7a743398835c98 },
        '{ 64'h2f21af5a9b3cec1f, 64'h54f4b627a66faf0a, 64'heecca30f820fd3cb, 64'h47442fab94016d5b, 64'hfae3dacde702651b },
        '{ 64'h0d8abb671937cf5e, 64'h23384a50249a485e, 64'h3621c1b080b54277, 64'h58b558c00ba7d9f8, 64'h2c84e9a9f8a78160 }
    },                                                                                                 
    '{                                                                                                 
        '{ 64'hc8526205dbfc3e39, 64'hb8abb03d5bbad619, 64'h85a5759ae6e439f4, 64'hffa84babd42758d2, 64'hcaa35284ebdcad68 },
        '{ 64'h0aa2ca1285592532, 64'h315c6207f5a3102f, 64'h55fcacc680212c29, 64'he144c9a5db5206d1, 64'h5dbfffad0303db45 },
        '{ 64'h8c50ec8354c7a92a, 64'h26adb2d0d6543f45, 64'he7fc979b7e2297d4, 64'h4d5443b7e9c1be82, 64'hf1ef363f47b45b9c },
        '{ 64'h5e4310a9b1131312, 64'h56f5145701cf7099, 64'hceb5fdda64d582b9, 64'h1cd90f1539c65902, 64'h792aabc4ed6e944a },
        '{ 64'h22cbc4e78bcb3aed, 64'h4e17be56856b7f04, 64'hd3912119da8b15f1, 64'hc0f2b64fe11b0e0a, 64'h3224bfec7025a7f6 }
    },
    '{
        '{ 64'h57d46d862b185873, 64'hcf156a294b36cd28, 64'h148db19b6f5a8c5e, 64'h4a2d8c87b3f26be7, 64'hb980ea931877205e },
        '{ 64'h63dfc8d450891f25, 64'hf5d118539530cdfa, 64'h25e59c31ef831de0, 64'hb403ea3536e3407e, 64'he5004571f94a4e6d },
        '{ 64'h4f6a26daa7dd7346, 64'h923851b5117d9434, 64'h4e3073a8098b7d73, 64'h1bc8c4bed3c21937, 64'ha6c9142de44552f3 },
        '{ 64'h858394683343a964, 64'hf82f5c435f154ab3, 64'h38f2ddc4c9ce272f, 64'h4e902e0e5cebb77b, 64'hd6fb3e1b5fe34755 },
        '{ 64'hdb56388bf3b66bb8, 64'h9bca8a232cc33f93, 64'h15761ccfb08eff6e, 64'hbe7c874407ed8147, 64'h084937ba662d2664 }
    },
    '{ // 27
        '{ 64'h6240102d6df6af02, 64'h08a93dc06bd1e9b1, 64'h10fc2bd3096b266f, 64'hee089c931628a39d, 64'h7fd68c1e072d3b5b },
        '{ 64'ha1f335db428db63d, 64'h7afd5a0c6d596d2c, 64'hb554d0e6754a41a6, 64'hea25f6296d490a69, 64'h9e38881862b21251 },
        '{ 64'h3d39c2d2a4f68607, 64'he110c205e164a450, 64'h7122f8abf68174fd, 64'h0ec689ef14e7ed9b, 64'hd011720ffc7de56d },
        '{ 64'h73a53f84e91e9cf8, 64'h27d9a1e8feaaecca, 64'h77d9ec7c899fa7b2, 64'he4f5f64a8b9eec15, 64'hc611c4748df382d0 },
        '{ 64'h4534af2270de2692, 64'h8757900cc3b10b5b, 64'ha03b23602a6d1701, 64'hf859e9251a7fbb17, 64'h7f94ea27bfd1f073 }
    },
    '{              
        '{ 64'h4ee6c8f5e773bac3, 64'h4423e39e784de064, 64'heee9004fff035dca, 64'hac9346f280be1396, 64'h51c071ea0b212ed3 },
        '{ 64'h1084a9f644809276, 64'h278d20c54b5dd1a5, 64'ha7b71b181211b24e, 64'h686f9ef40ccf2504, 64'h7d1c02484c11e201 },
        '{ 64'he0c702a6c6e1d0f3, 64'hce08068e49023340, 64'h748111e2302b3928, 64'h05db11aab4cf1519, 64'h34bedfe42675bb9c },
        '{ 64'h08a1b45049d63f52, 64'hedadd273a4fb16fb, 64'h6d3e42a17f0847a3, 64'h9b2661f0ee6d8cc2, 64'h3c4eddc8e4e83e78 },
        '{ 64'hcc0a7b5d777068c7, 64'hcfec11e6276ee125, 64'h7b9edb799a745df1, 64'h5039b2b9f17a91fa, 64'h024a008903e6c9e8 }
    }
};

// As the quirkies!
localparam NUM_BURSTSP = TESTS_EACH_BURST >= 1 ? $size(expected_resultp, 1) / TESTS_EACH_BURST : 0;
localparam VALID_TEST_COUNTP = NUM_BURSTSP * TESTS_EACH_BURST;

if (NUM_BURSTSP < 1) begin
  initial begin
    $display("Not enough proper tests values to make even a single burst!");
    $finish();
  end
end

int resultp_index = 0;
wire[63:0] resultp[5][5] = '{ rowpa, rowpb, rowpc, rowpd, rowpe };

always @(posedge clk) if(samplep) begin
  for (int loop = 0; loop < 5; loop++) begin
      for (int comp = 0; comp < 5; comp++) begin
          if (resultp[loop][comp] != expected_resultp[resultp_index][loop][comp]) begin
            $display("ResultP[%d][%d][%d] !! FAILED !! (expected %h, found %h)",
                     resultp_index, loop, comp, expected_resultp[resultp_index][loop][comp], resultp[loop][comp]);
            $fatal;
            $finish;
          end
      end
  end
  $display("ResultP[%d] %t", resultp_index, $realtime);
  resultp_index++;
  if(resultp_index == VALID_TEST_COUNTP) begin
    $display("%s GOOD (PROPER)", TESTBENCH_NAME);
  end
end

bit tests_done = 1'b0;
always_ff @(posedge clk) begin
    tests_done <= qresult_index == QVALID_TEST_COUNT & resultp_index == VALID_TEST_COUNTP;
end

always @(posedge clk) if(tests_done) begin
    $display("Tests done for %s", TESTBENCH_NAME);
    $finish();
end

endmodule
