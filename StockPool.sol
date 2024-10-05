pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


// StockPool
contract StockPool is Ownable {
    using SafeERC20 for IERC20;

    /**
     * @dev This modifier distributes the stockTokens
     * as rewards for all stakers. It does so in a rate of
     * approximately 3% of the dividend pool per day.
     */
    modifier updatePool {
        uint stockBalance = STOCK.balanceOf(address(this));
        uint newTokens = stockBalance - (tokenSupply + dividendPool + pendingDividends);

        if(newTokens > 0) {
            dividendPool += newTokens;
        }

        if (dividendPool > 0 && sharesSupply > 0) {
            uint secondsPassed = block.timestamp - lastDripTime;
            uint dividends = secondsPassed * dividendPool / distRate;
            
            if(dividends > 0) {
                if (dividends > dividendPool) {
                    dividends = dividendPool;
                }

                profitPerShare = profitPerShare + ( (dividends * precision) / sharesSupply);
                dividendPool -= dividends;
                pendingDividends += dividends;
                lastDripTime = block.timestamp;
            }
        }
        _;
    }
    
    /**
     * @dev This modifier ensures the user
     * has dividends
     */
    modifier onlyDivis {
        require(dividendsOf(msg.sender) > 0);
        _;
    }

    event onDonation(
        address indexed customerAddress,
        uint tokens
    );

    event onTokenPurchase(
        address indexed customerAddress,
        uint incomingTokens,
        uint tokensMinted,
        uint timestamp
    );

    event onTokenSell(
        address indexed customerAddress,
        uint tokensBurned,
        uint tokensEarned,
        uint timestamp
    );

    event onReinvest(
        address indexed customerAddress,
        uint tokensRolled,
        uint tokensMinted
    );

    event onWithdraw(
        address indexed customerAddress,
        uint tokensWithdrawn
    );

    // Precision variable
    uint constant private precision = 2 ** 64;

    // Distribution rate
    uint32 constant private distRate = 2880000; //3% a day (86400 -> seconds in a day / 2880000 -> distRate) = 0.03

    // User stats
    struct UserStats {
       uint sharesBalanceLedger;
       int payoutsTo;
       uint stockBalanceLedger;
       uint totalDivsClaimed;
       Stake[] stakes;
    }
    // Stake stats
    struct Stake {
        bool active;
        uint amount;
        uint shares;
        uint timestamp;
        uint duration;
    }
    // Stats of a user
    mapping(address => UserStats) public userStats;
    
    // Dividends not yet distributed
    uint public dividendPool;
    // Last time dividends were distributed
    uint public lastDripTime;
    // Amount of dividends already distributed but not yet withdrawn by users
    uint public pendingDividends;

    // Total amount of stock staked in the contract
    uint public tokenSupply;
    // Total amount of shares
    uint public sharesSupply;
    // Profit per share, used to track rewards
    uint public profitPerShare;
    // Stock token address
    IERC20 public STOCK;

    constructor(address _stockToken, address initialOwner) Ownable(initialOwner) {
        STOCK = IERC20(address(_stockToken));
        lastDripTime = block.timestamp;
    }
    
    /**
     * @dev This function allows users to donate stock to be used as rewards
     **/
    function donateToPool(uint _amount) external  {
        require(_amount > 0 && tokenSupply > 0, "must be a positive value and have supply");
        STOCK.safeTransferFrom(msg.sender, address(this), _amount);
        dividendPool += _amount;
        emit onDonation(msg.sender, _amount);
    }

    /**
     * @dev This function creates a new stake using the pending rewards of a user
     **/
    function reinvest(uint _duration) updatePool onlyDivis external {
        address _customerAddress = msg.sender;
        uint _dividends = dividendsOf(_customerAddress);
        userStats[_customerAddress].payoutsTo +=  (int256) (_dividends * precision);
        createStake(_customerAddress, _dividends, _duration);
        emit onReinvest(_customerAddress, _dividends, _dividends);
    }

    /**
     * @dev This function withdraws the pending rewards of a user
     **/
    function withdraw() updatePool onlyDivis external {
        address _customerAddress = msg.sender;
        uint _dividends = dividendsOf(_customerAddress);
        userStats[_customerAddress].payoutsTo += (int256) (_dividends * precision);
        if(_dividends >= pendingDividends) {
            pendingDividends = 0;
        } else {
            pendingDividends -= _dividends;
        }
        STOCK.transfer(_customerAddress, _dividends);
        userStats[_customerAddress].totalDivsClaimed += _dividends;
        emit onWithdraw(_customerAddress, _dividends);
    }
    /**
     * @dev This function creates a new stake
     **/
    function stake(uint _amount, uint _duration) updatePool external {
        STOCK.safeTransferFrom(msg.sender, address(this), _amount);
        createStake(msg.sender, _amount, _duration);
    }

    function createStake(address _customerAddress, uint _incomingTokens, uint _duration) private {
        require(_incomingTokens > 0, "Stake has to be greter than 0");
        require(_duration >= 1 days && _duration <= 100 days, "Duration has to be between 1 and 100 days" );
        UserStats storage _user  = userStats[_customerAddress];

        uint _stakeBonus = _duration / 1 days * 3;
        uint _shares = _incomingTokens + (_incomingTokens * _stakeBonus / 100);
        
        _user.stakes.push(Stake({
            active: true,
            amount: _incomingTokens,
            shares: _shares,
            timestamp: block.timestamp,
            duration: _duration
        }));

        _user.sharesBalanceLedger += _shares;
        _user.stockBalanceLedger += _incomingTokens;
        tokenSupply += _incomingTokens;
        sharesSupply += _shares;
        
        int256 _updatedPayouts = (int256) (profitPerShare * _shares);
        _user.payoutsTo += _updatedPayouts;

        emit onTokenPurchase(_customerAddress, _incomingTokens, _incomingTokens, block.timestamp);
    }

    /**
     * @dev This allows a user to unstake its token.
     * The stake must have ended.
     **/
    function unstake(uint _stakeId) updatePool external {
        UserStats storage _user  = userStats[msg.sender];
        Stake storage _stake = _user.stakes[_stakeId];
        uint _amountOfTokens = _stake.amount;
        uint _amountOfShares = _stake.shares;
        require(block.timestamp >= _stake.timestamp + _stake.duration, "stake hasn't ended");
        require(_stake.active == true, "stake isn't active");

        _stake.active = false;
        _user.sharesBalanceLedger -= _amountOfShares;
        _user.stockBalanceLedger -= _amountOfTokens;

        int256 _updatedPayouts = (int256) (profitPerShare * _amountOfShares);
        _user.payoutsTo -= _updatedPayouts;

        tokenSupply -= _amountOfTokens;
        sharesSupply -= _amountOfShares;
        STOCK.transfer(msg.sender, _amountOfTokens);
        
        emit onTokenSell(msg.sender, _amountOfTokens, _amountOfShares, block.timestamp);
    }

    /**
     * @dev This function is used to estimate the amount of rewards
     * a user will have after the updatePool modifier runs.
     **/
    function estimateDividendsOf(address _customerAddress, bool _dayEstimate) external view returns (uint) {
        uint _profitPerShare = profitPerShare;

        if (dividendPool > 0) {
          uint secondsPassed = 0;

          if (_dayEstimate == true){
            secondsPassed = 86400;
          } else {
            secondsPassed = block.timestamp - lastDripTime;
          }

          uint dividends = secondsPassed * dividendPool / distRate;

          if (dividends > dividendPool) {
            dividends = dividendPool;
          }

          _profitPerShare = _profitPerShare + ( (dividends * precision) / sharesSupply);
        }

        return (uint) ((int256) (_profitPerShare * userStats[_customerAddress].sharesBalanceLedger) - userStats[_customerAddress].payoutsTo) / precision;
    }

    /**
     * @dev This function returns the pending rewards of a user, 
     * before the updatePool modifier is called
     **/
    function dividendsOf(address _customerAddress) public view returns (uint) {
        return (uint) ((int256) (profitPerShare * userStats[_customerAddress].sharesBalanceLedger) - userStats[_customerAddress].payoutsTo) / precision;
    }

    /**
     * @dev This function returns the amount of shares of a user
     **/
    function balanceOf(address _customerAddress) external view returns (uint) {
        return userStats[_customerAddress].sharesBalanceLedger;
    }

    /**
     * @dev This function returns the total amount of stakes created by a user
     **/
    function userStakesLength(address _customerAddress) external view returns (uint) {
        return userStats[_customerAddress].stakes.length;
    }

    /**
     * @dev This function returns an array with all the stakes created by a user
     **/
    function userStakesArray(address _customerAddress) external view returns (Stake[] memory) {
        return userStats[_customerAddress].stakes;
    }
}