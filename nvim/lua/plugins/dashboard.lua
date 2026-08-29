-- Dashboard header: a braille moon showing tonight's real lunar phase.
--
-- ALBEDO below is the near side of the Moon baked to a 128x128 albedo map,
-- 16 levels, one character per cell, space = off the disc. Source is the LRO
-- WAC nearside mosaic (NASA/GSFC/Arizona State University, public domain).
-- Because it is an albedo map rather than a photograph of one phase, the
-- terminator can be applied at runtime for any phase.
--
-- Rendering is 2x4 subpixels per cell, Floyd-Steinberg dithered to 1 bit, then
-- packed into U+2800 braille. Dark maria simply fall to no dots, which on a
-- dark terminal is exactly right.

local uv = vim.uv or vim.loop

local EARTHSHINE = 0.10 -- the unlit limb, lit by light bounced off Earth

-- Cell height : width. This is the one number that has to match your font,
-- and the one thing Neovim cannot ask the terminal for -- get it wrong and
-- the moon comes out egg-shaped. Monaco falling back to BlexMono Nerd Font at
-- 12pt measures ~2.3; the Nerd Font drives a taller cell than Monaco alone.
-- Set `vim.g.moon_aspect` and reopen the dashboard to tune it.
local function aspect() return vim.g.moon_aspect or 2.3 end

