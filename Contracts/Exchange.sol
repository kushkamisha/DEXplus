pragma solidity ^0.5.0;

import "./Roles.sol";
import "./ERC20.sol";


/**
 * @title Exchange interface
 */
interface ExchangeInterface {
    function setERC20Token(uint index, address token) external;
    function setMainStatus(bool status) external;

    event SetERC20Token(uint index, address token);
    event SetMainStatus(bool mainStatus);
}


/**
 * @title Exchange
 * @dev The Exchange contract is a smart contract.
 * It controll tokens transferring.
 */
contract Exchange is ExchangeInterface, Roles {
    bool public mainStatus;

    mapping (uint => ERC20Interface) public ERC20tokens;

    constructor() public {
        mainStatus = true;
    }

    modifier isActive {
        require(mainStatus, "Platform is stopped.");
        _;
    }

    /**
     * @dev Add ERC20 token.
     * @param index uint The token index
     * @param token address The token contract address
     */
    function setERC20Token(uint index, address token) external onlyOwner {
        ERC20tokens[index] = ERC20Interface(token);
        emit SetERC20Token(index, token);
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
