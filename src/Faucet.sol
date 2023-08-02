// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract Faucet {
    address public owner;
    uint public amountAllowed = 1000000000000000000;

    mapping(address => uint) public lockTime;

    string public constant ERR_ONLY_OWNER =
        "Only owner can call this function.";
    string public constant ERR_NOT_FUNDED =
        "Not enough funds in the faucet. Please donate";
    string public constant ERR_LOCK_TIME =
        "Lock time has not expired. Please try again later";

    event TokensRequested(address indexed requestor, uint amount);
    event DonationReceived(address indexed donor, uint amount);

    constructor() payable {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, ERR_ONLY_OWNER);
        _;
    }

    modifier faucetIsFunded() {
        require(address(this).balance > amountAllowed, ERR_NOT_FUNDED);
        _;
    }

    modifier lockTimeHasExpired() {
        require(block.timestamp > lockTime[msg.sender], ERR_LOCK_TIME);
        _;
    }

    function setOwner(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    function setAmountallowed(uint newAmountAllowed) public onlyOwner {
        amountAllowed = newAmountAllowed;
    }

    function donateTofaucet() public payable {
        emit DonationReceived(msg.sender, msg.value);
    }

    function requestTokens(
        address payable _requestor
    ) public payable faucetIsFunded lockTimeHasExpired {
        _requestor.transfer(amountAllowed);

        lockTime[msg.sender] = block.timestamp + 1 days;

        emit TokensRequested(msg.sender, amountAllowed);
    }
}
