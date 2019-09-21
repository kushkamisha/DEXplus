pragma solidity ^0.5.0;

import "./ERC20.sol";


/**
 * @title SLC token
 * @dev Implementation of mintable stacking token
 */
contract SLC is ERC20 {
    string public constant NAME = "Silence";
    string public constant SYMBOL = "SLC";
    uint public constant DECIMAL = 18;

    constructor() public {
        balances[msg.sender] = balances[msg.sender].add(100000 * 10 ** DECIMAL);
    }
}
