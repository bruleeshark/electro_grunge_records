// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract ElectroGrungeSeedSale {
    address public owner;
    IERC20 public egptToken;     // 💾 Token
    IERC20 public paymentToken;  // crvUSD or USDC

    uint256 public tokenPriceInPayment; // e.g., 100 * 1e18 crvUSD per 1 💾
    uint256 public totalTokensSold;
    uint256 public maxTokensForSale = 10 * 1e18; // 10.0 💾 allocated to Seed/Advisors

    event TokensPurchased(address indexed buyer, uint256 amountPayment, uint256 amountTokens);

    constructor(address _token, address _paymentToken, uint256 _price) {
        owner = msg.sender;
        egptToken = IERC20(_token);
        paymentToken = IERC20(_paymentToken);
        tokenPriceInPayment = _price;
    }

    function buyTokens(uint256 paymentAmount) external {
        require(paymentAmount > 0, "Amount must be > 0");
        uint256 tokenAmount = (paymentAmount * 1e18) / tokenPriceInPayment;
        require(totalTokensSold + tokenAmount <= maxTokensForSale, "Exceeds seed cap");

        totalTokensSold += tokenAmount;
        
        // Transfer payment to treasury/owner
        require(paymentToken.transferFrom(msg.sender, owner, paymentAmount), "Payment transfer failed");
        // Transfer 💾 tokens to buyer
        require(egptToken.transfer(msg.sender, tokenAmount), "Token transfer failed");

        emit TokensPurchased(msg.sender, paymentAmount, tokenAmount);
    }
}
