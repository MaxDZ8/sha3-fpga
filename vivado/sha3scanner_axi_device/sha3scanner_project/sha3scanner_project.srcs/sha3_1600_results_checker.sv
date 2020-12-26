`timescale 1ns / 1ps

// Spiritual companion of sha3_round_dispatch_logic, check the corresponding results.
module sha3_1600_results_checker #(
    TESTBENCH_NAME = "<FORGOT TO SET ME>"
) (
    input clk,
    input sample,
    input[63:0] rowa[5], rowb[5], rowc[5], rowd[5], rowe[5]
);


localparam longint unsigned expected_result[24][5][5] = '{
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
    }
};

int result_index = 0;
wire[63:0] result[5][5] = '{ rowa, rowb, rowc, rowd, rowe };

always @(posedge clk) if(sample) begin
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
    $display("%s GOOD", TESTBENCH_NAME);
    $finish;
  end
end

endmodule
