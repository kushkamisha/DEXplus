pragma solidity ^0.5.0;

import "./Roles.sol";


/**
 * @title Exchange interface
 */
interface ExchangeInterface {
    function setERC20Token(uint index, address token) external;
    function setMainStatus(bool status) external;
    function createOrederERC20(uint price, uint amount, uint tokenId, uint expireDate) external returns(uint index);
    function fillOrederERC20(uint orderId) external payable returns(bool);

    event SetERC20Token(uint index, address token);
    event SetERC721Token(uint index, address token);    
    event SetMainStatus(bool mainStatus);
    event CreateOrederERC20(uint price, uint amount, uint tokenId, uint expireDate);
    event FillOrederERC20(uint orederId, address buyer);
    event CancelOrederERC20(uint orederId);
}


/**
 * @title ERC20 token interface
 */
interface ERC20Interface {
    function allowance(address wallet, address spender) external view returns (uint amount);
    function transfer(address to, uint amount) external returns (bool);
    function transferFrom(address from, address to, uint amount) external returns (bool);
}


/**
 * @title ERC721 token interface
 */
interface ERC721Interface {
    function getApproved(uint256 tokenId) external view returns (address);
    function transferFrom(address from, address to, uint256 tokenId) external;
}


/**
 * @title Exchange
 * @dev The Exchange contract is a smart contract.
 * It controll tokens transferring.
 */
contract Exchange is ExchangeInterface, Roles {
    bool public mainStatus;

    struct OrderERC20 {
        address payable owner;
        uint price;
        uint amount;
        uint tokenId;
        uint expireDate;
        bool status;
    }

    mapping (uint => ERC20Interface) public ERC20tokens;
    mapping (uint => ERC721Interface) public ERC721tokens;

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

    modifier createOrder(uint amount, uint tokenId, uint expireDate) {
        require(ERC20tokens[tokenId].allowance(msg.sender, address(this)) >= amount, "Not enought allowance.");
        require(expireDate > now, "Wrong expire date.");
        _;
    }

    modifier fillOrder(uint orderId) {
        require(ordersERC20[orderId].status, "Wrong order status.");
        require(ordersERC20[orderId].price == msg.value, "Not enought funds.");
        require(ordersERC20[orderId].expireDate > now, "Order is expired.");
        _;
    }

    modifier cancelOrder(uint orderId) {
        require(ordersERC20[orderId].status, "Wrong order status.");
        require(ordersERC20[orderId].owner == msg.sender, "Not enought funds.");
        _;
    }

    /**
     * @dev Create ERC20 oreder.
     * @param price uint The ETH price
     * @param amount uint The token amount
     * @param tokenId uint The token id
     * @param expireDate uint The expire date in timestamp
     */
    function createOrederERC20(uint price, uint amount, uint tokenId, uint expireDate) external isActive createOrder(amount, tokenId, expireDate) returns(uint index) {
        ERC20tokens[tokenId].transferFrom(msg.sender, address(this), amount);

        OrderERC20 memory order;
        index = ordersCountERC20;

        order.owner      = msg.sender;
        order.price      = price;
        order.amount     = amount;
        order.tokenId    = tokenId;
        order.expireDate = expireDate;
        order.status     = true;

        ordersERC20[index] = order;
        ordersCountERC20++;
        
        emit CreateOrederERC20(price, amount, tokenId, expireDate);
    }

    /**
     * @dev Fill ERC20 oreder.
     * @param orderId uint The order id
     */
    function fillOrederERC20(uint orderId) external payable isActive fillOrder(orderId) returns(bool) {
        ordersERC20[orderId].status = false;
        ordersERC20[orderId].owner.transfer(msg.value);
        ERC20tokens[ordersERC20[orderId].tokenId].transfer(msg.sender, ordersERC20[orderId].amount);

        emit FillOrederERC20(orderId, msg.sender);
        return true;
    }

    /**
     * @dev Cancel ERC20 oreder.
     * @param orderId uint The order id
     */
    function cancelOrederERC20(uint orderId) external isActive cancelOrder(orderId) returns(bool) {
        ordersERC20[orderId].status = false;
        ERC20tokens[ordersERC20[orderId].tokenId].transfer(ordersERC20[orderId].owner, ordersERC20[orderId].amount);
        emit CancelOrederERC20(orderId);
        return true;
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
     * @dev Add ERC721 token.
     * @param index uint The token index
     * @param token address The token contract address
     */
    function setERC721Token(uint index, address token) external onlyOwner {
        ERC721tokens[index] = ERC721Interface(token);
        emit SetERC721Token(index, token);
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
