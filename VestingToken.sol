// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VestingToken {
    string public name = "VestingToken";
    string public symbol = "VEST";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1000000 * 10**uint256(decimals);
    address public admin;

    mapping(address => uint256) public balanceOf;
    mapping(address => VestingSchedule) public vestingSchedules;

    struct VestingSchedule {
        uint256 totalAmount;
        uint256 releasedAmount;
        uint256 releaseInterval;
        uint256 nextReleaseTime;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event VestingScheduleSet(address indexed beneficiary, uint256 totalAmount, uint256 releaseInterval, uint256 startTime);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not an admin");
        _;
    }

    constructor() {
        admin = msg.sender;
        balanceOf[admin] = totalSupply;
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function setVestingSchedule(
        address _beneficiary,
        uint256 _totalAmount,
        uint256 _releaseInterval,
        uint256 _startTime
    ) external onlyAdmin {
        require(balanceOf[admin] >= _totalAmount, "Insufficient tokens for vesting");
        vestingSchedules[_beneficiary] = VestingSchedule({
            totalAmount: _totalAmount,
            releasedAmount: 0,
            releaseInterval: _releaseInterval,
            nextReleaseTime: _startTime
        });
        balanceOf[admin] -= _totalAmount;
        balanceOf[address(this)] += _totalAmount;
        emit VestingScheduleSet(_beneficiary, _totalAmount, _releaseInterval, _startTime);
    }

    function claimVestedTokens() public {
        VestingSchedule storage schedule = vestingSchedules[msg.sender];
        require(schedule.totalAmount > 0, "No vesting schedule");
        require(block.timestamp >= schedule.nextReleaseTime, "Too early to claim");

        uint256 releasable = ((block.timestamp - schedule.nextReleaseTime + schedule.releaseInterval) / schedule.releaseInterval)
            * (schedule.totalAmount / (365 days / schedule.releaseInterval)); // Example calculation
        releasable = releasable > schedule.totalAmount - schedule.releasedAmount
            ? schedule.totalAmount - schedule.releasedAmount
            : releasable;

        require(releasable > 0, "No tokens to release");
        schedule.releasedAmount += releasable;
        schedule.nextReleaseTime += schedule.releaseInterval;

        balanceOf[address(this)] -= releasable;
        balanceOf[msg.sender] += releasable;
        emit Transfer(address(this), msg.sender, releasable);
    }
}
