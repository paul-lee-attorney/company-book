const LibArrayUtils = artifacts.require("ArrayUtils");
const LibArrowChain = artifacts.require("ArrowChain");
const LibBallotsBox = artifacts.require("BallotsBox");
const LibCheckpoints = artifacts.require("Checkpoints");
const LibDelegateMap = artifacts.require("DelegateMap");
const LibEnumerableSet = artifacts.require("EnumerableSet");
const LibMembersRepo = artifacts.require("MembersRepo");
const LibMotionsRepo = artifacts.require("MotionsRepo");
const LibOptionsRepo = artifacts.require("OptionsRepo");
const LibRolesRepo = artifacts.require("RolesRepo");
const LibSigsRepo = artifacts.require("SigsRepo");
const LibSNFactory = artifacts.require("SNFactory");
const LibSNParser = artifacts.require("SNParser");
const LibTopChain = artifacts.require("TopChain");

const RC = artifacts.require("RegCenter");

const IA = artifacts.require("InvestmentAgreement");
const FRD = artifacts.require("FirstRefusalDeals");
const MR = artifacts.require("MockResults");
const BOA = artifacts.require("BookOfIA");
const BOD = artifacts.require("BookOfDirectors");
const SHA = artifacts.require("ShareholdersAgreement");
const BOH = artifacts.require("BookOfSHA");
const BOM = artifacts.require("BookOfMotions");
const BOO = artifacts.require("BookOfOptions");
const BOP = artifacts.require("BookOfPledges");
const BOS = artifacts.require("BookOfShares");
const ROM = artifacts.require("RegisterOfMembers");

const BOAKeeper = artifacts.require("BOAKeeper");
const BODKeeper = artifacts.require("BODKeeper");
const BOHKeeper = artifacts.require("BOHKeeper");
const BOMKeeper = artifacts.require("BOMKeeper");
const BOOKeeper = artifacts.require("BOOKeeper");
const BOPKeeper = artifacts.require("BOPKeeper");
const BOSKeeper = artifacts.require("BOSKeeper");
const ROMKeeper = artifacts.require("ROMKeeper");
const SHAKeeper = artifacts.require("SHAKeeper");

const GK = artifacts.require("GeneralKeeper");

const AD = artifacts.require("AntiDilution");
const DA = artifacts.require("DragAlong");
const FR = artifacts.require("FirstRefusal");
const GU = artifacts.require("GroupsUpdate");
const LU = artifacts.require("LockUp");
const OP = artifacts.require("Options");
const TA = artifacts.require("TagAlong");

