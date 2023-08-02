// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

// import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract Faucet {
    address public owner;
    uint public amountAllowed = 1 ether;
    uint public balanceLimit = 10 ether;

    mapping(address => uint) public lockTime;

    string public constant ERR_ONLY_OWNER =
        "Only owner can call this function.";
    string public constant ERR_NOT_FUNDED =
        "Not enough funds in the faucet. Please donate";
    string public constant ERR_LOCK_TIME =
        "Lock time has not expired. Please try again later";
    string public constant ERR_INVALID_ADDRESS = "Invalid address";
    string public constant ERR_ACCOUNT_EXCEEDS_LIMIT =
        "Beneficiary account balance exceeds balance limit";

    event InitialFund(uint amount);

    event TokensRequested(
        address indexed requestor,
        address indexed beneficiary,
        uint amount
    );
    event DonationReceived(address indexed donor, uint amount);

    constructor() payable {
        owner = msg.sender;
        emit InitialFund(msg.value);
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

    modifier validAddress(address _address) {
        require(_address != address(0), ERR_INVALID_ADDRESS);
        _;
    }

    modifier requireBalanceBelowLimit(address _beneficiary) {
        require(_beneficiary.balance < 10 ether, ERR_ACCOUNT_EXCEEDS_LIMIT);
        _;
    }

    // Fallback function accepts Ether donations
    fallback() external payable {
        emit DonationReceived(msg.sender, msg.value);
    }

    receive() external payable {
        emit DonationReceived(msg.sender, msg.value);
    }

    function setOwner(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    function setAmountallowed(uint newAmountAllowed) public onlyOwner {
        amountAllowed = newAmountAllowed;
    }

    function setBalanceLimit(uint newBalanceLimit) public onlyOwner {
        balanceLimit = newBalanceLimit;
    }

    function donateTofaucet() public payable {
        emit DonationReceived(msg.sender, msg.value);
    }

    function requestTokens(
        address payable _beneficiary
    )
        public
        payable
        faucetIsFunded
        lockTimeHasExpired
        validAddress(_beneficiary)
        requireBalanceBelowLimit(_beneficiary)
    {
        _beneficiary.transfer(amountAllowed);

        lockTime[_beneficiary] = block.timestamp + 1 days;

        emit TokensRequested(msg.sender, _beneficiary, amountAllowed);
    }
}
