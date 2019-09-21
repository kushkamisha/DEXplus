pragma solidity ^0.5.0;

import "./Roles.sol";


/**
 * @title Exchange interface
 */
interface ExchangeInterface {
    function setMainStatus(bool status) external;
    event SetMainStatus(bool mainStatus);
}


/**
 * @title Exchange
 * @dev The Exchange contract is a smart contract.
 * It controll tokens transferring.
 */
contract Exchange is ExchangeInterface, Roles {
    bool public mainStatus;

    constructor() public {
        mainStatus = true;
    }

    modifier isActive {
        require(mainStatus, "Platform is stopped.");
        _;
    }

    /**
     * @dev Set main status. Stop button.
     * @param status bool The main status
     */
    function setMainStatus(bool status) external onlyOwner {
        mainStatus = status;
        emit SetMainStatus(status);
    }
}
