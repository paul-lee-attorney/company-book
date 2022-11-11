// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../books/boh/ShareholdersAgreement.sol";
import "../books/boh/IShareholdersAgreement.sol";
import "../books/boh/terms/IGroupsUpdate.sol";

import "../common/components/ISigPage.sol";

import "../common/ruting/ROMSetting.sol";
import "../common/ruting/BOMSetting.sol";
import "../common/ruting/BOOSetting.sol";
import "../common/ruting/BOSSetting.sol";
import "../common/ruting/BODSetting.sol";
import "../common/ruting/SHASetting.sol";
import "../common/ruting/IBookSetting.sol";

import "../common/access/IAccessControl.sol";

import "../common/lib/SNParser.sol";

import "./IBOHKeeper.sol";

contract BOHKeeper is
    IBOHKeeper,
    BOASetting,
    BODSetting,
    SHASetting,
    BOMSetting,
    BOOSetting,
    BOSSetting,
    ROMSetting
{
    using SNParser for bytes32;

    // ##################
    // ##   Modifier   ##
    // ##################

    modifier notEstablished(address body) {
        require(!ISigPage(body).established(), "Doc ALREADY Established");
        _;
    }

    modifier onlyOwnerOf(address body, uint40 caller) {
        require(IAccessControl(body).getManager(0) == caller, "not Owner");
        _;
    }

    modifier onlyPartyOf(address body, uint40 caller) {
        require(ISigPage(body).isParty(caller), "NOT Party of Doc");
        _;
    }

    // #############
    // ##   SHA   ##
    // #############

    function addTermTemplate(
        uint8 title,
        address add,
        uint40 caller
    ) external onlyManager(1) {
        _boh.addTermTemplate(title, add, caller);
    }

    function createSHA(uint8 docType, address caller) external onlyManager(1) {
        require(_rom.isMember(_rc.userNo(caller)), "not MEMBER");
        address sha = _boh.createDoc(docType, _rc.userNo(caller));

        IAccessControl(sha).init(
            caller,
            address(this),
            address(_rc),
            address(_gk)
        );

        IBookSetting(sha).setBOA(address(_boa));
        IBookSetting(sha).setBOH(address(_boh));
        IBookSetting(sha).setBOS(address(_bos));
        IBookSetting(sha).setBOM(address(_bom));
        IBookSetting(sha).setROM(address(_rom));

        // copyRoleTo(KEEPERS, sha);
    }

    function removeSHA(address sha, uint40 caller)
        external
        onlyManager(1)
        onlyOwnerOf(sha, caller)
        notEstablished(sha)
    {
        _boh.removeDoc(sha);
    }

    function circulateSHA(address sha, address callerAddr)
        external
        onlyManager(1)
        onlyOwnerOf(sha, _rc.userNo(callerAddr))
    {
        address[] memory bodies = IShareholdersAgreement(sha).bodies();

        uint256 len = bodies.length;

        while (len > 0) {
            require(
                IAccessControl(bodies[len - 1]).finalized(),
                "BOHKeeper.circulateSHA: Term not finalized"
            );
            len--;
        }

        require(IAccessControl(sha).finalized(), "let GC finalize SHA first");

        IAccessControl(sha).setManager(0, callerAddr, address(0));

        // IAccessControl(sha).abandonOwnership();

        _boh.circulateDoc(sha, bytes32(0), _rc.userNo(callerAddr));
    }

    // ======== Sign SHA ========

    function signSHA(
        address sha,
        uint40 caller,
        bytes32 sigHash
    ) external onlyManager(1) onlyPartyOf(sha, caller) {
        require(
            _boh.currentState(sha) == uint8(DocumentsRepo.BODStates.Circulated),
            "SHA not in Circulated State"
        );

        ISigPage(sha).signDoc(caller, sigHash);

        if (ISigPage(sha).established()) _boh.pushToNextState(sha, caller);
    }

    function effectiveSHA(address sha, uint40 caller)
        external
        onlyManager(1)
        onlyPartyOf(sha, caller)
    {
        require(
            _boh.currentState(sha) ==
                uint8(DocumentsRepo.BODStates.Established),
            "SHA not executed yet"
        );

        uint40[] memory members = _rom.membersList();
        uint256 len = members.length;
        while (len > 0) {
            require(
                ISigPage(sha).isParty(members[len - 1]),
                "left member for SHA"
            );
            len--;
        }

        _boh.changePointer(sha, caller);

        _rom.setAmtBase(IShareholdersAgreement(sha).basedOnPar());

        _bod.setMaxQtyOfDirectors(
            IShareholdersAgreement(sha).maxNumOfDirectors()
        );

        if (
            IShareholdersAgreement(sha).hasTitle(
                uint8(ShareholdersAgreement.TermTitle.OPTIONS)
            )
        )
            _boo.registerOption(
                IShareholdersAgreement(sha).getTerm(
                    uint8(ShareholdersAgreement.TermTitle.OPTIONS)
                )
            );

        if (
            IShareholdersAgreement(sha).hasTitle(
                uint8(ShareholdersAgreement.TermTitle.GROUPS_UPDATE)
            )
        ) {
            bytes32[] memory guo = IGroupsUpdate(
                IShareholdersAgreement(sha).getTerm(
                    uint8(ShareholdersAgreement.TermTitle.GROUPS_UPDATE)
                )
            ).orders();
            len = guo.length;
            while (len > 0) {
                if (guo[len - 1].addMemberOfGUO())
                    _rom.addMemberToGroup(
                        guo[len - 1].memberOfGUO(),
                        guo[len - 1].groupNoOfGUO()
                    );
                else
                    _rom.removeMemberFromGroup(
                        guo[len - 1].memberOfGUO(),
                        guo[len - 1].groupNoOfGUO()
                    );
                len--;
            }
        }
    }
}