local ALBEDO = {
  [=[                                                     1111121367482521111111                                                     ]=],
  [=[                                                11111484588367863a35d841b5411111                                                ]=],
  [=[                                             11135655558471375fb4f88ba8468456b62111                                             ]=],
  [=[                                          1115775942616c42a7baa21fd4baa8888679699a9311                                          ]=],
  [=[                                       11158715ba9986f9637cb998958caca988a8989899a9ada711                                       ]=],
  [=[                                     113468939aab78aac4878766a39ca98a897b87a7e8699abb8abb41                                     ]=],
  [=[                                   1147159b77c499877a2994887388c88957967ca86798989778baddde71                                   ]=],
  [=[                                 1166519ba988738877683846435987676786868a87987aaa5b8cccc9edcb81                                 ]=],
  [=[                               115848b578c756578665455555554755566667576787888898aaaabd9dbbdbbc41                               ]=],
  [=[                              1386a958748a68665765555546545543445556767766778788899789bbdec7cb9d91                              ]=],
  [=[                            11677689976676657676665455454466444665567577566655655667788ccbc8cabbb921                            ]=],
  [=[                           1566788776654444456676566544567687767665556666566546554545687abab8ec8ab961                           ]=],
  [=[                         1174458765455665565695657668885476497898756665565555556555554577989b7d64bca941                         ]=],
  [=[                        136345754544548767667776655679828515873ba667766665456656554555578998aa8b849cb981                        ]=],
  [=[                       15645444223356685878557796574354451175a496a997677655c56765555665779989a98aab9baab1                       ]=],
  [=[                      1644444522234578637764849754321542556966576b899756565d716756649666999899a988989aa9b4                      ]=],
  [=[                    1163444434334557853a786497732444265454245387777a976655467786758776679789999b99778a899a41                    ]=],
  [=[                   1153334444437547556b543331822233223654433455497889766665566797876566897992c96be87788c79b51                   ]=],
  [=[                  1242233344435657428c32332222112232333336434431688998867576a8887a656778877a59a6bb8987788ab961                  ]=],
  [=[                 1332223233222346626d522333221112233333333334442588987877778f19887765788766778889ba877778979971                 ]=],
  [=[                13422232331212435646c322232211111233323334343444189598882a79a4869877565a7677777789998978874aaa71                ]=],
  [=[                16222223222214536556922111111111212333333333345556768789675887879565667987778777888a988a8888bab5                ]=],
  [=[               16421221322212445554655111111211121223332333335365557886377c88887955444876666677798b8a778a9889acb5               ]=],
  [=[              144122213122113545654311111111111211233333223445667656586167e7688877545466676647679999b8798a9989abb2              ]=],
  [=[             15211212331232254355621212211111111111333322344556666656531e6ba9887687544556777444689a8a59999ab699aab2             ]=],
  [=[            142211222211232344435321212111111111211333333334465555456556a8a4434776664466456544467aa7787aa9aa89a98a91            ]=],
  [=[            2321123312222223442541112221111111222222333223344454554555578953222345567653346544458999879a989cb8a889b6            ]=],
  [=[           1611112211122222232331112232222111112222333321225345457545516d9223322245655323365544566988b99887f9a8989ab4           ]=],
  [=[          151132221111122222223211232321112111122222122211253453c185446595234333333334323255554575699c9a6a9b9ba98a89a1          ]=],
  [=[          2113422211122322222131122322111211111122111222112234445464436574222233233234323376755778999a8b78b9acb9888aa7          ]=],
  [=[         1312511122223222222233222232111111111112222232222223345566654385322122222223422238858774b8a9a98b99a8d99879c9c3         ]=],
  [=[        14111111122222233222324222222221111122222222332223254556648654543321132222223322225868788998aacac97a8c99888ab9a1        ]=],
  [=[        1333211111132333322222213332222222231113212332222344436657665543333222222222332311127589b7889bacca7b8cb9a79abbb6        ]=],
  [=[       13444211111221343432221224331222122122213222232223425354567574543233222222222332211112679aa889acbbab99d96aa9a9bcb2       ]=],
  [=[       22533111112213443232322343321122322221113222443234545464445665745223422223223242221113478bb88b8aabaea9b969ba99aac8       ]=],
  [=[      142342121111124653334322333222113223211113228263245456764443236566222222223223232222111149abaca7a99bb999986ba79a9bd3      ]=],
  [=[      323221111111234953354222221122112321113113223443236366765441214556211222222223332222111265bd7da7a89a99999876888899c9      ]=],
  [=[     1525211111121236553344222121122112223223113122222234457665534148676111112222233332223211277b9b7ba8a87887958878787a8cc2     ]=],
  [=[     334612111111133f34444321211211321122322322322232321255656574184a944121111222233221122211166869878aa9688784899558697bb6     ]=],
  [=[    16452122111212588554331111112136321333224333222232112334365833a577521111122112432211122112376887888a66877a38a44347479cb1    ]=],
  [=[    1643132111112343344422222222334543233232423322323211222245716e7656321211112113432111132113258875579885c59966534424468bc4    ]=],
  [=[    643133111111123333333223223233544433215332142333323322122152a9a655311412222223332221222111446775469a87c398845354334589b9    ]=],
  [=[   193211211111112232333422221222444333532224223333322331221167878755532241221112332222132111236555646a8989996844443322377ab2   ]=],
  [=[   582212111111122222223432212222334344343234334334335412221367777663241121451112223212222111334653545668ba9c9a54333221156ba5   ]=],
  [=[   772122111111111111113332321123423355534343344443334324417468775455344222346311222221111111124452342436accbbb73333221138996   ]=],
  [=[  185312111111111111212334321232343346564234434554344433125857965445533411133335321131111122111223343115689dcdd744322212168961  ]=],
  [=[  294211111111111112113345521112444397575465456655543464236836573332322334233244d843312121121111223321147778ceca63222211257982  ]=],
  [=[  68311111111111112112233363222344485628746656565527242331573643232221124874332288543421811111111132111267777fc853222211348873  ]=],
  [=[ 187311111111111111111233462114523666648865676555619143331523343232322223b46112333554111111111111111111167776dc953222211467a641 ]=],
  [=[ 186421111111111112211233434222245677756878877666635544332211134333221111345423445632111111111111111111137677acaa3222211387a761 ]=],
  [=[ 1964221111111111112122333453212366789776788776563665443221111131222211123332235753111111111111111111111146779aa87422221485a961 ]=],
  [=[ 687442111111111111113235555421235679977689b6766556543333221112422111111132123437611111111111111111111111114778a897222224b78892 ]=],
  [=[ 7a65411111111111111122265554212348777787fb49766655654432211112453311111112235476641111111112111111111112111258b9986223578899a5 ]=],
  [=[1999661111111111111112347765523354467689bfd1c765655554312112334655541111113426482532111111111111111111121133557ba978737767879a71]=],
  [=[1aa97521111111111111234667775333444466877f93866655554321232364576555343232347667553111111111111111111111124555689988857878568a81]=],
  [=[4baa8431134121111111224687875432323456665667565433554311122364556766565454346776764111111121111111111111135643357889767758556a92]=],
  [=[3ba9653114211111112234467888542333546776555655434444311111246676967676545565678874421111111111111111111114344444577a7878672469a3]=],
  [=[5ca97831111111111111123567863444666566656645432133333111113467658767777546788878754311221211111111111121122356644679898787245ab5]=],
  [=[6baa87621111111111111334666523344556676654454521122431111233476656579a976a78b7877653122121111111111122212224676432478787874679b6]=],
  [=[789a99621111111121111333356323453345575755454321223421111232556669787978998d58a7666322111111111111113221232365642116688668377995]=],
  [=[7999c7621111111111111144235223543233567187554323434332111212334567778879989db896656532111111111111212221123453422112587678668895]=],
  [=[8a9aa852111111111111113425422343324456438754442132332212232134445568885b8abddb9765a643111122111211221111123653322111153658577686]=],
  [=[9999a841111111111111113243232323444345457668543212332123242243335468888a99e7ec86a66843321122111111466311134432322111111355368586]=],
  [=[a8a8a9311111111111111131122222334443344564586532323221324554522355757899b99dcb98996753312112121112589443234321322221113443468776]=],
  [=[a7aa994211111111111111111112222222525344544565533323334576754332468877a97a9cba89aa7845543221112113da7767646222221221112545456775]=],
  [=[979aa64311111111111111111111221222234343342555534333335666666534667869a8a8a99a9ab88788885633312137996768765222221111112354657775]=],
  [=[985ba853111111111111112111112224233243322334546453454565565688656688879b99a99989a8d1b99a8793322238776849662133231112223346757876]=],
  [=[786b886721111131111111211111222514443322233445644455677768996776768878aaa99998987abab9ea8ac5422157876796654222221222234347867885]=],
  [=[788b56734111122111111111111111231333231235345566445699a968a8588658888a89a88a979699cbcad9ab97433456788776856222222212244446757984]=],
  [=[788c23764211111211111111111122222423222136457556442489aa688679a689898a97998987b889accdea9954334557877676757532322122352347757984]=],
  [=[697c128753111112121111122111321245353222354566552323589878766d496a988a997ba9a7a88a7fbeea8653444567778977653522222122432357668784]=],
  [=[689c11b7631111131111111211112212664432223436655643334776767a6ab7788aaaa69eaaa98a9aaefcdc8754564478779aa7764422222123343776767892]=],
  [=[49ca52a67421111111111111221123237866211224355477531346558677b9856879a78adebba8a8ba7d8ddb7766654577766bb9786343232225457c88877994]=],
  [=[29a8a6c6862111111111111111122333566311222223559632123344778877772988897dcdba89a99a7899fb8866655675a49baaa7434322123446bd78868993]=],
  [=[199a98a787421211113111112111122355622122222246664212223558886776456b849cc8a989a89ab7a9ff9878876676789a7aa8677423233556db79989991]=],
  [=[ 9a9a79966521133121111112111122235621112222234465321223758a7767554bb624c9a999a9bbeb6bcdfa9bc78576566787a5aa75334334566e9998899a ]=],
  [=[ 7a7a9aa9773215412211125211123112331212122222347753323567776877486d7771b989887abcfbc9edabafc8389854455694db45534334456998888a88 ]=],
  [=[ 6798ab6b896226432334226711111113321311122122346852322557767985976c5873c86899888ea6c8dc9cafb76a9886445676aa65454355456787888896 ]=],
  [=[ 47a7ba796d7526442343335732212112332122323223434862123356359881c769b8699877aab95dba99ccbf9dc8c987644454668896586665465778987895 ]=],
  [=[ 18b88986ad8766413444356753111111222254733335623633123433338783968587b88987998a39ba7cbacfc6ed987643355676a7787887844585778779a2 ]=],
  [=[  7a6ba977a8768335546477765442111124456722444334432144746339a74978774979999998a76b99abbcfacfea855444556b6a9a557798445967677889  ]=],
  [=[  598b987678777533545545783263112113558732324332332123445471c58a877888798a9aa89a879a8ccbdaffd9755444565a8898678896456847876997  ]=],
  [=[  288b959699677454455659445141146114647723322333433311134574788a88788b5a9adba9aa378b8aafa8dfd976554444499745886665558545878995  ]=],
  [=[   89b87979967747657754b575146223211676533323433433311136865cb6297cbbb89a6ab89986988caadb6ffe987545433689756966665659637768ac   ]=],
  [=[   69a99a89a8777565984a6675112113555565433233223211332148986e8b1a5bb8c69669989898977cabcc5cdd986644432588758864556768766779a8   ]=],
  [=[   48b8aba7b97968659c7622111111464645643343333222122322587989b6878b977b8697999578894cb8f99cbaca8864343577765874556bb9679879b4   ]=],
  [=[    9a9dac7ca8776666c8521111113483726654b23332221243322488879987887886977889799879989c9bbaba9ccb676475577956576459ca977878b8    ]=],
  [=[    699e7f6cc9688693b75121111122846455547644333211221134688a5b877899499897aa5ab988795c89cadbabc966a79987a76657657aaa868989b6    ]=],
  [=[    39ab9dcceab87696854211111112564353453544323431231246586c1c9a79b57987a979f1bc877b5c85babcd9b9769999679a869a7699bb88888993    ]=],
  [=[     89ab8ffd9cb8777a6421211111135434245453421243212114437739a88b6a98b8694a999beb5476b988ddcd988999a98688988ba88a7c887889a7     ]=],
  [=[     3bb9afbfab8c8847d73232111112234333473433212121121333571e865d99bab9897baba9da66669bbaecca978b89a8699b79cab98a8b898999a4     ]=],
  [=[      8a7aedecaba9a83a75331111112334443355332221122131234675d7959fc67b98b9bdabaa9787b4acfdcca99ab99b778aba6d8e998bc899a898      ]=],
  [=[      5b99adec7a9bba9574442211223334853335343212122121234567e996edb77b6e9cdca99978989998fbbcababa7a88988bc7d9dbabcb99a98b4      ]=],
  [=[       8aba8cd86b8daa8862422221244554634346342222212224456599bda8bf89bcc6e8d6a9789aabaabbaabaab9a96a8967dbbbbdcbddbbaa99a       ]=],
  [=[       6aa988ba6e3fa7b8775412323236556143485542444546466698acecd76fb4baca9aa9b37c898ebca98daac8a997aa589bcbebdccbdb9b79b4       ]=],
  [=[        7aa998a7d75ac9a7c5643444358633435579554635544979bbc9bddb7ecee9ebb9b8785b9bb7abab89bcdc3a979d979c5afedf7ccc8cb698        ]=],
  [=[        499998997c5d79a89746337446872375766ba7966953489acbcdb77aecbff86baa69787a6cc8ba8b8998f94a989cd89bb6ffefacd9dba7b4        ]=],
  [=[         6a97998b69abeca896773736a4633556659e98a888987cfcddced5dd8aff5abd98998a69a8e84fb9789978b6de5d996cbffcffbc9c7a86         ]=],
  [=[          9ba79989889ada987677618a6432544456afaca888aaedcddffeff9c2ebeda9a67e5aca78e8bf5b5a8879a5abbd986cdff8fdbbba9b9          ]=],
  [=[          4a99999875787b78667678498333364474eaf9b94f94eecefffefdbe49ebbb98da82eeb84b9bba95c987a988bbeb79dedefffce99995          ]=],
  [=[           79a87a98a5979667558787787341748688acaeb3ec7cefdeffabfda9f5cab9e8d91bb997ca67a8acb47aa8ba8ac9bbfceef6aa9995           ]=],
  [=[            a88a598c858a89854469776599716aa3c89b7ccba9cddfeff9aeeacd9d7cbb9faa78a66ab6b798c879ca8aa9ababbedce9999aa7            ]=],
  [=[            3a6a868c79698887445a796269c95b86aaaa7eb8eadcdfdfccd8dcbbcf5bcb899a9ac996999396aaaa89a9a89b5addbd96aaa992            ]=],
  [=[             5a8b76b88496657874986a76895bb96b999af7fbcfdc6fefddfbfceb7bbba9899ddd689a99899c899bb789bc8cdcbae8aa9973             ]=],
  [=[              8a9a7899678686995a8875aa8476b789bce3cacefec6efd8afe3fdeabd9a8989d7d98bbad9b9b889e9597e8aeb8b9a999974              ]=],
  [=[               88aa9a99678878a87a698a2b899688aade5cd7dafcecffb7bc8ffeb39ca7b5ccbbaaabab9a9a99be7ec3cabc8898888984               ]=],
  [=[                9aa9a8893687898aa94ac857bb99aa99aadda7defdaffecd2fcfc8b7adfb53ea99ca8a888a998d99ea8cd79987887786                ]=],
  [=[                299a9a9954279776788e764e69898cd93afd7bf1fd8ff6cccf7fe9f55fcb1bc8a9cab7998a8bbbe94cbab68989697772                ]=],
  [=[                 39ba899b5756977698aab698a857edc49de6ef66f7ef6cbd9fbadb99eb66e687ba99988899cb7f89bca88988988653                 ]=],
  [=[                  289a998b78269766b7b967a8886d9b7bbf97dcddbbdefbcbcccab98aa8c6397aaabaac88ad8bd89baa869878a773                  ]=],
  [=[                   38aa888b962976689858c98a7958da99fd7bf5baf7fedfccbf5ba7798b7a9896aabbbbabdcca9ba8a677998663                   ]=],
  [=[                    27ba697bb77766878a88aa88a5aa645cfabebbcdddbffdb9f4999f9197977a9989bb98cfdab8a97879888562                    ]=],
  [=[                      5baa788997557657899a7893f9951abff6fffdc3f9f7bfd3d7cbb99a8c88888abab79babd198b7ab8754                      ]=],
  [=[                       4ab876a7a868493739c7a76efab1c5fd7efdcf68d9f4f3cf4aa9aa77ca98ad1baaaab98d89aaaa7654                       ]=],
  [=[                        39c778c5a865488144a7894ccd6cebcc7dfe86ef5dcdb8daaaa8e9abaa6c99bb9c9a9999a9977763                        ]=],
  [=[                         389989b4c76568c43976b987d48bcdeccbceccfa5bc9dcbaa99b8ca988c93fe3bac78a79768543                         ]=],
  [=[                           5a89899a76666b66799a89c599bc989ebed3f685f19bbaa9b9d8c6aaa91cb968bb58898854                           ]=],
  [=[                            399989bb88875b536b98e59afecd511efa9f95c9cae1c9c7a9a978ca8b9ca6ba89999973                            ]=],
  [=[                              7898a9dab6b8b526999b7dfaabbb15ffafa28b9bd98b8ca998a9aad48ba8baa9a895                              ]=],
  [=[                               47aaaacdbbca96a1f913bffce9d11ffab77969f699eab8bb99a9ab8c94baa9d993                               ]=],
  [=[                                 3aba8ba5bc99ac9ac1e75ff99a1fed96ae1aaaa9d889c7abb8aa8caaba7b95                                 ]=],
  [=[                                   6ba77a7b94ea99959f11bfacbfeab5a5ba6d4db676f46dcb6beab9bba4                                   ]=],
  [=[                                     79a658a9cc99a966d7ef9d9c461fe4ba4ddc9865e8bfac4eacdb95                                     ]=],
  [=[                                       578527d3b9c469979eaf91994ff34aa9dafc19cbbf979fc584                                       ]=],
  [=[                                          585bda8693fc71c975f711f1782d8f76eabbacfa3c64                                          ]=],
  [=[                                             249d277af11fc146b3c144643de396ff87ba57                                             ]=],
  [=[                                                31231262a16115f144b53f4c7c9c1851                                                ]=],
  [=[                                                     22276382181147eac81584                                                     ]=],
}

