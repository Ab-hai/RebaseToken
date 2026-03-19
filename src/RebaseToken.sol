// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/*
 * @title RebaseToken
 * @author Abhai
 * @notice This is a cross-chain rebase token that incentivises users to deposit into a vault and gain interest in rewards.
 * @notice The interest rate in the smart contract can only decrease
 * @notice Each will user will have their own interest rate that is the global interest rate at the time of depositing.
 */

contract RebaseToken is ERC20 {
    error RebaseToken_InterestRateIncreaseNotAllowed(uint256 oldInterestRate, uint256 newInterestRate);

    uint256 private constant PRECISION_FACTOR = 1e18;
    uint256 private s_interestRate = 5e10;
    mapping(address => uint256) private s_userInterestRates;
    mapping(address => uint256) private s_userLastUpdatedTimeStamp;

    event InterestRateSet(uint256 newInterestRate);

    constructor() ERC20("RebaseToken", "RBT") {}

    function setInterestRate(uint256 _newInterestRate) external {
        if (_newInterestRate > s_interestRate) {
            revert RebaseToken_InterestRateIncreaseNotAllowed(s_interestRate, _newInterestRate);
        }
        s_interestRate = _newInterestRate;
        emit InterestRateSet(_newInterestRate);
    }

    function mint(address _to, uint256 _amount) external {
        _mintAccruedInterest(_to);
        s_userInterestRates[_to] = s_interestRate;
        _mint(_to, _amount);
    }

    function balanceOf(address _user) public view override returns (uint256) {
        return (super.balanceOf(_user) * _calcUserAccumlatedInterestSinceLastUpdate(_user)) / PRECISION_FACTOR;
    }

    function _calcUserAccumlatedInterestSinceLastUpdate(address _user) internal view returns (uint256 linearInterest) {
        uint256 timeElapsed = block.timestamp - s_userLastUpdatedTimeStamp[_user];
        linearInterest = (PRECISION_FACTOR + (s_userInterestRates[_user] * timeElapsed));
    }

    function _mintAccruedInterest(address _to) internal {}

    function getUserInterestRate() external view returns (uint256) {
        return s_userInterestRates[msg.sender];
    }
}
