pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./PcapToken.sol";

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IMasterChef {
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. INC to distribute per second.
        uint256 lastRewardTime;  // Last time that INC distribution occurs.
        uint256 accIncPerShare; // Accumulated INC per share, times 1e12. See below.
    }
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function userInfo(uint256 _pid, address _user) external view returns (UserInfo memory);
    function poolInfo(uint256 _pid) external view returns (PoolInfo memory);
}

interface IZapper {
    function swapAndLiquifyToken(address _token, uint _amount, uint _minAmountOut) external;
}

// MasterChef is the master of PCAP. He can make PCAP and he is a fair guy.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterChef is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of PCAP
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accPCAPPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accPCAPPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }
    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. PCAP to distribute per block.
        uint256 lastRewardBlock; // Last block number that PCAP distribution occurs.
        uint256 accPCAPPerShare; // Accumulated PCAP per share, times 1e12. See below.
        uint256 taxFee; // The fee to deposit and withdraw on this pool.
        uint256 taxes; // Amount of taxes available to withdraw.
        uint256 plsxPID; // PID of the plsx masterchef for that same LP
        bool pcapPair; // If it is a pcap pair
    }
    // The PCAP TOKEN!
    PcapToken public immutable PCAP;
    //Pools, Farms, Dev percent decimals
    uint256 public immutable percentDec = 1000000;
    //Pools and Farms percent from token per block
    uint256 public immutable stakingPercent;
    //Developers percent from token per block
    uint256 public immutable devPercent;
    // Dev address.
    address public devaddr;
    // Last block that developer withdrew dev fee
    uint256 public lastBlockDevWithdraw;
    // PCAP tokens created per block.
    uint256 public PcapPerBlock;
    // Bonus muliplier for early PCAP makers.
    uint256 public BONUS_MULTIPLIER = 1;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;
    // The block number when PCAP mining starts.
    uint256 public immutable startBlock;
    // Mapping of farms already added
    mapping(address => bool) private addedFarms;
    // Minimum amount of INC needed for the rehyph function to run. Default is 0.
    uint256 public minRehyphAmount;
    // WPLS address
    address public immutable wpls;
    // DAI address
    address public immutable dai;

    IMasterChef public masterchef;
    IZapper public zapper;
    address public inc;
    address public stockToken;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event minRehyphAmountUpdated (
        uint256 minRehyphAmount
    );
    
    modifier rehyph() {
        _;
        uint _totalInc = IERC20(inc).balanceOf(address(this));
        IERC20(inc).approve(address(zapper), _totalInc);
        if(_totalInc > minRehyphAmount) {
            zapper.swapAndLiquifyToken(inc, _totalInc, 0);
            uint256 _totalStock = IERC20(stockToken).balanceOf(address(this));
            IERC20(stockToken).safeTransfer(devaddr, _totalStock);
        }
    }

    constructor(
        address initialOwner,
        PcapToken _PCAP,
        address _devaddr,
        uint256 _PcapPerBlock,
        uint256 _startBlock,
        address _zapper,
        address _stockToken
    ) Ownable(initialOwner) {
        PCAP = _PCAP;
        devaddr = _devaddr;
        PcapPerBlock = _PcapPerBlock;
        startBlock = _startBlock;
        devPercent = 500000;
        stakingPercent = 950000;
        lastBlockDevWithdraw = _startBlock;
        masterchef = IMasterChef(0xB2Ca4A66d3e57a5a9A12043B6bAD28249fE302d4);
        inc = 0x2fa878Ab3F87CC1C9737Fc071108F904c0B0C95d;
        wpls = 0xA1077a294dDE1B09bB078844df40758a5D0f9a27;
        dai = 0xefD766cCb38EaF1dfd701853BFCe31359239F305;
        zapper = IZapper(_zapper);
        stockToken = _stockToken;
    }

    function updateMultiplier(uint256 multiplierNumber) external onlyOwner {
        BONUS_MULTIPLIER = multiplierNumber;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function withdrawDevFee() external {
        require(lastBlockDevWithdraw < block.number, 'wait for new block');
        uint256 multiplier = getMultiplier(lastBlockDevWithdraw, block.number);
        uint256 PcapReward = multiplier.mul(PcapPerBlock);
        PCAP.mint(devaddr, PcapReward.mul(devPercent).div(percentDec));
        lastBlockDevWithdraw = block.number;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add( uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate, uint256 _taxFee, uint256 _plsxPID, bool _pcapPair ) external onlyOwner {
        require(addedFarms[address(_lpToken)] == false, "lp already added.");
        require(_taxFee <= 100000, "taxFee is higher than 10%");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        
        if(_pcapPair == false) {
            require(masterchef.poolInfo(_plsxPID).lpToken == _lpToken, "Invalid lpToken or pid");
        }

        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accPCAPPerShare: 0,
                taxFee: _taxFee,
                taxes: 0,
                plsxPID: _plsxPID,
                pcapPair: _pcapPair
            })
        );
        addedFarms[address(_lpToken)] = true;
    }

    // Update the given pool's PCAP allocation point. Can only be called by the owner.
    function set( uint256 _pid, uint256 _allocPoint, bool _withUpdate) external onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Update the given pool's taxFee. Can only be called by the owner.
    function setTaxFee( uint256 _pid, uint256 _taxFee, bool _withUpdate) public onlyOwner {
        require(_taxFee <= 100000, "taxFee is higher than 10%");
        if (_withUpdate) {
            massUpdatePools();
        }
        poolInfo[_pid].taxFee =_taxFee;
    }


    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
         return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending PCAP on frontend.
    function pendingPcap(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accPCAPPerShare = pool.accPCAPPerShare;
        uint256 lpSupply;
        if(pool.pcapPair == false) {
            lpSupply = masterchef.userInfo(pool.plsxPID, address(this)).amount;
        } else {
            lpSupply = pool.lpToken.balanceOf(address(this));
        }
        if (block.number > pool.lastRewardBlock) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 PcapReward = multiplier.mul(PcapPerBlock).mul(pool.allocPoint).div(totalAllocPoint).mul(stakingPercent).div(percentDec);
            accPCAPPerShare = accPCAPPerShare.add(PcapReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accPCAPPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward variables for all pools. Be careful of gas spending!
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
        uint256 lpSupply;
        if(pool.pcapPair == false) {
            lpSupply = masterchef.userInfo(pool.plsxPID, address(this)).amount;
        } else {
            lpSupply = pool.lpToken.balanceOf(address(this));
        }
        if (lpSupply <= 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 PcapReward = multiplier.mul(PcapPerBlock).mul(pool.allocPoint).mul(stakingPercent).div(totalAllocPoint).div(percentDec);
        PCAP.mint(address(this), PcapReward);
        pool.accPCAPPerShare = pool.accPCAPPerShare.add(PcapReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for PCAP allocation.
    function deposit(uint256 _pid, uint256 _amount) external rehyph {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accPCAPPerShare).div(1e12).sub(user.rewardDebt);
            safePcapTransfer(msg.sender, pending);
        }
        pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
       
        uint256 _farmFee = _amount.mul(pool.taxFee).div(percentDec);
        uint256 _taxedAmount = _amount.sub(_farmFee);
        pool.taxes = pool.taxes.add(_farmFee);
        //if its not a pcap pair then it is a pulsex pair
        if(pool.pcapPair == false) {
            //approve _taxedAmount
            pool.lpToken.approve(address(masterchef), _taxedAmount);
            //deposit _taxedAmount
            masterchef.deposit(pool.plsxPID, _taxedAmount);
        }
        user.amount = user.amount.add(_taxedAmount);
        user.rewardDebt = user.amount.mul(pool.accPCAPPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _taxedAmount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) external rehyph {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accPCAPPerShare).div(1e12).sub(user.rewardDebt);
        safePcapTransfer(msg.sender, pending);
        
        if(pool.pcapPair == false) {
            masterchef.withdraw(pool.plsxPID, _amount);
        }
        
        user.amount = user.amount.sub(_amount);

        uint256 _farmFee = _amount.mul(pool.taxFee).div(percentDec);
        uint256 _taxedAmount = _amount.sub(_farmFee);
        pool.taxes = pool.taxes.add(_farmFee);

        user.rewardDebt = user.amount.mul(pool.accPCAPPerShare).div(1e12);
        pool.lpToken.safeTransfer(address(msg.sender), _taxedAmount);
        emit Withdraw(msg.sender, _pid, _amount);
    }


    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        if(pool.pcapPair == false) {
            masterchef.withdraw(pool.plsxPID, user.amount);
        }
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Safe PCAP transfer function, just in case if rounding error causes pool to not have enough PCAP.
    function safePcapTransfer(address _to, uint256 _amount) internal {
        uint256 PcapBal = PCAP.balanceOf(address(this));
        if (_amount > PcapBal) {
            IERC20(address(PCAP)).safeTransfer(_to, PcapBal);
        } else {
            IERC20(address(PCAP)).safeTransfer(_to, _amount);
        }
    }

    function setDevAddress(address _devaddr) public onlyOwner {
        require(_devaddr != address(0), "Invalid address");
        devaddr = _devaddr;
    }

    function updatePcapPerBlock(uint256 newAmount) public onlyOwner {
        require(newAmount >= 1 * 1e18, 'Min per block 1 PCAP');
        PcapPerBlock = newAmount;
    }

    // sends taxes collected from a single pool to the dev address
    function withdrawTaxes(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        uint256 _taxes = pool.taxes;
        if(_taxes > 0) {
            pool.taxes = 0;
            pool.lpToken.safeTransfer(devaddr, _taxes);
        } 
    }

    // sends taxes collected from all pools to the dev address
    function withdrawAllTaxes() external {
        for(uint256 i = 0; i < poolInfo.length; i++) {
            withdrawTaxes(i);
        }
    }
    /**
     * @dev Updates the minimum amount of inc 
     * required for the rehyph modifier to run.
     * This can help users save gas by preventing
     * the function to run when it doesn't need to.
     * The amount must be less than 10 INC.
     */
    function updateMinRehyphAmount(uint256 _minRehyphAmount) external onlyOwner {
        require(_minRehyphAmount <= 10 ether, "Amount must be less than 10 INC");
        minRehyphAmount = _minRehyphAmount;
        emit minRehyphAmountUpdated(_minRehyphAmount);
    }

    /**
     * @dev During the conversion of INC to wpls-dai LP on 
     * the rehyph function, small amounts of dai and wpls
     * might be left over. Which over time can acumulate.
     * This function allows the owner to withdraw them.
     */
    function claimLeftOvers() external onlyOwner {
        //Send WPLS leftovers
        IERC20(wpls).safeTransfer(devaddr, IERC20(wpls).balanceOf(address(this)));
        //Send DAI leftovers
        IERC20(dai).safeTransfer(devaddr, IERC20(dai).balanceOf(address(this)));
    }
}