local N = #ALBEDO
local LEVEL = {}
for i = 0, 15 do
  LEVEL[("0123456789abcdef"):sub(i + 1, i + 1)] = i / 15
end

-- U+2800 + mask, encoded directly rather than via nr2char.
local BRAILLE = {}
for m = 0, 255 do
  BRAILLE[m] = string.char(0xE2, 0xA0 + math.floor(m / 64), 0x80 + m % 64)
end

local buf, buf_n = {}, 0

--- @param cols number width in cells
--- @param phase number degrees; 0 = full, 90 = first quarter, 180 = new
--- @return string[] lines, each exactly `cols` cells wide
local function draw(cols, phase)
  local rows = math.floor(cols / aspect() + 0.5)
  if rows % 2 == 0 then rows = rows + 1 end
  local W, H = cols * 2, rows * 4
  local lx, lz = math.sin(math.rad(phase)), math.cos(math.rad(phase))

  if buf_n < W * H then
    buf, buf_n = {}, W * H
  end

  for y = 0, H - 1 do
    local v = ((y + 0.5) / H) * 2 - 1
    local base = y * W
    for x = 0, W - 1 do
      local u = ((x + 0.5) / W) * 2 - 1
      local d2 = u * u + v * v
      local val = 0
      if d2 <= 1 then
        local gx = math.floor((u + 1) * 0.5 * N)
        local gy = math.floor((v + 1) * 0.5 * N)
        local row = ALBEDO[gy + 1]
        local t = row and LEVEL[row:sub(gx + 1, gx + 1)]
        if t then
          -- ^0.30 rather than Lambert: regolith scatters almost flat, which is
          -- why the real moon reads as a disc and not a shaded ball.
          local dot = u * lx + math.sqrt(1 - d2) * lz
          val = dot > 0 and t * dot ^ 0.30 or t * EARTHSHINE
        end
      end
      buf[base + x + 1] = val
    end
  end

  -- Floyd-Steinberg: diffuse the quantisation error forward, which is what
  -- turns a 1-bit dot grid back into apparent shades of gray.
  for y = 0, H - 1 do
    local base = y * W
    for x = 0, W - 1 do
      local i = base + x + 1
      local old = buf[i]
      local new = old >= 0.5 and 1 or 0
      buf[i] = new
      local e = old - new
      if e ~= 0 then
        if x + 1 < W then buf[i + 1] = buf[i + 1] + e * 0.4375 end
        if y + 1 < H then
          if x > 0 then buf[i + W - 1] = buf[i + W - 1] + e * 0.1875 end
          buf[i + W] = buf[i + W] + e * 0.3125
          if x + 1 < W then buf[i + W + 1] = buf[i + W + 1] + e * 0.0625 end
        end
      end
    end
  end

  local lines = {}
  for r = 0, rows - 1 do
    local cells, y0 = {}, r * 4
    local r0, r1, r2, r3 = y0 * W, (y0 + 1) * W, (y0 + 2) * W, (y0 + 3) * W
    for c = 0, cols - 1 do
      local a, b = c * 2 + 1, c * 2 + 2
      local m = 0
      if buf[r0 + a] == 1 then m = m + 1 end
      if buf[r1 + a] == 1 then m = m + 2 end
      if buf[r2 + a] == 1 then m = m + 4 end
      if buf[r0 + b] == 1 then m = m + 8 end
      if buf[r1 + b] == 1 then m = m + 16 end
      if buf[r2 + b] == 1 then m = m + 32 end
      if buf[r3 + a] == 1 then m = m + 64 end
      if buf[r3 + b] == 1 then m = m + 128 end
      cells[c + 1] = m == 0 and " " or BRAILLE[m]
    end
    lines[r + 1] = table.concat(cells)
  end
  return lines
