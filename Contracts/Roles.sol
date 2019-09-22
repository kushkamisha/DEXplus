pragma solidity ^0.5.0;


/**
 * @title Roles interface
 */
interface RolesInterface {
    function transferOwnership(address newOwner) external returns (bool);
    function acceptOwnership() external returns (bool);
    function setModerator(address moderator) external returns (bool);

    event OwnershipTransferred(address indexed from, address indexed to);
    event NewModerator(address indexed wallet);
}


/**
 * @title Roles
 * @dev The Roles contract has an owner and moderator address, and provides
 * basic authorization control functions, this simplifies the implementation
 * of "user permissions".
 */
contract Roles is RolesInterface {
    address public owner;
    address public newOwner;
    address public moderator;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "msg.sender is not an owner.");
        _;
    }

    modifier onlyModerator {
        require(msg.sender == moderator, "msg.sender is not a moderator.");
        _;
    }

    /**
     * @dev Create transfer ownership request.
     * @param _newOwner address The address of new owner
     * @return True if the operation was successful
     */
    function transferOwnership(address _newOwner) external onlyOwner returns (bool) {
        newOwner = _newOwner;
        return true;
    }

    /**
     * @dev Accept transfer ownership request.
     * @return True if the operation was successful
     */
    function acceptOwnership() external returns (bool) {
        require(msg.sender == newOwner, "msg.sender is not a newOwner.");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
        return true;
    }

    /**
     * @dev Set moderator wallet.
     * @param _moderator address The address of new moderator
     * @return True if the operation was successful
     */
    function setModerator(address _moderator) external onlyOwner returns (bool) {
        emit NewModerator(_moderator);
        moderator = _moderator;
        return true;
    }
}
