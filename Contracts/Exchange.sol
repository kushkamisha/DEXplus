pragma solidity ^0.5.0;

import "./Roles.sol";


/**
 * @title Exchange interface
 */
interface ExchangeInterface {
    function createERC20order(uint price, uint amount, uint tokenId, uint expireDate) external returns(uint id);
    function fillERC20order(uint orderId) external payable returns(bool);
    function cancelERC20order(uint orderId) external returns(bool);
    function setERC20token(uint index, address token) external;
        
    function createERC721order(uint price, uint index, uint tokenId, uint expireDate) external returns(uint id);
    function fillERC721order(uint orderId) external payable returns(bool);
    function cancelERC721order(uint orderId) external returns(bool);
    function setERC721token(uint index, address token) external;
    
    function setMainStatus(bool status) external;

    event CreateERC20order(uint price, uint amount, uint tokenId, uint expireDate);
    event FillERC20order(uint orederId, address buyer);
    event CancelERC20order(uint orederId);
    event SetERC20token(uint index, address token);

    event CreateERC721order(uint price, uint index, uint tokenId, uint expireDate);
    event FillERC721order(uint orederId, address buyer);
    event CancelERC721order(uint orederId);
    event SetERC721token(uint index, address token);
    
    event SetMainStatus(bool mainStatus);
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
        uint orderId;
        address payable owner;
        uint price;
        uint amount;
        uint tokenId;
        uint expireDate;
        bool status;
    }

    struct OrderERC721 {
        uint orderId;
        address payable owner;
        uint price;
        uint index;
        uint tokenId;
        uint expireDate;
        bool status;
    }

    mapping (uint => ERC20Interface) public ERC20tokens;
    mapping (uint => ERC721Interface) public ERC721tokens;

    mapping (uint => OrderERC20) public ordersERC20;
    uint ordersCountERC20;

    mapping (uint => OrderERC721) public ordersERC721;
    uint ordersCountERC721;

    constructor() public {
        mainStatus = true;
        ordersCountERC20 = 0;
    }

    modifier isActive {
        require(mainStatus, "Platform is stopped.");
        _;
    }

    modifier checkOrderERC20(uint amount, uint tokenId, uint expireDate) {
        require(ERC20tokens[tokenId].allowance(msg.sender, address(this)) >= amount, "Not enought allowance.");
        require(expireDate > now, "Wrong expire date.");
        _;
    }

    modifier fillOrderERC20(uint orderId) {
        require(ordersERC20[orderId].status, "Wrong order status.");
        require(ordersERC20[orderId].price == msg.value, "Not enought funds.");
        require(ordersERC20[orderId].expireDate > now, "Order is expired.");
        _;
    }

    modifier cancelOrderERC20(uint orderId) {
        require(ordersERC20[orderId].status, "Wrong order status.");
        require(ordersERC20[orderId].owner == msg.sender, "Not enought funds.");
        _;
    }

    modifier checkOrderERC721(uint index, uint tokenId, uint expireDate) {
        require(ERC721tokens[tokenId].getApproved(index) == address(this), "Can't get allowance.");
        require(expireDate > now, "Wrong expire date.");
        _;
    }

    modifier fillOrderERC721(uint orderId) {
        require(ordersERC721[orderId].status, "Wrong order status.");
        require(ordersERC721[orderId].price == msg.value, "Not enought funds.");
        require(ordersERC721[orderId].expireDate > now, "Order is expired.");
        _;
    }

    modifier cancelOrderERC721(uint orderId) {
        require(ordersERC721[orderId].status, "Wrong order status.");
        require(ordersERC721[orderId].owner == msg.sender, "Not enought funds.");
        _;
    }

    /**
     * @dev Create ERC20 oreder.
     * @param price uint The ETH price
     * @param amount uint The token amount
     * @param tokenId uint The token id
     * @param expireDate uint The expire date in timestamp
     */
    function createERC20order(uint price, uint amount, uint tokenId, uint expireDate) external isActive checkOrderERC20(amount, tokenId, expireDate) returns(uint id) {
        ERC20tokens[tokenId].transferFrom(msg.sender, address(this), amount);

        OrderERC20 memory order;
        id = ordersCountERC20;

        order.orderId    = id;
        order.owner      = msg.sender;
        order.price      = price;
        order.amount     = amount;
        order.tokenId    = tokenId;
        order.expireDate = expireDate;
        order.status     = true;

        ordersERC20[id] = order;
        ordersCountERC20++;
        
        emit CreateERC20order(price, amount, tokenId, expireDate);
    }

    /**
     * @dev Fill ERC20 oreder.
     * @param orderId uint The order id
     */
    function fillERC20order(uint orderId) external payable isActive fillOrderERC20(orderId) returns(bool) {
        ordersERC20[orderId].status = false;
        ordersERC20[orderId].owner.transfer(msg.value);
        ERC20tokens[ordersERC20[orderId].tokenId].transfer(msg.sender, ordersERC20[orderId].amount);

        emit FillERC20order(orderId, msg.sender);
        return true;
    }

    /**
     * @dev Cancel ERC20 oreder.
     * @param orderId uint The order id
     */
    function cancelERC20order(uint orderId) external isActive cancelOrderERC20(orderId) returns(bool) {
        ordersERC20[orderId].status = false;
        ERC20tokens[ordersERC20[orderId].tokenId].transfer(ordersERC20[orderId].owner, ordersERC20[orderId].amount);
        emit CancelERC20order(orderId);
        return true;
    }

    /**
     * @dev Add ERC20 token.
     * @param index uint The token index
     * @param token address The token contract address
     */
    function setERC20token(uint index, address token) external onlyOwner {
        ERC20tokens[index] = ERC20Interface(token);
        emit SetERC20token(index, token);
    }

    /**
     * @dev Create ERC721 oreder.
     * @param price uint The ETH price
     * @param index uint The token index
     * @param tokenId uint The token id
     * @param expireDate uint The expire date in timestamp
     */
    function createERC721order(uint price, uint index, uint tokenId, uint expireDate) external isActive checkOrderERC721(index, tokenId, expireDate) returns(uint id) {
        ERC721tokens[tokenId].transferFrom(msg.sender, address(this), index);

        OrderERC721 memory order;
        id = ordersCountERC20;

        order.orderId    = id;
        order.owner      = msg.sender;
        order.price      = price;
        order.index      = index;
        order.tokenId    = tokenId;
        order.expireDate = expireDate;
        order.status     = true;

        ordersERC721[id] = order;
        ordersCountERC721++;
        
        emit CreateERC721order(price, index, tokenId, expireDate);
        return id;
    }

    /**
     * @dev Fill ERC721 oreder.
     * @param orderId uint The order id
     */
    function fillERC721order(uint orderId) external payable isActive fillOrderERC721(orderId) returns(bool) {
        ordersERC721[orderId].status = false;
        ordersERC721[orderId].owner.transfer(msg.value);
        ERC721tokens[ordersERC721[orderId].tokenId].transferFrom(address(this), msg.sender, ordersERC721[orderId].index);

        emit FillERC721order(orderId, msg.sender);
        return true;
    }

    /**
     * @dev Cancel ERC721 oreder.
     * @param orderId uint The order id
     */
    function cancelERC721order(uint orderId) external isActive cancelOrderERC721(orderId) returns(bool) {
        ordersERC721[orderId].status = false;
        ERC721tokens[ordersERC721[orderId].tokenId].transferFrom(address(this), ordersERC721[orderId].owner, ordersERC721[orderId].index);
        emit CancelERC721order(orderId);
        return true;
    }

    /**
     * @dev Add ERC721 token.
     * @param index uint The token index
     * @param token address The token contract address
     */
    function setERC721token(uint index, address token) external onlyOwner {
        ERC721tokens[index] = ERC721Interface(token);
        emit SetERC721token(index, token);
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
