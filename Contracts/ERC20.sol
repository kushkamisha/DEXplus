pragma solidity ^0.5.0;

import "./SafeMath.sol";


/**
 * @title ERC20 interface
 */
interface ERC20Interface {
    function balanceOf(address wallet) external view returns (uint amount);
    function allowance(address wallet, address spender) external view returns (uint amount);
    function transfer(address to, uint amount) external returns (bool);
    function approve(address spender, uint amount) external returns (bool);
    function increaseApproval(address spender, uint amount) external returns (bool);
    function decreaseApproval(address spender, uint amount) external returns (bool);
    function transferFrom(address from, address to, uint amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint amount);
    event Burn(address indexed from, uint amount);
    event Approval(address indexed wallet, address indexed spender, uint amount);
}


/**
 * @title Standard ERC20 token
 * @dev Implementation of the basic standard token.
 */ 
contract ERC20 is ERC20Interface {
    using SafeMath for uint;

    mapping(address => uint) internal balances;
    mapping(address => mapping(address => uint)) internal allowed;

    uint public totalBurned;

    function() external payable {
        revert();
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param wallet address The address to query the the balance of.
     * @return An uint representing the amount owned by the passed address.
     */
    function balanceOf(address wallet) public view returns (uint amount) {
        amount = balances[wallet];
    }

    /**
     * @dev Function to check the amount of tokens that an wallet allowed to a
     * spender.
     * @param wallet address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return An uint specifying the amount of tokens still available for
     * the spender.
     */
    function allowance(address wallet, address spender) public view returns (uint amount) {
        amount = allowed[wallet][spender];
    }

    /**
     * @dev transfer token for a specified address.
     * Burn tokens mens send it to address(0).
     * @param to address The address to transfer to
     * @param amount uint The amount to be transferred
     * @return True if the operation was successful
     */
    function transfer(address to, uint amount) public returns (bool) {
        require(amount <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(amount);
        balances[to] = balances[to].add(amount);

        if (to == address(0)) {
            totalBurned = totalBurned.add(amount);
            emit Burn(msg.sender, amount);
        } else {
            emit Transfer(msg.sender, to, amount);
        }

        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens
     * on behalf of msg.sender. Beware that changing an allowance with this
     * method brings the risk that someone may use both the old and the new
     * allowance by unfortunate transaction ordering. One possible solution to
     * mitigate this race condition is to first reduce the spender's allowance
     * to 0 and set the desired value afterwards:
     * @param spender address The address which will spend the funds
     * @param amount uint The amount of tokens to be spent
     * @return True if the operation was successful
    */
    function approve(address spender, uint amount) public returns (bool) {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev Increase approval params for the passed address.
     * @param spender address The address which will spend the funds
     * @param amount uint The amount of tokens to be spent
     * @return True if the operation was successful
    */
    function increaseApproval(address spender, uint amount) public returns (bool) {
        allowed[msg.sender][spender] = allowed[msg.sender][spender].add(amount);
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decrease approval params for the passed address.
     * @param spender address The address which will spend the funds
     * @param amount uint The amount of tokens to be spent
     * @return True if the operation was successful
    */
    function decreaseApproval(address spender, uint amount) public returns (bool) {
        allowed[msg.sender][spender] = allowed[msg.sender][spender].sub(amount);
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    /**
    * @dev Transfer tokens from one address to another
    * @param from address The address which you want to send tokens from
    * @param to address The address which you want to transfer to
    * @param amount uint the amount of tokens to be transferred
    * @return True if the operation was successful
    */
    function transferFrom(address from, address to, uint amount) public returns (bool) {
        require(amount <= balances[from]);
        require(amount <= allowed[from][msg.sender]);

        balances[from] = balances[from].sub(amount);
        balances[to] = balances[to].add(amount);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(amount);

        if (to == address(0)) {
            totalBurned = totalBurned.add(amount);
            emit Burn(from, amount);
        } else {
            emit Transfer(from, to, amount);
        }

        return true;
    }
}
