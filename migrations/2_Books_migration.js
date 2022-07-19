var LibArrayUtils = artifacts.require("ArrayUtils");
var LibCheckpoints = artifacts.require("Checkpoints");
var LibEnumerableSet = artifacts.require("EnumerableSet");
var LibEnumsRepo = artifacts.require("EnumsRepo");
var LibObjsRepo = artifacts.require("ObjsRepo");
var LibRelationGraph = artifacts.require("RelationGraph");
var LibSNFactory = artifacts.require("SNFactory");
var LibSNParser = artifacts.require("SNParser");

var RC = artifacts.require("RegCenter");

var IA = artifacts.require("FirstRefusalToolKits");
var BOA = artifacts.require("BookOfIA");
var BOD = artifacts.require("BookOfDirectors");
var SHA = artifacts.require("ShareholdersAgreement");
var BOH = artifacts.require("BookOfSHA");
var BOM = artifacts.require("BookOfMotions");
var BOO = artifacts.require("BookOfOptions");
var BOP = artifacts.require("BookOfPledges");
var BOS = artifacts.require("BookOfShares");
var BOSCal = artifacts.require("BOSCalculator");

var BOAKeeper = artifacts.require("BOAKeeper");
var BODKeeper = artifacts.require("BODKeeper");
var BOHKeeper = artifacts.require("BOHKeeper");
var BOMKeeper = artifacts.require("BOMKeeper");
var BOOKeeper = artifacts.require("BOOKeeper");
var BOPKeeper = artifacts.require("BOPKeeper");
var SHAKeeper = artifacts.require("SHAKeeper");

var GK = artifacts.require("GeneralKeeper");

var AD = artifacts.require("AntiDilution");
var DA = artifacts.require("DragAlong");
var FR = artifacts.require("FirstRefusal");
var GU = artifacts.require("GroupsUpdate");
var LU = artifacts.require("LockUp");
var OP = artifacts.require("Options");
var TA = artifacts.require("TagAlong");
var VR = artifacts.require("VotingRules");

module.exports = async function (deployer, network, accounts) {

    await deployer.deploy(LibEnumerableSet);
    await deployer.link(LibEnumerableSet, [IA, BOA, BOD, SHA, BOH, BOM, BOO, BOP, BOS, BOSCal, RC, BOAKeeper, BODKeeper, BOHKeeper, BOMKeeper, BOOKeeper, BOPKeeper, SHAKeeper, GK, AD, DA, FR, GU, LU, OP, TA, VR, LibCheckpoints, LibEnumerableSet, LibObjsRepo, LibRelationGraph]);

    await deployer.deploy(LibArrayUtils);
    await deployer.link(LibArrayUtils, [AD, FR, LU, TA]);

    await deployer.deploy(LibCheckpoints);
    await deployer.link(LibCheckpoints, BOS);

    await deployer.deploy(LibEnumsRepo);
    await deployer.link(LibEnumsRepo, [IA, BOA, BOS, BOD, SHA, BOH, AD, DA, BOM, RC, BOAKeeper, BODKeeper, BOHKeeper, BOMKeeper, SHAKeeper, LibObjsRepo, LibRelationGraph]);

    await deployer.deploy(LibObjsRepo);
    await deployer.link(LibObjsRepo, [IA, BOA, BOD, BOH, BOM, BOS, BOO, BOP, SHA, AD, LU, OP]);

    await deployer.deploy(LibSNFactory);
    await deployer.link(LibSNFactory, [IA, BOA, BOD, BOH, BOM, BOO, BOP, BOS, DA, FR, GU, OP, VR]);

    await deployer.deploy(LibSNParser);
    await deployer.link(LibSNParser, [IA, BOA, BOD, BOH, BOM, BOO, BOP, BOS, BOSCal, BOAKeeper, BODKeeper, BOHKeeper, BOMKeeper, BOOKeeper, BOPKeeper, SHAKeeper, AD, DA, FR, GU, LU, OP, LibRelationGraph]);

    await deployer.deploy(LibRelationGraph);
    await deployer.link(LibRelationGraph, RC);

    await deployer.deploy(RC, 15);
    let rc = await RC.deployed();

    await deployer.deploy(BOS, "0x38301fb0b5fcf3aaa4b97c4771bb6c75546e313b4ce7057c51a8cc6a3ace9d7e", 50);
    let bos = await BOS.deployed();
    await bos.init(1, 1, rc.address);
    await bos.regThisContract(2, 0);

    // await deployer.deploy(IA);
    // let ia = await IA.deployed();
    // await ia.init(accounts[0], accounts[0]);

    // await deployer.deploy(BOA, "BookOfAgreement", accounts[0], accounts[0]);
    // let boa = await BOA.deployed();
    // await boa.setTemplate(ia.address);

    // await deployer.deploy(SHA);
    // let sha = await SHA.deployed();
    // await sha.init(accounts[0], accounts[0]);

    // await deployer.deploy(BOH, "BookOfSHA", accounts[0], accounts[0]);
    // let boh = await BOH.deployed();
    // await boh.setTemplate(sha.address);

    // await deployer.deploy(BOM, accounts[0]);
    // let bom = await BOM.deployed();
    // await bom.appointSubKeeper(accounts[0]);
    // await bom.setBOH(boh.address);
    // await bom.setBOS(bos.address);

    // await deployer.deploy(BOO, accounts[0]);
    // let boo = await BOO.deployed();
    // await boo.appointSubKeeper(accounts[0]);
    // await boo.setBOS(bos.address);

    // await deployer.deploy(BOP, accounts[0]);
    // let bop = await BOP.deployed();
    // await bop.appointSubKeeper(accounts[0]);
    // await bop.setBOS(bos.address);

    // await deployer.deploy(BOAKeeper, accounts[0]);
    // let boakeeper = await BOAKeeper.deployed();
    // await BOAkeeper.appointSubKeeper(accounts[0]);
    // await BOAkeeper.setBOA(boa.address);
    // await BOAkeeper.setBOH(boh.address);
    // await BOAkeeper.setBOM(bom.address);
    // await boakeeper.setBOS(bos.address);



    // await boa.setBOAkeeper(BOAkeeper.address);
    // await boh.setBOAkeeper(BOAkeeper.address);
    // await bom.setBOAkeeper(BOAkeeper.address);

    // await BOAkeeper.setBOAkeeper(accounts[1]);
};