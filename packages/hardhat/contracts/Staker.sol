// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;

  constructor(address exampleExternalContractAddress) public {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  mapping ( address => uint256 ) public balances;
  uint256 public constant threshold = 1 ether;
  uint256 public deadline = block.timestamp + 1 minutes;
  bool openForWithdraw;
  event Stake(address, uint256);

  modifier notCompleted() {
    require(!exampleExternalContract.completed(), "Has Been Completed");
    _;
  }
  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
  function stake() public payable notCompleted {
    require(msg.value > 0, "Enter an amount to stake");
    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, msg.value);
  }

  // After some `deadline` allow anyone to call an `execute()` function
  //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
  function execute() public notCompleted {
    //Function is only callable after deadline
    require(block.timestamp >= deadline);
    //check if balance of contract is greater than threshold value
    if(address(this).balance >= threshold) {
      exampleExternalContract.complete{value: address(this).balance}();
    }
    else if (address(this).balance < threshold) {
      openForWithdraw = true;
    }
  }


  // if the `threshold` was not met, allow everyone to call a `withdraw()` function


  // Add a `withdraw()` function to let users withdraw their balance
  function withdraw() public notCompleted {
    require(openForWithdraw == true&& balances[msg.sender] > 0, "Not open for withdrawal or zero staking balance lmao");
    uint256 amount = balances[msg.sender];
    balances[msg.sender] = 0;
    require(payable(msg.sender).send(amount), "Withdrawal Failed");
    
  }


  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() public view returns(uint256) {
    if(block.timestamp >= deadline) {
      return  0;
    }
    else {
      return deadline-block.timestamp;
    }
  }

  // Add the `receive()` special function that receives eth and calls stake()
  receive() external payable notCompleted{
    stake();
  }

}
