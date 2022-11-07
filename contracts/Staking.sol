// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./SafeBEP20.sol";

contract StakingPlatform is Ownable {
    
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;
    
    // args for _stakers
    struct Staker {
        uint256 stakerCurrentReward;
        uint256 stakedAmount;
        uint256 mode;
        uint256 stakeStartTime;
        uint256 lastUpdatedTime;
        uint256 staked;
    }   
    
    // refer to CRSFANS token. Address: 0x7AD8A62451f79399c940fC1A6FE96358a80B1931
    
    uint256 private _unstakingFeeRate;
    uint256 private _eventPeriod;
    uint256 private _rewardRate;
    uint256 private _rewardFeeRate;
    uint256 private _lockupPeriod;
    uint256 private _minStakeAmount_m;
    uint256 private _minStakeAmount_g;
    uint256 private _minStakeAmount_s;
    uint256 private _minStakeAmount_c;
    
    address[] private _stakers;

    mapping(address => Staker) private _staker;

    // Total amount of token staked in staking pool.
    uint256 public totalStaked;
    IBEP20 public token;
    
    // Events triggered when start, stake, unstake(withdraw), get reward.
    event Staked(address staker, uint256 amount);
    event Harvest(address staker, uint256 rewardToClaim);
    event Withdraw(address staker, uint256 amount);
    event SetRewardRate(uint256 rewardRate);
    event SetEventPeriod(uint256 lockupDuration);
    event SetUnstakingFeeRate(uint256 unstakingFeeRate);

    constructor(address _token) {
        
        Init();
        token = IBEP20(_token);
    }

    function Init() internal {
        
        _rewardRate = 200; // per day
        _unstakingFeeRate = 1500;
        _rewardFeeRate = 100;
        _eventPeriod = 7;
        _lockupPeriod = 90;
        _minStakeAmount_m = 3* 1e24;
        _minStakeAmount_c = 1e24;
        _minStakeAmount_s = 3 * 1e24;
        _minStakeAmount_g = 7 * 1e24;
    }

    // Update rewards for _stakers according to deposited amount.
    function updateReward() private{
        
        uint256 stakerStakedAmount = _staker[msg.sender].stakedAmount;
        
        uint256 newReward = stakerStakedAmount.mul(block.timestamp.sub(_staker[msg.sender].lastUpdatedTime)).mul(_rewardRate).div(1 days).div(1e4);
        _staker[msg.sender].stakerCurrentReward = _staker[msg.sender].stakerCurrentReward.add(newReward);
        _staker[msg.sender].lastUpdatedTime = block.timestamp;
    }
    
    function startStaking(uint256 _amount, uint256 _mode) external {
        
        require(_amount > 0, "Amount should be greater than 0");
        require(token.balanceOf(msg.sender) > _amount, "Insufficient!");
        require(isLocked(msg.sender) == 0, "Can't start");
        
        if (_mode == 0) require(_amount >= _minStakeAmount_m, "Insufficient");
        else if (_mode == 1) require(_amount >= _minStakeAmount_c, "Insufficient");
        else if (_mode == 2) require(_amount >= _minStakeAmount_s, "Insufficient");
        else if (_mode == 3) require(_amount >= _minStakeAmount_g, "Insufficient");
        else require(_amount < 0, "Invalid Mode");
        
        _staker[msg.sender].mode = _mode;
        _staker[msg.sender].stakeStartTime = block.timestamp;
        _staker[msg.sender].staked = 55;
        _stakers.push(msg.sender);
        stake(_amount);
    }
    
    // Staker tries to stake specific amount of token.
    function stake(uint256 _amount) public{
        
        require(_amount > 0, "Amount should be greater than 0");
        require(token.balanceOf(msg.sender) > _amount, "Insufficient!");
        require(_staker[msg.sender].staked == 55, "Error: invalid staker");
        
        updateReward();
        
        token.safeTransferFrom(msg.sender, address(this), _amount);
        _staker[msg.sender].stakedAmount = _staker[msg.sender].stakedAmount.add(_amount);
        totalStaked = totalStaked.add(_amount);
        
        emit Staked(msg.sender, _amount);
    }

    function getTotalStaked() public view returns (uint256) {

        return totalStaked;
    }

    function getNumberofStakers() public view returns (uint256) {

        return _stakers.length;
    }

    function getStakerMode(address _address) public view returns (uint256) {

        require(isStartStaking(_address) == 55, "Not staker yet");
        return _staker[_address].mode;
    }
    
    function isStartStaking(address _address) public view returns (uint256) {

        return _staker[_address].staked;
    }

    function isLocked(address _address) public view returns (uint256) {

        if (_staker[_address].staked != 55)
            return 0;
        if (_staker[_address].mode != 0)
            return block.timestamp.sub(_staker[_address].stakeStartTime).div(1 days) % 7 == 0 ? 0 : 1;
        else 
            return block.timestamp.sub(_staker[_address].stakeStartTime) >= _lockupPeriod.mul(1 days) ? 0 : 1;
    }
    
    function stakedAmount(address _address) public view returns (uint256) {
        
        return _staker[_address].stakedAmount;
    }

    function getRewardRate() public view returns (uint256) {

        return _rewardRate;
    }

    function lockupPeriod(uint256 mode) public view returns (uint256) {
        
        if (mode == 0) return _lockupPeriod;
        return _eventPeriod;
    }

    function eventPeriod() public view returns (uint256) {
        
        return _eventPeriod;
    }

    function unstakingFeeLate() public view returns (uint256) {

        return _unstakingFeeRate;
    }

    // Amount of reward staker can be guaranteed.
    function rewardToHarvest(address _address) public view returns (uint256){
        
        uint256 stakerStakedAmount = _staker[_address].stakedAmount;
        uint256 newReward = stakerStakedAmount.mul(block.timestamp.sub(_staker[_address].lastUpdatedTime)).mul(_rewardRate).div(1 days).div(1e4);
        
        return _staker[msg.sender].stakerCurrentReward + newReward;
    }

    // Withdraw some of token staked.
    function withdraw(uint256 amount) external{
        
        require(amount > 0, "Amount should be greater than 0");
        require(amount <= _staker[msg.sender].stakedAmount, "Invalid amount");

        updateReward();
        uint256 amountTobeWithdrawn = amount >= token.balanceOf(address(this)) ? token.balanceOf(address(this)) : amount;
        uint256 during = block.timestamp.sub(_staker[msg.sender].stakeStartTime).div(1 days);
        uint256 fee = 100;
        bool isLockupTimeOver = _staker[msg.sender].mode != 0 ? during % _eventPeriod == 0 && during > 0 :
            block.timestamp >= _staker[msg.sender].stakeStartTime.add(_lockupPeriod.mul(1 days));
        if (!isLockupTimeOver) {
            fee = _unstakingFeeRate;
        }
        _staker[msg.sender].stakedAmount = _staker[msg.sender].stakedAmount.sub(amountTobeWithdrawn);
        totalStaked = totalStaked.sub(amountTobeWithdrawn);
        uint256 amountReflectFee = amountTobeWithdrawn.sub(amountTobeWithdrawn.mul(fee).div(1e4));
        
        token.safeTransfer(msg.sender, amountReflectFee);
        token.safeTransfer(owner(), amountTobeWithdrawn.sub(amountReflectFee));

        emit Withdraw(msg.sender, amountReflectFee);
    }
    
    function setRewardRate(uint256 __rewardRate) external onlyOwner {
        
        require(__rewardRate > 0, "Invalid value");
        
        _rewardRate = __rewardRate;

        emit SetRewardRate(__rewardRate);
    }

    function setEventPeriod(uint256 __eventPeriod) external onlyOwner {
        
        require(__eventPeriod > 0, "Invalid Lockup Duration");

        _eventPeriod = __eventPeriod;

        emit SetEventPeriod(__eventPeriod);
    }

    function setUnstakingFeeRate(uint256 __unstakingFeeRate) external onlyOwner {
        
        require(__unstakingFeeRate > 0, "Invalid Unstaking Fee Rate");

        _unstakingFeeRate = __unstakingFeeRate;

        emit SetUnstakingFeeRate(__unstakingFeeRate);
    }

    function setLockupTime(uint256 lockupTime) external onlyOwner {
        
        require(lockupTime > 0, "Can't be zero");
        
        _lockupPeriod = lockupTime;
    }

    function setThreeMonthMinAmount(uint256 _minAmount) external onlyOwner {
        
        require (_minAmount > 0, "Can't be zero");

        _minStakeAmount_m = _minAmount;
    }
    
    function setCopperMinAmount(uint256 _minAmount) external onlyOwner {

        require (_minAmount > 0, "Can't be zero");

        _minStakeAmount_c = _minAmount;
    }

    function setSilverMinAmount(uint256 _minAmount) external onlyOwner {

        require (_minAmount > 0, "Can't be zero");

        _minStakeAmount_s = _minAmount;
    }

    function setGoldMinAmount(uint256 _minAmount) external onlyOwner {

        require (_minAmount > 0, "Can't be zero");
        
        _minStakeAmount_g = _minAmount;
    }
    
    // Get reward of msg.sender
    function harvest() public{
        
        updateReward();
        
        uint256 curReward = _staker[msg.sender].stakerCurrentReward;

        if (curReward >= token.balanceOf(address(this)))
            curReward = token.balanceOf(address(this));

        uint256 rewardToClaim = curReward.sub(curReward.mul(_rewardFeeRate).div(1e4));
        
        require(rewardToClaim > 0, "Nothing to claim");
        if (rewardToClaim > token.balanceOf(address(this)))
            rewardToClaim = token.balanceOf(address(this));
        token.safeTransfer(msg.sender, rewardToClaim);
        token.safeTransfer(owner(), curReward.sub(rewardToClaim));
        _staker[msg.sender].stakerCurrentReward = 0;
        
        emit Harvest(msg.sender, rewardToClaim);
    }
    
    function getMinimumStakingAmount(uint256 _mode) public view returns (uint256) {
        
        uint256 _minStakeAmount = 0;

        if (_mode == 0 || _mode == 2) _minStakeAmount = _minStakeAmount_m;
        else if (_mode == 1) _minStakeAmount = _minStakeAmount_c;
        else if (_mode == 3) _minStakeAmount = _minStakeAmount_g;
        else require (0 > 1, "Invalid Mode");

        return _minStakeAmount;
    }
}