module.exports = async function (deployer, network, accounts) {

    // ==== Libraries ====

    await deployer.deploy(LibEnumerableSet);
    await deployer.link(LibEnumerableSet, [IA, BOD, AD, DA, FR, GU, LU, TA, BOA, BOH, LibBallotsBox, LibCheckpoints, LibMembersRepo, LibMotionsRepo, LibOptionsRepo, LibSigsRepo]);

    await deployer.deploy(LibBallotsBox);
    await deployer.link(LibBallotsBox, [BOD, BOM, LibMotionsRepo]);

    await deployer.deploy(LibCheckpoints);
    await deployer.link(LibCheckpoints, [LibMembersRepo, LibOptionsRepo]);

    await deployer.deploy(LibDelegateMap);
    await deployer.link(LibDelegateMap, [BOD, BOM, LibMotionsRepo]);

    await deployer.deploy(LibSNParser);
    await deployer.link(LibSNParser, [BOA, IA, MR, SHA, AD, DA, FR, GU, LU, TA, BOM, BOO, BOP, BOS, BOH, LibMotionsRepo, LibOptionsRepo, BOAKeeper, BOHKeeper, BOMKeeper, BOOKeeper, BOPKeeper, BOSKeeper, SHAKeeper]);

    await deployer.deploy(LibSNFactory);
    await deployer.link(LibSNFactory, [BOP, BOS, LibOptionsRepo, BOMKeeper, SHAKeeper]);

    await deployer.deploy(LibTopChain);
    await deployer.link(LibTopChain, [MR, ROM, LibMembersRepo]);

    await deployer.deploy(LibArrayUtils);
    await deployer.link(LibArrayUtils, [AD, FR, LU]);

    await deployer.deploy(LibArrowChain);
    await deployer.link(LibArrowChain, AD);

    await deployer.deploy(LibMembersRepo);
    await deployer.link(LibMembersRepo, [MR, ROM]);

    await deployer.deploy(LibMotionsRepo);
    await deployer.link(LibMotionsRepo, [BOM, BOD, BODKeeper, BOMKeeper]);

    await deployer.deploy(LibOptionsRepo);
    await deployer.link(LibOptionsRepo, [OP, BOO]);

    await deployer.deploy(LibRolesRepo);
    await deployer.link(LibRolesRepo, [IA, FRD, MR, BOA, BOD, SHA, BOH, BOM, BOO, BOP, BOS, ROM, BOAKeeper, BODKeeper, BOHKeeper, BOMKeeper, BOOKeeper, BOPKeeper, BOSKeeper, ROMKeeper, SHAKeeper, GK, AD, DA, FR, GU, LU, OP, TA]);

    await deployer.deploy(LibSigsRepo);
    await deployer.link(LibSigsRepo, [IA, SHA]);

    // ==== RegCenter ====

    await deployer.deploy(RC, accounts[0]);
    let rc = await RC.deployed();

    await rc.setBlockSpeed(10); // 10 blocks/hr only for test purpose;
    await rc.setRewards(168000000, 42000000, 1000, 100000);

    await rc.regUser({
        from: accounts[0]
    });

    let acct0 = await rc.userNo.call(accounts[0]);
    acct0 = acct0.toNumber();
    console.log("acct0: ", acct0);

    // ==== General Keeper ====

    await deployer.deploy(GK);
    let gk = await GK.deployed();
    await gk.init(acct0, accounts[0], rc.address, gk.address);

    // ==== Keepers ====

    await deployer.deploy(BOAKeeper);
    let boaKeeper = await BOAKeeper.deployed();
    await boaKeeper.init(acct0, accounts[0], rc.address, gk.address);

    await deployer.deploy(BODKeeper);
    let bodKeeper = await BODKeeper.deployed();
    await bodKeeper.init(acct0, accounts[0], rc.address, gk.address);

    await deployer.deploy(BOHKeeper);
    let bohKeeper = await BOHKeeper.deployed();
    await bohKeeper.init(acct0, accounts[0], rc.address, gk.address);

    await deployer.deploy(BOMKeeper);
    let bomKeeper = await BOMKeeper.deployed();
    await bomKeeper.init(acct0, accounts[0], rc.address, gk.address);

    await deployer.deploy(BOOKeeper);
    let booKeeper = await BOOKeeper.deployed();
    await booKeeper.init(acct0, accounts[0], rc.address, gk.address);

    await deployer.deploy(BOPKeeper);
    let bopKeeper = await BOPKeeper.deployed();
    await bopKeeper.init(acct0, accounts[0], rc.address, gk.address);

    await deployer.deploy(BOSKeeper);
    let bosKeeper = await BOSKeeper.deployed();
    await bosKeeper.init(acct0, accounts[0], rc.address, gk.address);

    await deployer.deploy(ROMKeeper);
    let romKeeper = await ROMKeeper.deployed();
    await romKeeper.init(acct0, accounts[0], rc.address, gk.address);

    await deployer.deploy(SHAKeeper);
    let shaKeeper = await SHAKeeper.deployed();
    await shaKeeper.init(acct0, accounts[0], rc.address, gk.address);

    // ==== Books ====

    await deployer.deploy(BOA);
    let boa = await BOA.deployed();
    await boa.init(acct0, accounts[0], rc.address, gk.address);

    await deployer.deploy(IA);
    let ia = await IA.deployed();
    await boa.setTemplate(ia.address, 0);

    await deployer.deploy(FRD);
    let frd = await FRD.deployed();
    await boa.setTemplate(frd.address, 1);

    await deployer.deploy(MR);
    let mr = await MR.deployed();
    await boa.setTemplate(mr.address, 2);

    await deployer.deploy(BOH);
    let boh = await BOH.deployed();
    await boh.init(acct0, accounts[0], rc.address, gk.address);

    await deployer.deploy(SHA);
    let sha = await SHA.deployed();
    await boh.setTemplate(sha.address, 0);

    await deployer.deploy(BOD);
    let bod = await BOD.deployed();
    await bod.init(acct0, accounts[0], rc.address, gk.address);

    await deployer.deploy(BOM);
    let bom = await BOM.deployed();
    await bom.init(acct0, accounts[0], rc.address, gk.address);

    await deployer.deploy(BOO);
    let boo = await BOO.deployed();
    await boo.init(acct0, accounts[0], rc.address, gk.address);

    await deployer.deploy(BOP);
    let bop = await BOP.deployed();
    await bop.init(acct0, accounts[0], rc.address, gk.address);

    await deployer.deploy(BOS);
    let bos = await BOS.deployed();
    await bos.init(acct0, accounts[0], rc.address, gk.address);

    await deployer.deploy(ROM);
    let rom = await ROM.deployed();
    await rom.init(acct0, accounts[0], rc.address, gk.address);

    // ==== TermsOfSHA ====
    await deployer.deploy(LU);
    let lu = await LU.deployed();
    await boh.setTermTemplate(1, lu.address);

    await deployer.deploy(AD);
    let ad = await AD.deployed();
    await boh.setTermTemplate(2, ad.address);

    await deployer.deploy(FR);
    let fr = await FR.deployed();
    await boh.setTermTemplate(3, fr.address);

    await deployer.deploy(GU);
    let gu = await GU.deployed();
    await boh.setTermTemplate(4, gu.address);

    await deployer.deploy(DA);
    let da = await DA.deployed();
    await boh.setTermTemplate(5, da.address);

    await deployer.deploy(TA);
    let ta = await TA.deployed();
    await boh.setTermTemplate(6, ta.address);

    await deployer.deploy(OP);
    let op = await OP.deployed();
    await boh.setTermTemplate(7, op.address);

    // ==== BOASetting ====
    await bom.setBOA(boa.address);

    await boaKeeper.setBOA(boa.address);
    await bohKeeper.setBOA(boa.address);
    await bomKeeper.setBOA(boa.address);
    await shaKeeper.setBOA(boa.address);

    // ==== BODSetting ==== 
    await bodKeeper.setBOD(bod.address);
    await bohKeeper.setBOD(bod.address);
    await bomKeeper.setBOD(bod.address);

    // ==== BOHSetting ==== 
    await boa.setBOH(boh.address);
    await bod.setBOH(boh.address);
    await bom.setBOH(boh.address);

    await boaKeeper.setBOH(boh.address);
    await bodKeeper.setBOH(boh.address);
    await bohKeeper.setBOH(boh.address);
    await bomKeeper.setBOH(boh.address);
    await shaKeeper.setBOH(boh.address);

    // ==== BOMSetting ==== 
    await boaKeeper.setBOM(bom.address);
    await bodKeeper.setBOM(bom.address);
    await bomKeeper.setBOM(bom.address);

    // ==== BOOSetting ==== 
    await bohKeeper.setBOO(boo.address);
    await bomKeeper.setBOO(boo.address);
    await booKeeper.setBOO(boo.address);

    // ==== BOPSetting ==== 
    await bopKeeper.setBOP(bop.address);

    // ==== BOSSetting ====
    await boo.setBOS(bos.address);
    await rom.setBOS(bos.address);

    await boaKeeper.setBOS(bos.address);
    await bodKeeper.setBOS(bos.address);
    await bohKeeper.setBOS(bos.address);
    await bomKeeper.setBOS(bos.address);
    await booKeeper.setBOS(bos.address);
    await bopKeeper.setBOS(bos.address);
    await bosKeeper.setBOS(bos.address);
    await shaKeeper.setBOS(bos.address);

    // ==== ROMSetting ==== 

    await bos.setROM(rom.address);
    await bod.setROM(rom.address);
    await bom.setROM(rom.address);

    await boaKeeper.setROM(rom.address);
    await bohKeeper.setROM(rom.address);
    await bomKeeper.setROM(rom.address);
    await romKeeper.setROM(rom.address);
    await shaKeeper.setROM(rom.address);

    // ==== Keepers Setting ====

    await gk.setBookeeper(0, boaKeeper.address);
    await gk.setBookeeper(1, bodKeeper.address);
    await gk.setBookeeper(2, bohKeeper.address);
    await gk.setBookeeper(3, bomKeeper.address);
    await gk.setBookeeper(4, booKeeper.address);
    await gk.setBookeeper(5, bopKeeper.address);
    await gk.setBookeeper(6, bosKeeper.address);
    await gk.setBookeeper(7, romKeeper.address);
    await gk.setBookeeper(8, shaKeeper.address);

    // ==== RegDocs ====

    await bom.createCorpSeal();
    await bom.createBoardSeal(bod.address);

    // ==== DirectKeeper ====
    await boa.setBookeeper(boaKeeper.address);
    await bod.setBookeeper(bodKeeper.address);
    await boh.setBookeeper(bohKeeper.address);
    await bom.setBookeeper(bomKeeper.address);
    await boo.setBookeeper(booKeeper.address);
    await bop.setBookeeper(bopKeeper.address);
    // await bos.setBookeeper(bosKeeper.address);
    // await rom.setBookeeper(romKeeper.address);

    await boaKeeper.setBookeeper(gk.address);
    await bodKeeper.setBookeeper(gk.address);
    await bohKeeper.setBookeeper(gk.address);
    await bomKeeper.setBookeeper(gk.address);
    await booKeeper.setBookeeper(gk.address);
    await bopKeeper.setBookeeper(gk.address);
    await bosKeeper.setBookeeper(gk.address);
    await romKeeper.setBookeeper(gk.address);

    gk.setBookeeper(accounts[1]);
};