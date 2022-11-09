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
const BOSCal = artifacts.require("BOSCalculator");
const ROM = artifacts.require("RegisterOfMembers");

const BOAKeeper = artifacts.require("BOAKeeper");
const BODKeeper = artifacts.require("BODKeeper");
const BOHKeeper = artifacts.require("BOHKeeper");
const BOMKeeper = artifacts.require("BOMKeeper");
const BOOKeeper = artifacts.require("BOOKeeper");
const BOPKeeper = artifacts.require("BOPKeeper");
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
    await deployer.link(LibEnumerableSet, [BOA, IA, BOD, AD, DA, FR, GU, LU, OP, TA, BOH, LibBallotsBox, LibCheckpoints, LibEnumerableSet, LibMembersRepo, LibMotionsRepo, LibOptionsRepo, LibSigsRepo]);

    await deployer.deploy(LibBallotsBox);
    await deployer.link(LibBallotsBox, [BOD, BOM, LibMotionsRepo]);

    await deployer.deploy(LibCheckpoints);
    await deployer.link(LibCheckpoints, [LibMembersRepo, LibOptionsRepo]);

    await deployer.deploy(LibDelegateMap);
    await deployer.link(LibDelegateMap, [BOD, BOM, LibMotionsRepo]);

    await deployer.deploy(LibSNParser);
    await deployer.link(LibSNParser, [IA, MR, SHA, AD, DA, FR, GU, LU, OP, TA, BOA, BOD, BOH, BOM, BOO, BOP, BOS, BOSCal, BOAKeeper, BOHKeeper, BOMKeeper, BOOKeeper, BOPKeeper, SHAKeeper, LibMotionsRepo, LibOptionsRepo]);

    await deployer.deploy(LibSNFactory);
    await deployer.link(LibSNFactory, [DA, FR, GU, OP, BOP, BOS, BOA, BOH, BOMKeeper, SHAKeeper, LibOptionsRepo]);

    await deployer.deploy(LibTopChain);
    await deployer.link(LibTopChain, [MR, BOS, LibMembersRepo]);

    await deployer.deploy(LibArrayUtils);
    await deployer.link(LibArrayUtils, [AD, FR, LU, TA]);

    await deployer.deploy(LibArrowChain);
    await deployer.link(LibArrowChain, AD);

    await deployer.deploy(LibMembersRepo);
    await deployer.link(LibMembersRepo, [MR, BOS]);

    await deployer.deploy(LibMotionsRepo);
    await deployer.link(LibMotionsRepo, [BOD, BOM, BODKeeper, BOMKeeper]);

    await deployer.deploy(LibOptionsRepo);
    await deployer.link(LibOptionsRepo, [OP, BOO]);

    await deployer.deploy(LibRolesRepo);
    await deployer.link(LibRolesRepo, RC);

    await deployer.deploy(LibSigsRepo);
    await deployer.link(LibSigsRepo, [IA, SHA]);

    // ==== RegCenter & GeneralKeeper====

    await deployer.deploy(RC, 10); // testing purpose set 10 block per hr
    let rc = await RC.deployed();

    await rc.regUser({
        from: accounts[0]
    });

    await rc.regUser({
        from: accounts[1]
    });

    await deployer.deploy(GK);
    let gk = await GK.deployed();

    await gk.init(accounts[0], accounts[0], rc.address, gk.address);

    // ==== BOS ====

    await deployer.deploy(BOS, "0x38301fb0b5fcf3aaa4b97c4771bb6c75546e313b4ce7057c51a8cc6a3ace9d7e");
    let bos = await BOS.deployed();
    await bos.init(accounts[0], accounts[0], rc.address, gk.address);

    await deployer.deploy(BOSCal);
    let bosCal = await BOSCal.deployed();
    await bosCal.init(accounts[0], accounts[0], rc.address, gk.address);

    // ==== Keepers ====

    await deployer.deploy(BOAKeeper);
    let boaKeeper = await BOAKeeper.deployed();
    await boaKeeper.init(accounts[0], accounts[0], rc.address, gk.address);

    await deployer.deploy(BODKeeper);
    let bodKeeper = await BODKeeper.deployed();
    await bodKeeper.init(accounts[0], accounts[0], rc.address, gk.address);

    await deployer.deploy(BOHKeeper);
    let bohKeeper = await BOHKeeper.deployed();
    await bohKeeper.init(accounts[0], accounts[0], rc.address, gk.address);

    await deployer.deploy(BOMKeeper);
    let bomKeeper = await BOMKeeper.deployed();
    await bomKeeper.init(accounts[0], accounts[0], rc.address, gk.address);

    await deployer.deploy(BOOKeeper);
    let booKeeper = await BOOKeeper.deployed();
    await booKeeper.init(accounts[0], accounts[0], rc.address, gk.address);

    await deployer.deploy(BOPKeeper);
    let bopKeeper = await BOPKeeper.deployed();
    await bopKeeper.init(accounts[0], accounts[0], rc.address, gk.address);

    await deployer.deploy(SHAKeeper);
    let shaKeeper = await SHAKeeper.deployed();
    await shaKeeper.init(accounts[0], accounts[0], rc.address, gk.address);

    // ==== Books ====
    await deployer.deploy(BOA);
    let boa = await BOA.deployed();
    await boa.init(accounts[0], accounts[0], rc.address, gk.address);

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
    await boh.init(accounts[0], accounts[0], rc.address, gk.address);

    await deployer.deploy(SHA);
    let sha = await SHA.deployed();
    await boh.setTemplate(sha.address, 0);

    await deployer.deploy(BOD);
    let bod = await BOD.deployed();
    await bod.init(accounts[0], accounts[0], rc.address, gk.address);

    await deployer.deploy(BOM);
    let bom = await BOM.deployed();
    await bom.init(accounts[0], accounts[0], rc.address, gk.address);

    await deployer.deploy(BOO);
    let boo = await BOO.deployed();
    await boo.init(accounts[0], accounts[0], rc.address, gk.address);

    await deployer.deploy(BOP);
    let bop = await BOP.deployed();
    await bop.init(accounts[0], accounts[0], rc.address, gk.address);

    await deployer.deploy(ROM);
    let rom = await ROM.deployed();
    await rom.init(accounts[0], accounts[0], rc.address, gk.address);

    // ==== BOSSetting ====
    await boaKeeper.setBOS(bos.address);
    await boaKeeper.setBOSCal(bosCal.address);
    await bodKeeper.setBOS(bos.address);
    await bodKeeper.setBOSCal(bosCal.address);
    await bohKeeper.setBOS(bos.address);
    await bohKeeper.setBOSCal(bosCal.address);
    await bomKeeper.setBOS(bos.address);
    await bomKeeper.setBOSCal(bosCal.address);
    await booKeeper.setBOS(bos.address);
    await booKeeper.setBOSCal(bosCal.address);
    await bopKeeper.setBOS(bos.address);
    await bopKeeper.setBOSCal(bosCal.address);

    await boa.setBOS(bos.address);
    await boa.setBOSCal(bosCal.address);
    await boh.setBOS(bos.address);
    await boh.setBOSCal(bosCal.address);
    await boo.setBOS(bos.address);
    await boo.setBOSCal(bosCal.address);
    await bop.setBOS(bos.address);
    await bop.setBOSCal(bosCal.address);
    await rom.setBOS(bos.address);
    await rom.setBOSCal(bosCal.address);

    // ==== BOASetting ====
    await boaKeeper.setBOA(boa.address);
    await bohKeeper.setBOA(boa.address);
    await bomKeeper.setBOA(boa.address);
    await shaKeeper.setBOA(boa.address);
    await bom.setBOA(boa.address);

    // ==== BODSetting ==== 
    await bodKeeper.setBOD(bod.address);
    await bohKeeper.setBOD(bod.address);
    await bomKeeper.setBOD(bod.address);

    // ==== BOHSetting ==== 
    await boaKeeper.setBOH(boh.address);
    await bodKeeper.setBOH(boh.address);
    await bohKeeper.setBOH(boh.address);
    await bomKeeper.setBOH(boh.address);
    await shaKeeper.setBOH(boh.address);

    await boa.setBOH(boh.address);
    await boh.setBOH(boh.address);
    await bod.setBOH(boh.address);
    await bom.setBOH(boh.address);
    await rom.setBOH(boh.address);

    // ==== BODSetting ==== 
    await bodKeeper.setBOD(bod.address);
    await bohKeeper.setBOD(bod.address);
    await bomKeeper.setBOD(bod.address);

    // ==== BOMSetting ==== 
    await boaKeeper.setBOM(bom.address);
    await bodKeeper.setBOM(bom.address);
    await bohKeeper.setBOM(bom.address);
    await bomKeeper.setBOM(bom.address);

    // ==== BOOSetting ==== 
    await bohKeeper.setBOO(boo.address);
    await bomKeeper.setBOO(boo.address);
    await booKeeper.setBOO(boo.address);

    // ==== BOPSetting ==== 
    await bopKeeper.setBOP(bop.address);

    // ==== ROMSetting ==== 
    await bod.setROM(rom.address);
    await bom.setROM(rom.address);
    await bos.setROM(rom.address);
    await boaKeeper.setROM(rom.address);
    await bohKeeper.setROM(rom.address);
    await bomKeeper.setROM(rom.address);

    // ==== DirectKeeper ====
    await boa.setManager(1, accounts[0], boaKeeper.address);
    await bod.setManager(1, accounts[0], bodKeeper.address);
    await boh.setManager(1, accounts[0], bohKeeper.address);
    await bom.setManager(1, accounts[0], bomKeeper.address);
    await boo.setManager(1, accounts[0], booKeeper.address);
    await bop.setManager(1, accounts[0], bopKeeper.address);
    await bosCal.setManager(1, accounts[0], boaKeeper.address);

    // ==== Keepers Setting ====
    await gk.setBOAKeeper(boaKeeper.address);
    await gk.setBODKeeper(bodKeeper.address);
    await gk.setBOHKeeper(bohKeeper.address);
    await gk.setBOMKeeper(bomKeeper.address);
    await gk.setBOOKeeper(booKeeper.address);
    await gk.setBOPKeeper(bopKeeper.address);
    // await gk.setBOSKeeper(bosKeeper.address);
    await gk.setSHAKeeper(shaKeeper.address);

    await boaKeeper.setManager(1, accounts[0], gk.address);
    await bodKeeper.setManager(1, accounts[0], gk.address);
    await bohKeeper.setManager(1, accounts[0], gk.address);
    await bomKeeper.setManager(1, accounts[0], gk.address);
    await booKeeper.setManager(1, accounts[0], gk.address);
    await bopKeeper.setManager(1, accounts[0], gk.address);
    await shaKeeper.setManager(1, accounts[0], gk.address);

    // ==== TermsOfSHA ====
    await deployer.deploy(LU);
    let lu = await LU.deployed();
    await gk.addTermTemplate(1, lu.address);

    await deployer.deploy(AD);
    let ad = await AD.deployed();
    await gk.addTermTemplate(2, ad.address);

    await deployer.deploy(FR);
    let fr = await FR.deployed();
    await gk.addTermTemplate(3, fr.address);

    await deployer.deploy(GU);
    let gu = await GU.deployed();
    await gk.addTermTemplate(4, gu.address);

    await deployer.deploy(DA);
    let da = await DA.deployed();
    await gk.addTermTemplate(5, da.address);

    await deployer.deploy(TA);
    let ta = await TA.deployed();
    await gk.addTermTemplate(6, ta.address);

    await deployer.deploy(OP);
    let op = await OP.deployed();
    await gk.addTermTemplate(7, op.address);

    gk.setManager(1, accounts[0], accounts[1]);

};