// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title RebaseToken
 * @author Abhai
 * @notice This is a cross-chain rebase token that incentivises users to deposit into a vault and gain interest in rewards.
 * @notice The interest rate in the smart contract can only decrease
 * @notice Each will user will have their own interest rate that is the global interest rate at the time of depositing.
 */

contract RebaseToken is ERC20, Ownable, AccessControl {
    error RebaseToken_InterestRateIncreaseNotAllowed(uint256 oldInterestRate, uint256 newInterestRate);

    uint256 private constant PRECISION_FACTOR = 1e18;
    bytes32 private constant MINT_AND_BURN_ROLE = keccak256("MINT_AND_BURN_ROLE");
    uint256 private s_interestRate = (5 * PRECISION_FACTOR) / 1e8;
    mapping(address => uint256) private s_userInterestRates;
    mapping(address => uint256) private s_userLastUpdatedTimeStamp;

    event InterestRateSet(uint256 newInterestRate);

    constructor() ERC20("RebaseToken", "RBT") Ownable(msg.sender) {}

    function grantMintAndBurnRole(address _account) external onlyOwner {
        _grantRole(MINT_AND_BURN_ROLE, _account);
    }

    function setInterestRate(uint256 _newInterestRate) external onlyOwner {
        if (_newInterestRate >= s_interestRate) {
            revert RebaseToken_InterestRateIncreaseNotAllowed(s_interestRate, _newInterestRate);
        }
        s_interestRate = _newInterestRate;
        emit InterestRateSet(_newInterestRate);
    }

    function principleBalanceOf(address _user) external view returns (uint256) {
        return super.balanceOf(_user);
    }

    function mint(address _to, uint256 _amount, uint256 _userInterestRate) external onlyRole(MINT_AND_BURN_ROLE) {
        _mintAccruedInterest(_to);
        s_userInterestRates[_to] = _userInterestRate;
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) public onlyRole(MINT_AND_BURN_ROLE) {
        _mintAccruedInterest(_from);
        _burn(_from, _amount);
    }

    function balanceOf(address _user) public view override returns (uint256) {
        return (super.balanceOf(_user) * _calcUserAccumlatedInterestSinceLastUpdate(_user)) / PRECISION_FACTOR;
    }

    function transfer(address _recipient, uint256 _amount) public override returns (bool) {
        if (_amount == type(uint256).max) {
            _amount = balanceOf(msg.sender);
        }

        _mintAccruedInterest(msg.sender);
        _mintAccruedInterest(_recipient);

        if (balanceOf(_recipient) == 0) {
            s_userInterestRates[_recipient] = s_userInterestRates[msg.sender];
        }
        return super.transfer(_recipient, _amount);
    }

    function transferFrom(address _sender, address _recipient, uint256 _amount) public override returns (bool) {
        _mintAccruedInterest(_sender);
        _mintAccruedInterest(_recipient);
        if (_amount == type(uint256).max) {
            _amount = balanceOf(_sender);
        }
        if (balanceOf(_recipient) == 0) {
            s_userInterestRates[_recipient] = s_userInterestRates[_sender];
        }
        return super.transfer(_recipient, _amount);
    }

    function _calcUserAccumlatedInterestSinceLastUpdate(address _user) internal view returns (uint256 linearInterest) {
        uint256 timeElapsed = block.timestamp - s_userLastUpdatedTimeStamp[_user];
        linearInterest = (PRECISION_FACTOR + (s_userInterestRates[_user] * timeElapsed));
    }

    function _mintAccruedInterest(address _user) internal {
        uint256 previousPrincipleBalance = super.balanceOf(_user);
        uint256 currentBalance = balanceOf(_user);

        uint256 balanceChange = currentBalance - previousPrincipleBalance;
        if (balanceChange > 0) {
            _mint(_user, balanceChange);
        }
        s_userLastUpdatedTimeStamp[_user] = block.timestamp;
    }

    function getInterestRate() external view returns (uint256) {
        return s_interestRate;
    }

    function getUserInterestRate(address _user) external view returns (uint256) {
        return s_userInterestRates[_user];
    }
}
