pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// PLSX masterchef interface
interface IMasterChef {
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }
    struct PoolInfo {
        IERC20 lpToken;
        uint256 allocPoint;
        uint256 lastRewardTime;
        uint256 accIncPerShare; 
    }
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function userInfo(uint256 _pid, address _user) external returns (UserInfo memory);
    function poolInfo(uint256 _pid) external returns (PoolInfo memory);
}

// Zapper interface
interface IZapper {
    function swapAndLiquifyToken(address _token, uint _amount, uint _minAmountOut) external;
}

// StockToken
contract StockToken is ERC20('StockToken', 'STOCK'), ERC20Burnable, Ownable {
    using SafeERC20 for IERC20;

    address public immutable lpReserve; // The lp token that serves as collateral for the stock token
    address public dev; // Dev address that receives the fees
    uint256 public minRehyphAmount; // Minimum amount of INC needed for the rehyph function to run. Default is 0.

    // Structure of a token lock
    struct TokenLock {
        uint256 amount; //Amount of tokens
        uint256 timestamp; //Time the lock ends
        bool claimed; //Already claimed?
    }
    // All token locks of a user
    mapping(address => TokenLock[]) public userLocks;
    // PLSX masterchef
    IMasterChef public immutable masterchef;
    // Zapper address
    IZapper public zapper;
    // INC address
    address public immutable inc;
    // WPLS address
    address public immutable wpls;
    // DAI address
    address public immutable dai;
    // StockPool address
    address public stockPool;

    event tokensLocked (
        address indexed user,
        uint256 amount
    );
    event tokensBurntUnlocked (
        address indexed user,
        uint256 amount
    );
    event tokensBurntLocked (
        address indexed user,
        uint256 amount
    );
    event zapperSet (
        address indexed zapper
    );
    event stockPoolSet (
        address indexed stockPool
    );
    event minRehyphAmountUpdated (
        uint256 minRehyphAmount
    );

     /**
     * @dev This modifier calls the swapAndLiquifyToken function
     * of the zapper contract. This function sells all of the
     * INC for DAI and PLS, adds them as liquidity and mints
     * STOCK token. Which is sent to the StockPool contract.
     */
    modifier rehyph() {
        _;
        uint _totalInc = IERC20(inc).balanceOf(address(this));
        if(_totalInc > minRehyphAmount) {
            IERC20(inc).approve(address(zapper), _totalInc);
            zapper.swapAndLiquifyToken(inc, _totalInc, 0);
            IERC20(address(this)).safeTransfer(stockPool, balanceOf(address(this)));
        }
    }

    constructor(
        address initialOwner,
        address _devAddress
    ) Ownable(initialOwner) {
        require(initialOwner != address(0) && _devAddress != address(0), "Invalid address");
        dev = _devAddress;
        lpReserve = 0xE56043671df55dE5CDf8459710433C10324DE0aE;
        masterchef = IMasterChef(0xB2Ca4A66d3e57a5a9A12043B6bAD28249fE302d4);
        inc = 0x2fa878Ab3F87CC1C9737Fc071108F904c0B0C95d;
        wpls = 0xA1077a294dDE1B09bB078844df40758a5D0f9a27;
        dai = 0xefD766cCb38EaF1dfd701853BFCe31359239F305;
    }
    
    /**
     * @dev This function mints `_amount` of STOCK tokens
     * and sends them to the `_to` address. The caller must
     * send the respective amount of lpTokens (lpReserve) 
     * to the contract.
     */
    function mint(address _to, uint256 _amount) external  rehyph {
        IERC20(lpReserve).safeTransferFrom(msg.sender, address(this), _amount);
        IERC20(lpReserve).approve(address(masterchef), _amount);
        masterchef.deposit(1, _amount);
        _mint(_to, _amount);
    }

    /**
     * @dev This function burns the STOCK tokens and 
     * sends the respective amount of lpTokens (lpReserve)
     * back to the caller. A 5% fee is taken and sent to 
     * to the dev address.
     */
    function burnUnlocked(address _burnFrom, uint256 _amount) external rehyph {
        burnFrom(_burnFrom, _amount);
        masterchef.withdraw(1, _amount);
        uint256 _fee = _amount * 50000 / 1000000;
        uint256 _taxedAmount = _amount - _fee;
        IERC20(lpReserve).transfer(dev, _fee);
        IERC20(lpReserve).transfer(msg.sender, _taxedAmount);
        emit tokensBurntUnlocked(msg.sender, _amount);
    }

    /**
     * @dev This function locks `_amount` of STOCK
     * tokens, for 14 days. After that the user can 
     * burn the with the burnLocked() function
     * without paying the 5% fee.
     */
    function lock(uint256 _amount) external {
        burn(_amount);
        userLocks[msg.sender].push(TokenLock({
            amount: _amount,
            timestamp: block.timestamp + 14 days,
            claimed: false
        }));
        emit tokensLocked(msg.sender, _amount);
    }
    /**
     * @dev This function burns the STOCK tokens, from the _lockID  
     * and sends the respective amount of lpTokens (lpReserve)
     * back to the caller. The tokens must have been locked
     * 14 before.
     */
    function burnLocked(uint256 _lockID) external rehyph {
        require(userLocks[msg.sender][_lockID].timestamp <= block.timestamp, "Tokens still locked");
        require(userLocks[msg.sender][_lockID].claimed == false, "Tokens already claimed");
        userLocks[msg.sender][_lockID].claimed = true;
        uint256 _amount = userLocks[msg.sender][_lockID].amount;
        masterchef.withdraw(1, _amount);
        IERC20(lpReserve).transfer(msg.sender, _amount);
        emit tokensBurntLocked(msg.sender, _amount);
    }

    /**
     * @dev Returns the amount of locks created by a user
     */
    function userLocksLength(address _user) external view returns(uint256) {
       return userLocks[_user].length;
    }

    /**
     * @dev Returns an array with all locks created by a user
     */
    function userLocksArray(address _user) external view returns(TokenLock[] memory) {
       return userLocks[_user];
    }

    /**
     * @dev Sets the zapper address
     */
    function setZapper(address _zapper) external onlyOwner {
        require(_zapper != address(0), "Invalid address");
        zapper = IZapper(_zapper);
        emit zapperSet(_zapper);
    }

    /**
     * @dev Sets the stockPool address
     */
    function setStockPool(address _stockPool) external onlyOwner {
        require(_stockPool != address(0), "Invalid address");
        require(stockPool == address(0), "StockPool is already set");
        stockPool = _stockPool;
        emit stockPoolSet(_stockPool);
    }
    /**
     * @dev Sets the dev address
     */
    function setDevAddress(address _devaddr) public onlyOwner {
        require(_devaddr != address(0), "Invalid address");
        dev = _devaddr;
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
        IERC20(wpls).safeTransfer(dev, IERC20(wpls).balanceOf(address(this)));
        //Send DAI leftovers
        IERC20(dai).safeTransfer(dev, IERC20(dai).balanceOf(address(this)));
    }
}
