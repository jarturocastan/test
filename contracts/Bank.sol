pragma solidity 0.8.0;
import "./IBank.sol";

contract Bank is IBank {

    constructor() {}

    mapping(address => Account) private accounts;

    function deposit(uint256 amount) external payable override returns(bool){
        require(amount == msg.value,"Amount is diferent of the real amount sent it by the bank");
        require(amount > 0,"Amount must be greater than 0");
        if (accounts[msg.sender].deposit > 0) {
            uint256 blocks = getDiferenceOfLastInterestBlockUntilNow(accounts[msg.sender].lastInterestBlock);
            uint256 rateBalance = getRate(accounts[msg.sender].deposit,blocks);
            amount += rateBalance;
        }
        accounts[msg.sender].deposit += amount;
        accounts[msg.sender].lastInterestBlock = block.number;
        emit Deposit(msg.sender,amount);
        return true;
    }

    function withdraw(uint256 amount) external override returns (uint256) {
        require(amount >= 0,"Amount must be 0 or gratter than 0 to send amount");
        require(accounts[msg.sender].deposit > 0,"Account not in the white list");
        uint256 withdrawAmount = 0;
        if (amount > 0) {
            uint256 blocks = getDiferenceOfLastInterestBlockUntilNow(accounts[msg.sender].lastInterestBlock);
            uint256 rateBalance = getRate(accounts[msg.sender].deposit,blocks);
            uint256 totalAmount = accounts[msg.sender].deposit + rateBalance;
            require(amount <= totalAmount,"Insufficent amount");
            accounts[msg.sender].deposit  = totalAmount - amount;
            accounts[msg.sender].lastInterestBlock = block.number;
            withdrawAmount = amount;
        } else {
            uint256 blocks = getDiferenceOfLastInterestBlockUntilNow(accounts[msg.sender].lastInterestBlock);
            uint256 rateBalance = getRate(accounts[msg.sender].deposit,blocks);
            withdrawAmount = accounts[msg.sender].deposit + rateBalance;
            accounts[msg.sender].deposit  = 0;
        }
        emit Withdraw(msg.sender,amount);
        return withdrawAmount;
    }

    function getDiferenceOfLastInterestBlockUntilNow(uint256 lastInterestBlock) private view returns(uint256) {
        return block.number - lastInterestBlock;
    }

    function getRate(uint256 amount, uint256 blocks) private view returns  (uint256) {
        return (30 * ((blocks/100) * 1000) * (amount* 100)) / 1000;
    }


    function getBalance(address sender) external  view override returns (uint256) {
        return accounts[sender].deposit+  getRate(accounts[sender].deposit,getDiferenceOfLastInterestBlockUntilNow(accounts[sender].lastInterestBlock));
    }
}