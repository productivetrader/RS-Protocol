// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RSDutchAuction is ReentrancyGuard, Ownable {
    IERC20 public immutable rsToken;      // RS token
    IERC20 public immutable paymentToken; // USDC or S token
    
    uint256 public startTime;
    uint256 public endTime;
    uint256 public startPrice;
    uint256 public endPrice;
    uint256 public totalTokens;
    uint256 public remainingTokens;
    
    // Auction parameters
    uint256 public constant AUCTION_DURATION = 7 days;
    uint256 public constant MIN_PURCHASE = 100 * 1e18; // 100 RS minimum
    uint256 public constant MAX_PURCHASE_PERCENT = 10; // 10% of total tokens
    
    mapping(address => uint256) public commitments;
    mapping(address => uint256) public claimed;
    
    bool public finalized;
    uint256 public clearingPrice;
    
    // Tier bonuses for proven holders
    uint256 public constant TIER1_MAX_MULTIPLIER = 200; // 2x for diamond hands
    uint256 public constant TIER1_PRICE_DISCOUNT = 10;  // 10% discount
    uint256 public constant TIER2_MAX_MULTIPLIER = 150; // 1.5x for strategic traders
    uint256 public constant TIER2_PRICE_DISCOUNT = 5;   // 5% discount

    // Track proven believers from migration
    mapping(address => uint8) public holderTier; // 1 for Tier1, 2 for Tier2
    
    // Allow proven holders to register trusted addresses
    mapping(address => address[]) public trustedAddresses;
    mapping(address => bool) public isTrustedAddress;
    uint256 public constant MAX_TRUSTED_ADDRESSES = 2;

    event Committed(address indexed buyer, uint256 amount, uint256 payment);
    event PriceUpdated(uint256 newPrice);
    event AuctionFinalized(uint256 clearingPrice);
    event TokensClaimed(address indexed buyer, uint256 amount);

    constructor(
        address _rsToken,
        address _paymentToken,
        uint256 _startPrice,
        uint256 _endPrice,
        uint256 _totalTokens
    ) {
        rsToken = IERC20(_rsToken);
        paymentToken = IERC20(_paymentToken);
        startPrice = _startPrice;
        endPrice = _endPrice;
        totalTokens = _totalTokens;
        remainingTokens = _totalTokens;
    }

    function startAuction() external onlyOwner {
        require(startTime == 0, "Auction already started");
        startTime = block.timestamp;
        endTime = startTime + AUCTION_DURATION;
    }

    function getCurrentPrice() public view returns (uint256) {
        if (block.timestamp < startTime) return startPrice;
        if (block.timestamp >= endTime) return endPrice;
        
        uint256 elapsed = block.timestamp - startTime;
        uint256 priceDrop = ((startPrice - endPrice) * elapsed) / AUCTION_DURATION;
        return startPrice - priceDrop;
    }

    function commit(uint256 tokenAmount) external nonReentrant {
        require(block.timestamp >= startTime, "Auction not started");
        require(block.timestamp < endTime, "Auction ended");
        
        // Get buyer's effective tier (direct or trusted)
        uint8 buyerTier = holderTier[msg.sender];
        if (!buyerTier && isTrustedAddress[msg.sender]) {
            // Find the original holder who trusted this address
            // and use their tier
            buyerTier = getOriginalHolderTier(msg.sender);
        }

        // Calculate max purchase with tier bonus
        uint256 maxPurchase = (totalTokens * MAX_PURCHASE_PERCENT) / 100;
        if (buyerTier == 1) {
            maxPurchase = (maxPurchase * TIER1_MAX_MULTIPLIER) / 100;
        } else if (buyerTier == 2) {
            maxPurchase = (maxPurchase * TIER2_MAX_MULTIPLIER) / 100;
        }

        require(tokenAmount >= MIN_PURCHASE, "Below minimum purchase");
        require(tokenAmount <= maxPurchase, "Exceeds max purchase");
        
        // Calculate price with tier discount
        uint256 currentPrice = getCurrentPrice();
        if (buyerTier == 1) {
            currentPrice = currentPrice * (100 - TIER1_PRICE_DISCOUNT) / 100;
        } else if (buyerTier == 2) {
            currentPrice = currentPrice * (100 - TIER2_PRICE_DISCOUNT) / 100;
        }
        
        uint256 paymentRequired = (tokenAmount * currentPrice) / 1e18;
        
        // Transfer payment tokens
        require(paymentToken.transferFrom(msg.sender, address(this), paymentRequired), "Payment failed");
        
        commitments[msg.sender] += tokenAmount;
        remainingTokens -= tokenAmount;
        
        emit Committed(msg.sender, tokenAmount, paymentRequired);
    }

    function finalizeAuction() external onlyOwner {
        require(block.timestamp >= endTime, "Auction not ended");
        require(!finalized, "Already finalized");
        
        clearingPrice = getCurrentPrice();
        finalized = true;
        
        emit AuctionFinalized(clearingPrice);
    }

    function claim() external nonReentrant {
        require(finalized, "Auction not finalized");
        
        uint256 entitled = commitments[msg.sender] - claimed[msg.sender];
        require(entitled > 0, "Nothing to claim");
        
        claimed[msg.sender] += entitled;
        require(rsToken.transfer(msg.sender, entitled), "Transfer failed");
        
        emit TokensClaimed(msg.sender, entitled);
    }

    // Emergency functions
    function emergencyPause() external onlyOwner {
        endTime = block.timestamp;
    }

    function emergencyWithdraw() external onlyOwner {
        require(block.timestamp >= endTime + 30 days, "Too early");
        uint256 balance = rsToken.balanceOf(address(this));
        if (balance > 0) {
            rsToken.transfer(owner(), balance);
        }
    }

    // Helper function to get original holder tier
    function getOriginalHolderTier(address trusted) internal view returns (uint8) {
        for (uint8 tier = 1; tier <= 2; tier++) {
            address[] memory holders = getTierHolders(tier);
            for (uint i = 0; i < holders.length; i++) {
                address[] storage trustedList = trustedAddresses[holders[i]];
                for (uint j = 0; j < trustedList.length; j++) {
                    if (trustedList[j] == trusted) {
                        return tier;
                    }
                }
            }
        }
        return 0;
    }

    function registerTrustedAddresses(address[] calldata _trusted) external {
        require(holderTier[msg.sender] > 0, "Not a proven holder");
        require(_trusted.length <= MAX_TRUSTED_ADDRESSES, "Too many addresses");
        
        // Clear previous trusted addresses
        address[] storage current = trustedAddresses[msg.sender];
        for(uint i = 0; i < current.length; i++) {
            isTrustedAddress[current[i]] = false;
        }
        
        // Set new trusted addresses
        delete trustedAddresses[msg.sender];
        for(uint i = 0; i < _trusted.length; i++) {
            require(_trusted[i] != address(0), "Invalid address");
            trustedAddresses[msg.sender].push(_trusted[i]);
            isTrustedAddress[_trusted[i]] = true;
        }
    }
} 