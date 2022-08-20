const LibArrayUtils = artifacts.require("ArrayUtils");
const LibCheckpoints = artifacts.require("Checkpoints");
const LibEnumerableSet = artifacts.require("EnumerableSet");
const LibEnumsRepo = artifacts.require("EnumsRepo");
const LibObjsRepo = artifacts.require("ObjsRepo");
const LibRelationGraph = artifacts.require("RelationGraph");
const LibSNFactory = artifacts.require("SNFactory");
const LibSNParser = artifacts.require("SNParser");

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
    await deployer.link(LibEnumerableSet, [IA, MR, BOA, BOD, SHA, BOH, BOM, BOO, BOP, BOS, BOSCal, RC, BOAKeeper, BODKeeper, BOHKeeper, BOMKeeper, BOOKeeper, BOPKeeper, SHAKeeper, GK, AD, DA, FR, GU, LU, OP, TA, LibCheckpoints, LibEnumerableSet, LibObjsRepo, LibRelationGraph]);

    await deployer.deploy(LibArrayUtils);
    await deployer.link(LibArrayUtils, [AD, FR, LU, TA]);

    await deployer.deploy(LibCheckpoints);
    await deployer.link(LibCheckpoints, BOS);

    await deployer.deploy(LibEnumsRepo);
    await deployer.link(LibEnumsRepo, [IA, BOA, BOS, BOD, SHA, BOH, AD, DA, BOM, RC, BOAKeeper, BODKeeper, BOHKeeper, BOMKeeper, SHAKeeper, LibObjsRepo, LibRelationGraph]);

    await deployer.deploy(LibObjsRepo);
    await deployer.link(LibObjsRepo, [IA, BOA, BOD, BOH, BOM, BOS, BOO, BOP, SHA, AD, LU, OP]);

    await deployer.deploy(LibSNFactory);
    await deployer.link(LibSNFactory, [IA, BOA, BOD, BOH, BOM, BOO, BOP, BOS, DA, FR, GU, OP]);

    await deployer.deploy(LibSNParser);
    await deployer.link(LibSNParser, [IA, BOA, BOD, BOH, BOM, BOO, BOP, BOS, BOSCal, BOAKeeper, BODKeeper, BOHKeeper, BOMKeeper, BOOKeeper, BOPKeeper, SHAKeeper, AD, DA, FR, GU, LU, OP, LibRelationGraph]);

    await deployer.deploy(LibRelationGraph);
    await deployer.link(LibRelationGraph, RC);

    // ==== RegCenter ====

    await deployer.deploy(RC, 15);
    let rc = await RC.deployed();

    await rc.regUser(1, 0, {
        from: accounts[1]
    });

    // ==== Entity / BOS ====

    await deployer.deploy(BOS, "0x38301fb0b5fcf3aaa4b97c4771bb6c75546e313b4ce7057c51a8cc6a3ace9d7e", 50);
    let bos = await BOS.deployed();
    await bos.init(accounts[0], accounts[0], rc.address, 2, 0);
    let companyNo = await rc.userNo(bos.address);

    await deployer.deploy(BOSCal);
    let bosCal = await BOSCal.deployed();
    await bosCal.init(accounts[0], accounts[0], rc.address, 17, companyNo.toNumber());

    // ==== Keepers ====

    await deployer.deploy(GK);
    let gk = await GK.deployed();
    await gk.init(accounts[0], accounts[0], rc.address, 9, companyNo.toNumber());

    await deployer.deploy(BOAKeeper);
    let boaKeeper = await BOAKeeper.deployed();
    await boaKeeper.init(accounts[0], gk.address, rc.address, 10, companyNo.toNumber());

    let acct1 = await rc.userNo(accounts[1]);

    await bos.grantRole("0xdea0b28c65859df30ee7d304fe077244fb2f08c9a834ba25ac340474a46a026a", acct1.toNumber());

    await bos.setManager(1, boaKeeper.address);
    await bosCal.setManager(1, boaKeeper.address);

    await deployer.deploy(BODKeeper);
    let bodKeeper = await BODKeeper.deployed();
    await bodKeeper.init(accounts[0], gk.address, rc.address, 11, companyNo.toNumber());

    await deployer.deploy(BOHKeeper);
    let bohKeeper = await BOHKeeper.deployed();
    await bohKeeper.init(accounts[0], gk.address, rc.address, 12, companyNo.toNumber());

    await deployer.deploy(BOMKeeper);
    let bomKeeper = await BOMKeeper.deployed();
    await bomKeeper.init(accounts[0], gk.address, rc.address, 13, companyNo.toNumber());

    await deployer.deploy(BOOKeeper);
    let booKeeper = await BOOKeeper.deployed();
    await booKeeper.init(accounts[0], gk.address, rc.address, 14, companyNo.toNumber());

    await deployer.deploy(BOPKeeper);
    let bopKeeper = await BOPKeeper.deployed();
    await bopKeeper.init(accounts[0], gk.address, rc.address, 15, companyNo.toNumber());

    await deployer.deploy(SHAKeeper);
    let shaKeeper = await SHAKeeper.deployed();
    await shaKeeper.init(accounts[0], gk.address, rc.address, 16, companyNo.toNumber());

    await gk.setBOAKeeper(boaKeeper.address);
    await gk.setBODKeeper(bodKeeper.address);
    await gk.setBOHKeeper(bohKeeper.address);
    await gk.setBOMKeeper(bomKeeper.address);
    await gk.setBOOKeeper(booKeeper.address);
    await gk.setBOPKeeper(bopKeeper.address);
    await gk.setSHAKeeper(shaKeeper.address);

    await gk.grantKeepers(boaKeeper.address);
    await gk.grantKeepers(bodKeeper.address);
    await gk.grantKeepers(bohKeeper.address);
    await gk.grantKeepers(bomKeeper.address);
    await gk.grantKeepers(booKeeper.address);
    await gk.grantKeepers(bopKeeper.address);
    await gk.grantKeepers(shaKeeper.address);

    // ==== Books ====

    await boaKeeper.copyRoleTo("0xdea0b28c65859df30ee7d304fe077244fb2f08c9a834ba25ac340474a46a026a", bos.address);

    await deployer.deploy(BOA);
    let boa = await BOA.deployed();
    await boa.init(accounts[0], boaKeeper.address, rc.address, 5, companyNo.toNumber());
    await boaKeeper.copyRoleTo("0xdea0b28c65859df30ee7d304fe077244fb2f08c9a834ba25ac340474a46a026a", boa.address);

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
    await boh.init(accounts[0], bohKeeper.address, rc.address, 6, companyNo.toNumber());
    await bohKeeper.copyRoleTo("0xdea0b28c65859df30ee7d304fe077244fb2f08c9a834ba25ac340474a46a026a", boh.address);

    await deployer.deploy(SHA);
    let sha = await SHA.deployed();
    await boh.setTemplate(sha.address, 0);

    await deployer.deploy(BOM);
    let bom = await BOM.deployed();
    await bom.init(accounts[0], accounts[0], rc.address, 3, companyNo.toNumber());
    await bom.setBOA(boa.address);
    await bom.setBOH(boh.address);
    await bom.setBOS(bos.address);
    await bom.setBOSCal(bosCal.address);
    await bom.setManager(1, bomKeeper.address);
    await bomKeeper.copyRoleTo("0xdea0b28c65859df30ee7d304fe077244fb2f08c9a834ba25ac340474a46a026a", bom.address);

    await deployer.deploy(BOD);
    let bod = await BOD.deployed();
    await bod.init(accounts[0], accounts[0], rc.address, 4, companyNo.toNumber());
    await bod.setBOH(boh.address);
    await bod.setManager(1, bodKeeper.address);
    await bodKeeper.copyRoleTo("0xdea0b28c65859df30ee7d304fe077244fb2f08c9a834ba25ac340474a46a026a", bod.address);

    await deployer.deploy(BOO);
    let boo = await BOO.deployed();
    await boo.init(accounts[0], accounts[0], rc.address, 7, companyNo.toNumber());
    await boo.setBOS(bos.address);
    await boo.setBOSCal(bosCal.address);
    await boo.setManager(1, booKeeper.address);
    await booKeeper.copyRoleTo("0xdea0b28c65859df30ee7d304fe077244fb2f08c9a834ba25ac340474a46a026a", boo.address);

    await deployer.deploy(BOP);
    let bop = await BOP.deployed();
    await bop.init(accounts[0], accounts[0], rc.address, 8, companyNo.toNumber());
    await bop.setBOS(bos.address);
    await bop.setBOSCal(bosCal.address);
    await bop.setManager(1, bopKeeper.address);
    await bopKeeper.copyRoleTo("0xdea0b28c65859df30ee7d304fe077244fb2f08c9a834ba25ac340474a46a026a", bop.address);

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
};