end

-- Phase ---------------------------------------------------------------------

local SYNODIC = 29.530588853
local NEW_MOON_JD = 2451550.1 -- 2000-01-06 18:14 UTC

local function moon_age()
  local jd = os.time() / 86400.0 + 2440587.5
  return (jd - NEW_MOON_JD) % SYNODIC
end

--- Age -> the angle `draw` wants. 0 days (new) = 180, half a cycle = 0 (full).
local function age_to_phase(age) return (180 - 360 * age / SYNODIC) % 360 end

local NAMES = {
  "New Moon", "Waxing Crescent", "First Quarter", "Waxing Gibbous",
  "Full Moon", "Waning Gibbous", "Last Quarter", "Waning Crescent",
}

local function caption(age)
  local f = age / SYNODIC
  local lit = (1 - math.cos(2 * math.pi * f)) / 2
  return ("%s  ·  %.1f days  ·  %d%% lit")
    :format(NAMES[math.floor(f * 8 + 0.5) % 8 + 1], age, math.floor(lit * 100 + 0.5))
end

-- Sizing --------------------------------------------------------------------

-- Rows the rest of the dashboard needs: header padding, six keys with gaps,
-- the caption and the startup line.
local CHROME = 22

-- Shrink relative to the space available, so the moon has some air around it
-- rather than filling every row the chrome leaves free.
local SCALE = 0.90

