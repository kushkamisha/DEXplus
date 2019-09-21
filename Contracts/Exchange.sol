pragma solidity ^0.5.0;

import "./Roles.sol";
import "./ERC20.sol";


/**
 * @title Exchange interface
 */
interface ExchangeInterface {
    function setERC20Token(uint index, address token) external;
    function setMainStatus(bool status) external;
    function createOrederERC20(uint price, uint amount, uint tokenId, uint expireDate) external returns(uint index);

    event SetERC20Token(uint index, address token);
    event SetMainStatus(bool mainStatus);
    event CreateOrederERC20(uint price, uint amount, uint tokenId, uint expireDate);
}


/**
 * @title Exchange
 * @dev The Exchange contract is a smart contract.
 * It controll tokens transferring.
 */
contract Exchange is ExchangeInterface, Roles {
    bool public mainStatus;

    struct OrderERC20 {
        uint price;
        uint amount;
        uint tokenId;
        uint expireDate;
    }

    mapping (uint => ERC20Interface) public ERC20tokens;

    mapping (uint => OrderERC20) public ordersERC20;
    uint ordersCountERC20;

    constructor() public {
        mainStatus = true;
        ordersCountERC20 = 0;
    }

    modifier isActive {
        require(mainStatus, "Platform is stopped.");
        _;
    }

    modifier checkOrder(uint amount, uint tokenId, uint expireDate) {
        require(ERC20tokens[tokenId].allowance(msg.sender, address(this)) >= amount, "Not enought allowance.");
        require(expireDate > now, "Wrong expire date.");
        _;
    }

    /**
     * @dev Create ERC20 oreder.
     * @param price uint The ETH price
     * @param amount uint The token amount
     * @param tokenId uint The token id
     * @param expireDate uint The expire date in timestamp
     */
    function createOrederERC20(uint price, uint amount, uint tokenId, uint expireDate) isActive checkOrder(amount, tokenId, expireDate) external returns(uint index) {
        ERC20tokens[tokenId].transferFrom(msg.sender, address(this), amount);
        
        OrderERC20 memory order;
        index = ordersCountERC20;

        order.price      = price;
        order.amount     = amount;
        order.tokenId    = tokenId;
        order.expireDate = expireDate;

        ordersERC20[index] = order;
        ordersCountERC20++;
        
        emit CreateOrederERC20(price, amount, tokenId, expireDate);
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
