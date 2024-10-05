pragma solidity =0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PcapToken is ERC20('PulseChainCapital', 'PCAP'), ERC20Burnable, Ownable {
    /* 
        @dev  When a new minter is set, the timestamp is stored. 
        The old minter can only be updated to the new address 
        15 after the newMinter was set. The two minters are
        Farms and heartFarms.
    */
    address public farms;
    address public newFarms;
    address public heartFarms;
    address public newHeartFarms;
    uint256 public farmsUpdatedAt;
    uint256 public heartUpdatedAt;
    uint256 public initialized;

    event contractInitialized (
        address indexed farms,
        address indexed heartFarms
    );
    event newFarmsSet (
        address indexed newFarms
    );
    event newHeartFarmsSet (
        address indexed newHeartFarms
    );
    event farmsMinterUpdated (
        address indexed newFarms
    );
    event heartMinterUpdated (
        address indexed newHeartFarms
    );
    
    constructor(address initialOwner, uint256 _preMintAmount) Ownable(initialOwner) {
        // pre minted supply, used to add liquidity, it is sent to the initialOwner
        _mint(initialOwner, _preMintAmount);
    }

    /**
     * @dev This function sets the two minters (farms and heart farms)
     * it can only be called once. After that if a change is required
     * the owner must use the update functions.
     */
    function initialize(address _farms, address _heartFarms) external  {
        require(initialized == 0, "PCAP: Contract already initialized");
        require(_farms != address(0) && _heartFarms != address(0), "PCAP: Invalid _farms or _heartFarms address");
        initialized = 1;
        farms = _farms;
        heartFarms = _heartFarms;
        emit contractInitialized(_farms, _heartFarms);
    }
    
    /** @dev This function mints `_amount` of PCAP to the address `_to`. 
     * Can only be called by the minters (farms and heartFarms).
     */
    function mint(address _to, uint256 _amount) external {
        require(msg.sender == farms || msg.sender == heartFarms, "PCAP: Permission declined");
        _mint(_to, _amount);
    }

    /**
     * @dev This function is used to change the minter address
     * it stores the new address (newFarms) and the timestamp.
     * The address can only be updated 15 days after,
     * by calling the updateMinterHeart function.
     * Can only be called by the owner.
     */
    function setNewFarms(address _minter) external onlyOwner {
        require(_minter != address(0), "PCAP: _minter is the zero address");
        newFarms = _minter;
        farmsUpdatedAt = block.timestamp;
        emit newFarmsSet(_minter);
    }

    /**
     * @dev This function is used to change the minter address
     * it stores the new address (newHeartFarms) and the timestamp.
     * The address can only be updated 15 days after,
     * by calling the updateMinterHeart function.
     * Can only be called by the owner.
     */
    function setNewHeartFarms(address _minter) external onlyOwner {
        require(_minter != address(0), "PCAP: _minter is the zero address");
        newHeartFarms = _minter;
        heartUpdatedAt = block.timestamp;
        emit newHeartFarmsSet(_minter);
    }

    /**
     * @dev This function updates the current minter(farms) to the new
     * minter(newFarms), newFarms must have been set 15 days before 
     * with the setNewFarms function.
     * Can only be called by the owner.
     */
    function updateMinterFarms() external onlyOwner {
        require(newFarms != address(0), "PCAP: no new minter set");
        require(block.timestamp >= farmsUpdatedAt + 15 days, "PCAP: You can only update the minter 15 days after setting a new one");
        farms = newFarms;
        newFarms = address(0);
        farmsUpdatedAt = 0;
        emit farmsMinterUpdated(newFarms);
    }

    /**
     * @dev This function updates the current minter(heartFarms) to the new
     * minter(newHeartFarms), newFarms must have been set 15 days before 
     * with the setNewFarms function.
     * Can only be called by the owner.
     */
    function updateMinterHeart() external onlyOwner {
        require(newHeartFarms != address(0), "PCAP: no new minter set");
        require(block.timestamp >= heartUpdatedAt + 15 days, "PCAP: You can only update the minter 15 days after setting a new one");
        heartFarms = newHeartFarms;
        newHeartFarms = address(0);
        heartUpdatedAt = 0;
        emit heartMinterUpdated(newHeartFarms);
    }
}