local function moon_cols()
  return math.max(20, math.floor(SCALE * math.min(
    N, vim.o.columns - 6, (vim.o.lines - CHROME) * aspect())))
end

-- Color ---------------------------------------------------------------------

local PERIOD = 30000 -- one trip through every accent in the theme
local FRAME = 50

local function to_hsl(hex)
  local r = tonumber(hex:sub(2, 3), 16) / 255
  local g = tonumber(hex:sub(4, 5), 16) / 255
  local b = tonumber(hex:sub(6, 7), 16) / 255
  local mx, mn = math.max(r, g, b), math.min(r, g, b)
  local l = (mx + mn) / 2
  if mx == mn then return 0, 0, l end
  local d = mx - mn
  local s = l > 0.5 and d / (2 - mx - mn) or d / (mx + mn)
  local h
  if mx == r then
    h = (g - b) / d + (g < b and 6 or 0)
  elseif mx == g then
    h = (b - r) / d + 2
  else
    h = (r - g) / d + 4
  end
  return h * 60, s, l
end

local function from_hsl(h, s, l)
  local function chan(p, q, t)
    t = t % 1
    if t < 1 / 6 then return p + (q - p) * 6 * t end
    if t < 1 / 2 then return q end
    if t < 2 / 3 then return p + (q - p) * (2 / 3 - t) * 6 end
    return p
  end
  local r, g, b = l, l, l
  if s > 0 then
    local q = l < 0.5 and l * (1 + s) or l + s - l * s
    local p = 2 * l - q
    h = (h % 360) / 360
    r, g, b = chan(p, q, h + 1 / 3), chan(p, q, h), chan(p, q, h - 1 / 3)
  end
  return ("#%02x%02x%02x"):format(
    math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5))
