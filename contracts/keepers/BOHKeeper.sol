/*
 * Copyright 2021 LI LI of JINGTIAN & GONGCHENG.
 * */

pragma solidity ^0.4.24;

import "../common/config/BOSSetting.sol";
import "../common/config/BOHSetting.sol";
import "../common/config/BOMSetting.sol";

import "../common/interfaces/IAdminSetting.sol";
import "../common/interfaces/IShareholdersAgreement.sol";
import "../common/interfaces/IBOSSetting.sol";
import "../common/interfaces/IBOMSetting.sol";
import "../common/interfaces/ISigPage.sol";

contract BOHKeeper is BOSSetting, BOHSetting, BOMSetting {
    address[15] public termsTemplate;

    constructor(address bookeeper) public {
        init(msg.sender, bookeeper);
    }

    // ################
    // ##   Events   ##
    // ################

    event AddTemplate(uint8 title, address add);

    // ##################
    // ##   Modifier   ##
    // ##################

    modifier beEstablished(address body) {
        require(ISigPage(body).isEstablished(), "Doc NOT Established");
        _;
    }

    modifier notEstablished(address body) {
        require(!ISigPage(body).isEstablished(), "Doc ALREADY Established");
        _;
    }

    modifier onlyAdminOf(address body) {
        require(
            IAdminSetting(body).getAdmin() == msg.sender,
            "NOT Admin of Doc"
        );
        _;
    }

    modifier onlyPartyOf(address body) {
        require(ISigPage(body).isParty(msg.sender), "NOT Party of Doc");
        _;
    }

    // #############
    // ##   SHA   ##
    // #############

    function addTermTemplate(uint8 title, address add) external onlyAdmin {
        termsTemplate[title] = add;
        emit AddTemplate(title, add);
    }

    function createSHA(uint8 docType)
        external
        onlyMember
        returns (address body)
    {
        body = _boh.createDoc(docType);

        IAdminSetting(body).init(msg.sender, this);
        IShareholdersAgreement(body).setTermsTemplate(termsTemplate);
        IBOSSetting(body).setBOS(address(_bos));
        IBOMSetting(body).setBOM(address(_bom));
    }

    function removeSHA(address body)
        external
        onlyAdminOf(body)
        notEstablished(body)
    {
        _boh.removeDoc(body);
    }

    function submitSHA(address body, bytes32 docHash)
        external
        onlyAdminOf(body)
        beEstablished(body)
    {
        _boh.submitSHA(body, docHash);

        IAdminSetting(body).abandonAdmin();
    }

    function effectiveSHA(address body) external onlyPartyOf(body) {
        require(_boh.isSubmitted(body), "SHA not submitted yet");
        // 将之前有效的SHA，撤销其效力
        if (_boh.pointer() != address(0))
            ISigPage(_boh.pointer()).updateStateOfDoc(5);

        _boh.changePointer(body);

        ISigPage(body).updateStateOfDoc(4);
    }
}
