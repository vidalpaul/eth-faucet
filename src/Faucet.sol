// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/security/Pausable.sol";
import "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

import "openzeppelin-contracts/contracts/utils/Address.sol";

contract Faucet is Ownable, Pausable, ReentrancyGuard {
    uint public amountAllowed = 1 ether;
    uint public balanceLimit = 10 ether;

    mapping(address => uint) public lockTime;

    string private constant ERR_NOT_FUNDED =
        "Not enough funds in the faucet. Please donate";
    string private constant ERR_LOCK_TIME =
        "Lock time has not expired. Please try again later";
    string private constant ERR_INVALID_ADDRESS = "Invalid address";
    string private constant ERR_ACCOUNT_EXCEEDS_LIMIT =
        "Beneficiary account balance exceeds balance limit";
    string private constant ERR_CONTRACT_ADDRESS =
        "Neither the requestor nor the beneficiary can be a contract";

    event InitialFund(uint amount);

    event TokensRequested(
        address indexed requestor,
        address indexed beneficiary,
        uint amount
    );
    event DonationReceived(address indexed donor, uint amount);

    constructor() payable {
        emit InitialFund(msg.value);
    }

    modifier faucetIsFunded() {
        require(address(this).balance > amountAllowed, ERR_NOT_FUNDED);
        _;
    }

    modifier lockTimeHasExpired() {
        require(block.timestamp > lockTime[msg.sender], ERR_LOCK_TIME);
        _;
    }

    modifier validAddress(address _address) {
        require(_address != address(0), ERR_INVALID_ADDRESS);
        _;
    }

    modifier requireBalanceBelowLimit(address _beneficiary) {
        require(_beneficiary.balance < 10 ether, ERR_ACCOUNT_EXCEEDS_LIMIT);
        _;
    }

    modifier isNotContract(address _address) {
        require(!Address.isContract(msg.sender), ERR_CONTRACT_ADDRESS);
        require(!Address.isContract(_address), ERR_CONTRACT_ADDRESS);
        _;
    }

    // Fallback function accepts Ether donations
    fallback() external payable {
        donateToFaucet();
    }

    receive() external payable {
        donateToFaucet();
    }

    function setAmountallowed(uint newAmountAllowed) public onlyOwner {
        amountAllowed = newAmountAllowed;
    }

    function setBalanceLimit(uint newBalanceLimit) public onlyOwner {
        balanceLimit = newBalanceLimit;
    }

    function donateToFaucet() public payable {
        emit DonationReceived(msg.sender, msg.value);
    }

    function requestTokens(
        address payable _beneficiary
    )
        public
        payable
        nonReentrant
        whenNotPaused
        faucetIsFunded
        lockTimeHasExpired
        isNotContract(_beneficiary)
        validAddress(_beneficiary)
        requireBalanceBelowLimit(_beneficiary)
    {
        _beneficiary.transfer(amountAllowed);

        lockTime[_beneficiary] = block.timestamp + 1 days;

        emit TokensRequested(msg.sender, _beneficiary, amountAllowed);
    }
}