end

--- Every accent in the palette, in hue order so the sweep closes the circle.
local function palette()
  local ok, base16 = pcall(require, "base16-colorscheme")
  if ok and base16.colors then
    local c = base16.colors
    return { c.base08, c.base09, c.base0A, c.base0B, c.base0C, c.base0D, c.base0E }
  end
  return { "#d54e53", "#e78c45", "#e7c547", "#b9ca4a", "#70c0b1", "#7aa6da", "#c397d8" }
end

local function lerp_hue(a, b, t) return a + ((b - a + 540) % 360 - 180) * t end

local function color_at(pos, hsl)
  local x = pos * #hsl
  local i = math.floor(x)
  local a, b = hsl[i % #hsl + 1], hsl[(i + 1) % #hsl + 1]
  local t = x - i
  t = t * t * (3 - 2 * t)
  return from_hsl(lerp_hue(a[1], b[1], t), a[2] + (b[2] - a[2]) * t, a[3] + (b[3] - a[3]) * t)
end

-- Animation -----------------------------------------------------------------

-- The intro runs the moon through two full lunations in the first ~2s, then
-- eases to a stop on tonight's real phase.
local SPIN_CYCLES = 2
local SPIN_AT = 2.0
local SPIN_COLOR_LOOPS = 1 -- trips through the palette while it spins

local M = { timer = nil, phase = nil, elapsed = 0, spinning = true }

local function stop()
  if M.timer then
    M.timer:stop()
    M.timer:close()
    M.timer = nil
  end
end

local function start()
  stop()
  local hsl = {}
  for _, hex in ipairs(palette()) do
    hsl[#hsl + 1] = { to_hsl(hex) }
  end

  local target = age_to_phase(moon_age())
  local total = SPIN_CYCLES * 360 + target
  -- ease-out cubic, solved so the spin's last full cycle lands at SPIN_AT and
  -- the remainder coasts to a stop.
  local dur = math.min(5.5, math.max(2.5,
    SPIN_AT / (1 - (1 - SPIN_CYCLES * 360 / total) ^ (1 / 3))))

  M.elapsed, M.spinning, M.phase = 0, true, 0
  M.timer = uv.new_timer()
  M.timer:start(0, FRAME, vim.schedule_wrap(function()
    if not M.timer then return end
    M.elapsed = M.elapsed + FRAME / 1000

    -- Color rides the same easing curve as the spin: a full trip through the
    -- palette while the moon is turning, decelerating in step with it, then
    -- handing off to the slow ambient drift once it settles.
    local u = math.min(1, M.elapsed / dur)
    local eased = 1 - (1 - u) ^ 3
    local coast = math.max(0, M.elapsed - dur) * 1000 / PERIOD
    vim.api.nvim_set_hl(0, "SnacksDashboardHeader",
      { fg = color_at((eased * SPIN_COLOR_LOOPS + coast) % 1, hsl) })

    if M.spinning then
      M.phase = total * eased
      if u >= 1 then M.phase, M.spinning = target, false end
      if not pcall(function() require("snacks").dashboard.update() end) then stop() end
    end
  end))
end

-- Spec ----------------------------------------------------------------------

---@type LazySpec
return {
  "folke/snacks.nvim",
  init = function()
    local group = vim.api.nvim_create_augroup("dashboard_moon", { clear = true })
    vim.api.nvim_create_autocmd("User", { group = group, pattern = "SnacksDashboardOpened", callback = start })
    vim.api.nvim_create_autocmd("User", { group = group, pattern = "SnacksDashboardClosed", callback = stop })
    vim.api.nvim_create_autocmd("VimLeavePre", { group = group, callback = stop })
  end,
  opts = function(_, opts)
    local age = moon_age()
    opts.dashboard.sections = {
      -- A function section is re-resolved on every update, which is what lets
      -- the intro animate.
      function()
        return {
          header = table.concat(draw(moon_cols(), M.phase or age_to_phase(age)), "\n"),
          padding = 2,
        }
      end,
      { text = { { caption(age), hl = "SnacksDashboardDesc" } }, align = "center", padding = 2 },
      { section = "keys", gap = 1, padding = 3 },
      { section = "startup" },
    }
    return opts
  end,
}
