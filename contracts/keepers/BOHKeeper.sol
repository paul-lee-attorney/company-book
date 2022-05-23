/*
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.4.24;

import "../books/boh/interfaces/IShareholdersAgreement.sol";
import "../books/boh/terms/interfaces/IGroupsUpdate.sol";

import "../common/components/EnumsRepo.sol";
import "../common/components/interfaces/ISigPage.sol";

import "../common/ruting/BOMSetting.sol";
import "../common/ruting/BOOSetting.sol";
import "../common/ruting/BOSSetting.sol";
import "../common/ruting/SHASetting.sol";
import "../common/access/interfaces/IAccessControl.sol";
import "../common/ruting/interfaces/IBookSetting.sol";
import "../common/access/interfaces/IRoles.sol";

import "../common/lib/SNParser.sol";

import "../common/utils/Context.sol";

contract BOHKeeper is
    EnumsRepo,
    BOSSetting,
    SHASetting,
    BOMSetting,
    BOOSetting,
    Context
{
    using SNParser for bytes32;

    address[15] public termsTemplate;

    // constructor(address bookeeper, address usersList) public {
    //     init(msg.sender, bookeeper);
    // }

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
            IAccessControl(body).getOwner() == _bridgedMsgSender,
            "NOT Admin of Doc"
        );
        _;
    }

    modifier onlyPartyOf(address body) {
        require(ISigPage(body).isParty(_bridgedMsgSender), "NOT Party of Doc");
        _;
    }

    // #############
    // ##   SHA   ##
    // #############

    function addTermTemplate(uint8 title, address add)
        external
        onlyDirectKeeper
    {
        require(_bridgedMsgSender == getOwner(), "not ADMIN");
        _clearMsgSender();

        termsTemplate[title] = add;
        emit AddTemplate(title, add);
    }

    function createSHA(uint8 docType) external onlyDirectKeeper {
        require(_bos.isMember(_bridgedMsgSender), "not MEMBER");
        address body = _boh.createDoc(docType);

        IAccessControl(body).init(
            _rc.userNo(_bridgedMsgSender),
            _rc.userNo(this),
            address(_rc)
        );
        _clearMsgSender();

        IShareholdersAgreement(body).setTermsTemplate(termsTemplate);
        IBookSetting(body).setBOM(address(_bom));
        IBookSetting(body).setBOS(address(_bos));
        IBookSetting(body).setBOSCal(address(_bosCal));

        _copyRoleTo(body, KEEPERS);
    }

    function removeSHA(address body)
        external
        onlyDirectKeeper
        onlyAdminOf(body)
        notEstablished(body)
    {
        _clearMsgSender();

        _boh.removeDoc(body);
        IShareholdersAgreement(body).kill();
    }

    function submitSHA(address body, bytes32 docHash)
        external
        onlyDirectKeeper
        onlyAdminOf(body)
        beEstablished(body)
    {
        _clearMsgSender();
        _boh.submitSHA(body, docHash);

        // IAccessControl(body).abandonAdmin();
    }

    function effectiveSHA(address body)
        external
        onlyDirectKeeper
        onlyPartyOf(body)
    {
        _clearMsgSender();

        require(_boh.isSubmitted(body), "SHA not submitted yet");

        if (_boh.pointer() != address(0))
            ISigPage(_boh.pointer()).updateStateOfDoc(5);

        _boh.changePointer(body);

        ISigPage(body).updateStateOfDoc(4);

        if (IShareholdersAgreement(body).hasTitle(uint8(TermTitle.OPTIONS)))
            _boo.registerOption(
                IShareholdersAgreement(body).getTerm(uint8(TermTitle.OPTIONS))
            );

        if (
            IShareholdersAgreement(body).hasTitle(
                uint8(TermTitle.GROUPS_UPDATE)
            )
        ) {
            bytes32[] memory guo = IGroupsUpdate(
                IShareholdersAgreement(body).getTerm(
                    uint8(TermTitle.GROUPS_UPDATE)
                )
            ).orders();
            uint256 len = guo.length;
            for (uint256 i = 0; i < len; i++) {
                if (guo[i].addMemberOfGUO())
                    _bos.addMemberToGroup(
                        guo[i].memberOfGUO(),
                        guo[i].groupNoOfGUO()
                    );
                else
                    _bos.removeMemberFromGroup(
                        guo[i].memberOfGUO(),
                        guo[i].groupNoOfGUO()
                    );
            }
        }
    }
}
