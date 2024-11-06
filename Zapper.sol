pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// IPulsexRouter01
interface IPulsexRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// IPulsexRouter02
interface IPulsexRouter02 is IPulsexRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
// IUniswapV2Pair
interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}
// WPLS
interface WPLS {
    function deposit() external payable;
    function withdraw(uint wad) external;
}
// STOCK
interface STOCK {
    function mint(address _to, uint _amount) external;
    function burnUnlocked(address _burnFrom, uint256 _amount) external;
}

// Zapper
contract Zapper is Ownable{
    using SafeERC20 for IERC20;

    // Path to convert a specific token to dai and pls
    struct Token {
        address [] pathA;
        address [] pathB;
    }
    // token A of the DAI-WPLS LP pair
    address public immutable tokenA;
    // token B of the DAI-WPLS LP pair
    address public immutable tokenB;
    // DAI-WPLS pair
    address public immutable pair;
    // WPLS address
    address public immutable wpls;
    // STOCK token address
    STOCK public immutable stockToken;
    // pulsex router contract
    IPulsexRouter02 public immutable pulsexV2Router; 

    // Mapping of token routes to convert to dai-pls
    mapping (address => Token) private tokens;
    

    constructor (
        address _stockToken,
        address initialOwner
    ) Ownable(initialOwner) {
        //0x98bf93ebf5c380C0e6Ae8e192A7e2AE08edAcc02 for pulsex v2
        pulsexV2Router = IPulsexRouter02(0x98bf93ebf5c380C0e6Ae8e192A7e2AE08edAcc02);
        IUniswapV2Pair _pair = IUniswapV2Pair(0xE56043671df55dE5CDf8459710433C10324DE0aE);
        wpls = 0xA1077a294dDE1B09bB078844df40758a5D0f9a27;
        tokenA = _pair.token0();
        tokenB = _pair.token1();
        pair = 0xE56043671df55dE5CDf8459710433C10324DE0aE;
        addToken(tokenA);
        addToken(tokenB);
        addToken(0x02DcdD04e3F455D838cd1249292C58f3B79e3C3C); // weth
        addToken(0x95B303987A60C71504D99Aa1b13B4DA07b0790ab); // plsx
        addToken(0x2fa878Ab3F87CC1C9737Fc071108F904c0B0C95d); // inc
        addToken(0x0Cb6F5a34ad42ec934882A05265A7d5F59b51A2f); // usdt
        addToken(0x15D38573d2feeb82e7ad5187aB8c1D52810B1f07); // usdc
        stockToken = STOCK(_stockToken);
    }
    
    receive() external payable {}

    // swaps and then adds the liquidity
    function swapAndLiquifyETH(uint _minAmountOut) external payable {
        uint _amount = msg.value;
        WPLS(wpls).deposit{value: _amount}();
        uint half = _amount/2;
        
        if(tokenA != wpls) {
            swapForOutputToken(wpls, tokenA, half);
        }

        if(tokenB != wpls) {
            swapForOutputToken(wpls, tokenB, half);
        }
        
        uint _balanceBefore = IERC20(pair).balanceOf(address(this));
        addLiquidity();
        uint _balanceAfter = IERC20(pair).balanceOf(address(this));

        uint tokenAAmount = IERC20(tokenA).balanceOf(address(this));
        uint tokenBAmount = IERC20(tokenB).balanceOf(address(this));
        uint pairAmount = _balanceAfter - _balanceBefore;
        
        require(pairAmount >= _minAmountOut, "Insufficient amount out");

        IERC20(tokenA).safeTransfer(msg.sender, tokenAAmount);
        IERC20(tokenB).safeTransfer(msg.sender, tokenBAmount);
        IERC20(pair).approve(address(stockToken), _balanceBefore);
        stockToken.mint(msg.sender, pairAmount);
    }

    // swaps and then adds the liquidity
    function swapAndLiquifyToken(address _token, uint _amount, uint _minAmountOut) external {
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        uint half = _amount/2;
        
        if(tokenA != _token) {
            swapForOutputToken(_token, tokenA, half);
        }

        if(tokenB != _token) {
            swapForOutputToken(_token, tokenB, half);
        }

        uint _balanceBefore = IERC20(pair).balanceOf(address(this));
        addLiquidity();
        uint _balanceAfter = IERC20(pair).balanceOf(address(this));
       
        uint tokenAAmount = IERC20(tokenA).balanceOf(address(this));
        uint tokenBAmount = IERC20(tokenB).balanceOf(address(this));
        uint pairAmount = _balanceAfter - _balanceBefore;
        
        require(pairAmount >= _minAmountOut, "Insufficient amount out");

        IERC20(tokenA).safeTransfer(msg.sender, tokenAAmount);
        IERC20(tokenB).safeTransfer(msg.sender, tokenBAmount);
        IERC20(pair).approve(address(stockToken), _balanceBefore);
        stockToken.mint(msg.sender, pairAmount);
    }
    
    // swaps and then adds the liquidity
    function swapAndLiquifyETHOther(address _otherPair, uint _minAmountOut) external payable {
        IUniswapV2Pair _pair = IUniswapV2Pair(_otherPair);
        address otherTokenA = _pair.token0();
        address otherTokenB = _pair.token1();

        uint _amount = msg.value;
        WPLS(wpls).deposit{value: _amount}();
        uint half = _amount/2;
        
        if(otherTokenA != wpls) {
            swapForOutputTokenOther(wpls, otherTokenA, half);
        }

        if(otherTokenB != wpls) {
            swapForOutputTokenOther(wpls, otherTokenB, half);
        }

        addLiquidityOther(otherTokenA, otherTokenB);

        uint tokenAAmount = IERC20(otherTokenA).balanceOf(address(this));
        uint tokenBAmount = IERC20(otherTokenB).balanceOf(address(this));
        uint pairAmount = IERC20(_otherPair).balanceOf(address(this));

        require(pairAmount >= _minAmountOut, "Insufficient amount out");

        IERC20(otherTokenA).safeTransfer(msg.sender, tokenAAmount);
        IERC20(otherTokenB).safeTransfer(msg.sender, tokenBAmount);
        IERC20(_otherPair).transfer(msg.sender, pairAmount);
        
    }

    // swaps and then adds the liquidity
    function swapAndLiquifyTokenOther(address _token, uint _amount, address _otherPair, uint _minAmountOut) external {
        IUniswapV2Pair _pair = IUniswapV2Pair(_otherPair);  
        address otherTokenA = _pair.token0();
        address otherTokenB = _pair.token1();

        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        uint half = _amount/2;
        
        if(otherTokenA != _token) {
            swapForOutputTokenOther(_token, otherTokenA, half);
        }

        if(otherTokenB != _token) {
            swapForOutputTokenOther(_token, otherTokenB, half);
        }

        addLiquidityOther(otherTokenA, otherTokenB);

        uint tokenAAmount = IERC20(otherTokenA).balanceOf(address(this));
        uint tokenBAmount = IERC20(otherTokenB).balanceOf(address(this));
        uint pairAmount = IERC20(_otherPair).balanceOf(address(this));

        require(pairAmount >= _minAmountOut, "Insufficient amount out");

        IERC20(otherTokenA).safeTransfer(msg.sender, tokenAAmount);
        IERC20(otherTokenB).safeTransfer(msg.sender, tokenBAmount);
        IERC20(_otherPair).transfer(msg.sender, pairAmount);
    }

    // swaps the reward token for tokenA or tokenB
    function swapForOutputToken(address _token, address _tokenToReceive, uint _amount) internal {
       
        IERC20(_token).approve(address(pulsexV2Router), _amount);

        pulsexV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amount,
            0,
            _tokenToReceive == tokenA ? tokens[_token].pathA : tokens[_token].pathB,
            address(this),
            block.timestamp
        );
    }

   // swaps the reward token for tokenA or tokenB
    function swapForOutputTokenOther(address _token, address _tokenToReceive, uint _amount) internal {
        IERC20(_token).approve(address(pulsexV2Router), _amount);
        if(_tokenToReceive != wpls && _token != wpls) {
                address[] memory _path = new address[](3);
                _path[0] = _token;
                _path[1] = wpls;
                _path[2] = _tokenToReceive;
                pulsexV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    _amount,
                    0,
                    _path,
                    address(this),
                    block.timestamp
                );
            } else {
                address[] memory _path = new address[](2);
                _path[0] = _token;
                _path[1] = _tokenToReceive;
                pulsexV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    _amount,
                    0,
                    _path,
                    address(this),
                    block.timestamp
                );
            }
    }
    
    // adds the liquidity
    function addLiquidity() internal  {
        uint tokenAAmount = IERC20(tokenA).balanceOf(address(this));
        uint tokenBAmount = IERC20(tokenB).balanceOf(address(this));

        // approve token transfer to cover all possible scenarios
        IERC20(tokenA).approve(address(pulsexV2Router), tokenAAmount);
        IERC20(tokenB).approve(address(pulsexV2Router), tokenBAmount);

        // add liquidity and get the LP tokens to the contract itself
        pulsexV2Router.addLiquidity(
            address(tokenA),
            address(tokenB),
            tokenAAmount,
            tokenBAmount,
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    // adds the liquidity
    function addLiquidityOther(address _otherTokenA, address _otherTokenB) internal  {
        uint tokenAAmount = IERC20(_otherTokenA).balanceOf(address(this));
        uint tokenBAmount = IERC20(_otherTokenB).balanceOf(address(this));

        // approve token transfer to cover all possible scenarios
        IERC20(_otherTokenA).approve(address(pulsexV2Router), tokenAAmount);
        IERC20(_otherTokenB).approve(address(pulsexV2Router), tokenBAmount);

        // add liquidity and get the LP tokens to the contract itself
        pulsexV2Router.addLiquidity(
            address(_otherTokenA),
            address(_otherTokenB),
            tokenAAmount,
            tokenBAmount,
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    function swapStockToTokens(uint _amount, address _tokenToReceive, uint _minAmountOut) external {
        stockToken.burnUnlocked(msg.sender, _amount);
        uint _amountRedeemed = IERC20(pair).balanceOf(address(this));
        removeLiquidity(_amountRedeemed,  _tokenToReceive);
        
        uint tokenAAmount = IERC20(tokenA).balanceOf(address(this));
        uint tokenBAmount = IERC20(tokenB).balanceOf(address(this));
        uint tokenToReceiveAmount = IERC20(_tokenToReceive).balanceOf(address(this));

        require(tokenToReceiveAmount >= _minAmountOut, "Insufficient amount out");

        IERC20(_tokenToReceive).transfer(msg.sender, tokenToReceiveAmount);
        IERC20(tokenA).transfer(msg.sender, tokenAAmount);
        if(_tokenToReceive != tokenB) IERC20(tokenB).transfer(msg.sender, tokenBAmount);

    }

    function swapStockToETH(uint _amount, uint _minAmountOut) external {
        stockToken.burnUnlocked(msg.sender, _amount);
        uint _amountRedeemed = IERC20(pair).balanceOf(address(this));
        removeLiquidity(_amountRedeemed,  wpls);
        
        uint tokenBAmount = IERC20(tokenB).balanceOf(address(this));

        uint _wplsAmount = IERC20(wpls).balanceOf(address(this));

        require(_wplsAmount >= _minAmountOut, "Insufficient amount out");
        
        WPLS(wpls).withdraw(IERC20(wpls).balanceOf(address(this)));

        payable(msg.sender).transfer(address(this).balance);

        IERC20(tokenB).transfer(msg.sender, tokenBAmount);
    }
    
    function removeLiquidity(uint _amount, address _tokenToReceive) internal  {
        IERC20(pair).approve(address(pulsexV2Router), _amount);
        pulsexV2Router.removeLiquidity(
            address(tokenA),
            address(tokenB),
            _amount,
            0,
            0,
            address(this),
            block.timestamp
        );
        
        if(tokenA != _tokenToReceive){
            uint tokenAAmount = IERC20(tokenA).balanceOf(address(this));
            IERC20(tokenA).approve(address(pulsexV2Router), tokenAAmount);
            address[] memory _path = new address[](2);
            _path[0] = tokenA;
            _path[1] = _tokenToReceive;
            pulsexV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                tokenAAmount,
                0,
                _path,
                address(this),
                block.timestamp
            );
        }

        if(tokenB != _tokenToReceive){  
            uint tokenBAmount = IERC20(tokenB).balanceOf(address(this));
            IERC20(tokenB).approve(address(pulsexV2Router), tokenBAmount);
            if(_tokenToReceive != wpls) {
                address[] memory _path = new address[](3);
                _path[0] = tokenB;
                _path[1] = wpls;
                _path[2] = _tokenToReceive;
                pulsexV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    tokenBAmount,
                    0,
                    _path,
                    address(this),
                    block.timestamp
                );
            } else {
                address[] memory _path = new address[](2);
                _path[0] = tokenB;
                _path[1] = _tokenToReceive;
                pulsexV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    tokenBAmount,
                    0,
                    _path,
                    address(this),
                    block.timestamp
                );
            }
        }
    } 

    function addToken(address _token) public onlyOwner {
        require(tokens[_token].pathA.length == 0, "Token already added");
        
        tokens[_token].pathA = [_token, tokenA];

        if(_token != wpls) tokens[_token].pathB = [_token, wpls, tokenB];
        else tokens[_token].pathB = [_token, tokenB];
    }

    function updatePathA(address _token, address [] calldata _pathA) external onlyOwner {
        require(tokens[_token].pathA.length > 0, "Token not found, add the token first");
        tokens[_token].pathA = _pathA;
    }

    function updatePathB(address _token, address [] calldata _pathB) external onlyOwner {
        require(tokens[_token].pathA.length > 0, "Token not found, add the token first");
        tokens[_token].pathB = _pathB;
    }

}