/**
 *Submitted for verification at ftmscan.com on 2022-01-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MasterChefUpgradeable is 
    Initializable, 
    UUPSUpgradeable, 
    OwnableUpgradeable, 
    ReentrancyGuardUpgradeable,
    PausableUpgradeable 
{
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of Tokens
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accTokenPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accTokenPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }
    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. Tokens to distribute per block.
        uint256 lastRewardBlock; // Last block number that Tokens distribution occurs.
        uint256 accTokenPerShare; // Accumulated Tokens per share, times 1e12. See below.
    }
    // The Token TOKEN!
    Token public rewardsToken;
    // Dev address.
    address public devaddr;
    // Ecosystem funds address.
    address public ecosystemaddr;
    // Token tokens created per block.
    uint256 public rewardsPerBlock;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when Token mining starts.
    uint256 public startBlock;
    uint256 public endBlock;
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    // Add immutable addresses
    address public immutable tokenAddress;
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        IERC20 _rewardsToken,
        address _devaddr,
        address _ecosystemaddr,
        uint256 _rewardsPerBlock,
        uint256 _startBlock,
        uint256 _endBlock
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        rewardsToken = _rewardsToken;
        devaddr = _devaddr;
        ecosystemaddr = _ecosystemaddr;
        rewardsPerBlock = _rewardsPerBlock;
        startBlock = _startBlock;
        endBlock = _endBlock;
    }

    // Required by UUPS
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        bool _withUpdate
    ) public onlyOwner {
        require(address(_lpToken) != address(0), "add: lp token cannot be 0 address");
        require(address(_lpToken) != tokenAddress, "add: LP token cannot be reward token");
        
        // Ensure LP token hasn't been added before
        for(uint256 i = 0; i < poolInfo.length; i++) {
            require(address(poolInfo[i].lpToken) != address(_lpToken), 
                "add: LP token already added");
        }
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accTokenPerShare: 0
            })
        );
    }

    // Update the given pool's Token allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOwner {
        require(_pid < poolInfo.length, "set: pool does not exist");
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;
    }


    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        if (_to <= endBlock) {
            return _to.sub(_from);
        } else if (_from >= endBlock) {
            return 0;
        } else {
            return
                endBlock.sub(_from);
        }
    }

    function pendingRewards(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accTokenPerShare = pool.accTokenPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && pool.lastRewardBlock < endBlock && lpSupply != 0) {
            uint256 multiplier =
                getMultiplier(pool.lastRewardBlock, block.number);
            uint256 TokenReward =
                multiplier.mul(rewardsPerBlock).mul(pool.allocPoint).div(
                    totalAllocPoint
                );
            accTokenPerShare = accTokenPerShare.add(
                TokenReward.mul(1e12).div(lpSupply)
            );
        }
        return user.amount.mul(accTokenPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0 || block.number <= startBlock) {
            pool.lastRewardBlock = block.number;
            return;
        }

        // Calculate the actual end block for rewards
        uint256 endRewardBlock = block.number > endBlock ? endBlock : block.number;
        if (pool.lastRewardBlock >= endRewardBlock) {
            return;
        }

        uint256 multiplier = getMultiplier(pool.lastRewardBlock, endRewardBlock);
        if (multiplier == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        uint256 TokenReward = multiplier.mul(rewardsPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        rewardsToken.mint(devaddr, TokenReward.mul(2).div(17));
        rewardsToken.mint(ecosystemaddr, TokenReward.div(17));
        rewardsToken.mint(address(this), TokenReward);
        
        pool.accTokenPerShare = pool.accTokenPerShare.add(TokenReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for Token allocation.
    function deposit(uint256 _pid, uint256 _amount) public nonReentrant {
        require(_pid < poolInfo.length, "deposit: pool does not exist");
        require(_amount > 0, "deposit: amount must be greater than 0");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending =
                user.amount.mul(pool.accTokenPerShare).div(1e12).sub(
                    user.rewardDebt
                );
            safeTokenTransfer(msg.sender, pending);
        }
        pool.lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accTokenPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
        require(_pid < poolInfo.length, "withdraw: pool does not exist");
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending =
            user.amount.mul(pool.accTokenPerShare).div(1e12).sub(
                user.rewardDebt
            );
        safeTokenTransfer(msg.sender, pending);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accTokenPerShare).div(1e12);
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Safe Token transfer function, just in case if rounding error causes pool to not have enough Tokens.
    function safeTokenTransfer(address _to, uint256 _amount) internal {
        uint256 TokenBal = rewardsToken.balanceOf(address(this));
        
        if (_amount > TokenBal) {
            rewardsToken.transfer(_to, TokenBal);
        } else {
            rewardsToken.transfer(_to, _amount);
        }
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }

    // Update ecosystem address
    function setEcosystemAddress(address _newEcosystemAddr) public {
        require(msg.sender == ecosystemaddr, "ecosystem: unauthorized");
        require(_newEcosystemAddr != address(0), "ecosystem: zero address");
        ecosystemaddr = _newEcosystemAddr;
    }

    // Add ability to update rewards per block
    function setRewardsPerBlock(uint256 _newRewardsPerBlock) public onlyOwner {
        require(_newRewardsPerBlock > 0, "rewards per block must be greater than 0");
        rewardsPerBlock = _newRewardsPerBlock;
    }

    // Add ability to extend/update end block
    function setEndBlock(uint256 _newEndBlock) public onlyOwner {
        require(_newEndBlock > block.number, "end block must be in the future");
        require(_newEndBlock > startBlock, "end block must be after start block");
        endBlock = _newEndBlock;
    }

    // Add timelock to critical functions
    uint256 public constant TIMELOCK_DURATION = 24 hours;
    mapping(bytes32 => uint256) public timelock;

    modifier timeLocked(bytes32 _operation) {
        require(timelock[_operation] != 0 && timelock[_operation] <= block.timestamp,
            "timelock: operation must be scheduled");
        delete timelock[_operation];
        _;
    }

    function scheduleOperation(bytes32 _operation) external onlyOwner {
        timelock[_operation] = block.timestamp + TIMELOCK_DURATION;
    }

    // Update setRewardsPerBlock with timelock
    function setRewardsPerBlock(uint256 _newRewardsPerBlock) 
        public 
        onlyOwner 
        timeLocked(keccak256("setRewardsPerBlock"))
    {
        require(_newRewardsPerBlock > 0, "rewards per block must be greater than 0");
        rewardsPerBlock = _newRewardsPerBlock;
    }

    // Update setEndBlock with timelock
    function setEndBlock(uint256 _newEndBlock) 
        public 
        onlyOwner 
        timeLocked(keccak256("setEndBlock"))
    {
        require(_newEndBlock > block.number, "end block must be in the future");
        require(_newEndBlock > startBlock, "end block must be after start block");
        endBlock = _newEndBlock;
    }

    // Add version tracking
    uint256 public version;
    
    function getVersion() public view returns (uint256) {
        return version;
    }

    // Add upgrade events
    event ContractUpgraded(address indexed implementation, uint256 version);
}