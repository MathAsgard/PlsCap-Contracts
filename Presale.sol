// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract TokenTracking {
    using SafeERC20 for IERC20;
    address public deployer;
    address public tokenAddress;
    address public stock;
    address public pcap;
    bool public endState = false;
    uint256 public totalPoints;
    uint256 public totalStockRaised;
    uint256 public totalPcapRaised;

    uint256 public constant MAX_ID = 19;
    
    mapping(uint256 => uint256) public idTotalAmount; // Tracks total amount brought by each ID
    mapping(address => uint256) public userPoints; // Tracks points for each user
    mapping(address => bool) public userClaimed; // Tracks if a user already claimed

    event DepositMade(address indexed user, uint256 indexed id, uint256 amount);
    event PointsClaimed(address indexed user, uint256 reward1Amount, uint256 reward2Amount);
    event ContractEnded();

    constructor(address _tokenAddress) {
        deployer = msg.sender;
        tokenAddress = _tokenAddress;
    }

    modifier onlyDeployer() {
        require(msg.sender == deployer, "Only deployer can call this function.");
        _;
    }

    modifier notEnded() {
        require(!endState, "Deposits are not allowed after the contract has ended.");
        _;
    }

    // Deposit function for users to transfer tokens and gain points
    function deposit(uint256 _id, uint256 _amount) external notEnded {
        require(_id >= 0 && _id <= MAX_ID, "Invalid ID, must be between 0 and 19.");
        require(_amount > 0, "Amount must be greater than zero.");

        // Transfer the token from the user to the contract
        IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), _amount);

        // Transfer the token from the contract to the deployer
        IERC20(tokenAddress).safeTransfer(deployer, _amount);

        // Update tracking
        idTotalAmount[_id] += _amount;  // Track total amount for this ID
        totalPoints += _amount; // Track total amount deposited to the contract
        
        // Assume 1 point per token deposited        
        userPoints[msg.sender] += _amount; // User gets points based on deposit amount

        emit DepositMade(msg.sender, _id, _amount); // Emit Deposit event
    }

    // Function to end the deposit phase; only deployer can call this
    function end (address _pcap, address _stock) external onlyDeployer {
        require(endState == false, "Already ended");
        pcap = _pcap;
        stock = _stock;
        endState = true;
        totalPcapRaised = IERC20(pcap).balanceOf(address(this));
        totalStockRaised = IERC20(stock).balanceOf(address(this));
        require(totalPcapRaised > 0 && totalStockRaised > 0, "Owner should send the rewards before calling the end function");
        emit ContractEnded(); // Emit End event
    }

    // Function for users to claim their rewards based on points
    function claimPoints() external {
        require(endState, "Rewards can only be claimed after the contract has ended.");
        require(userClaimed[msg.sender] == false, "User already claimed.");
        uint256 points = userPoints[msg.sender];
        require(points > 0, "No points to claim.");

        // Calculate rewards, based on the user share of total points
        uint256 pcapAmount = points * totalPcapRaised / totalPoints;
        uint256 stockAmount = points * totalStockRaised / totalPoints;

        // Track that the user already claimed
        userClaimed[msg.sender] = true;

        // Transfer rewards
        IERC20(pcap).safeTransfer(msg.sender, pcapAmount);
        IERC20(stock).safeTransfer(msg.sender, stockAmount);

        emit PointsClaimed(msg.sender, pcapAmount, stockAmount); // Emit ClaimPoints event
    }

    // View function, returns users rewards. Will return 0 before the presale ends.
    function rewardsToClaim() external view returns (uint256 [2] memory rewards) {
        uint256 points = userPoints[msg.sender];
         // Calculate rewards, based on the user share of total points 
        uint256 pcapAmount = points * totalPcapRaised / totalPoints;
        uint256 stockAmount = points * totalStockRaised / totalPoints;
        rewards = [pcapAmount, stockAmount];
        return rewards;
    }

}

