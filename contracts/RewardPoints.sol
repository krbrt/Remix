
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IRewardPoints.sol";

contract RewardPoints is
    IRewardPoints,
    Ownable,
    AccessControl,
    Pausable,
    ReentrancyGuard
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // ========== Reward Tiers ==========

    uint8 public constant TIER_BRONZE = 0;
    uint8 public constant TIER_SILVER = 1;
    uint8 public constant TIER_GOLD = 2;
    uint8 public constant TIER_PLATINUM = 3;

    uint256 public constant TIER_SILVER_THRESHOLD = 1_000;
    uint256 public constant TIER_GOLD_THRESHOLD = 10_000;
    uint256 public constant TIER_PLATINUM_THRESHOLD = 100_000;

    // Multipliers use basis points (10000 = 1x)

    uint256 public constant TIER_BRONZE_MULTIPLIER = 10_000;
    uint256 public constant TIER_SILVER_MULTIPLIER = 12_000;
    uint256 public constant TIER_GOLD_MULTIPLIER = 15_000;
    uint256 public constant TIER_PLATINUM_MULTIPLIER = 20_000;

    // ========== State Variables ==========

    uint256 public minRedemption;
    uint256 public multiplier;

    mapping(address => uint256)
        public override totalPointsEarned;

    mapping(address => uint256)
        public override balanceOf;

    mapping(address => uint8) public userTier;

    // ========== Constructor ==========

    constructor() Ownable(msg.sender) {
        minRedemption = 100;
        multiplier = 10_000;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    // ========== Access Control ==========

    modifier onlyMinterOrOwner() {
        require(
            hasRole(MINTER_ROLE, msg.sender) ||
                owner() == msg.sender,
            "RewardPoints: caller must have minter role or be owner"
        );
        _;
    }

    // ========== Tier View Functions ==========

    function getTier(address user)
        external
        view
        override
        returns (uint8)
    {
        return userTier[user];
    }

    function getTierMultiplier(uint8 tier)
        external
        pure
        override
        returns (uint256)
    {
        return _getTierMultiplier(tier);
    }

    function getTierThreshold(uint8 tier)
        external
        pure
        override
        returns (uint256)
    {
        if (tier == TIER_PLATINUM) {
            return TIER_PLATINUM_THRESHOLD;
        }

        if (tier == TIER_GOLD) {
            return TIER_GOLD_THRESHOLD;
        }

        if (tier == TIER_SILVER) {
            return TIER_SILVER_THRESHOLD;
        }

        return 0;
    }

    function getMultiplier()
        external
        view
        override
        returns (uint256)
    {
        return multiplier;
    }

    function getMinRedemption()
        external
        view
        override
        returns (uint256)
    {
        return minRedemption;
    }

    // ========== Internal Tier Functions ==========

    function _getTierFromPoints(uint256 points)
        internal
        pure
        returns (uint8)
    {
        if (points >= TIER_PLATINUM_THRESHOLD) {
            return TIER_PLATINUM;
        }

        if (points >= TIER_GOLD_THRESHOLD) {
            return TIER_GOLD;
        }

        if (points >= TIER_SILVER_THRESHOLD) {
            return TIER_SILVER;
        }

        return TIER_BRONZE;
    }

    function _getTierMultiplier(uint8 tier)
        internal
        pure
        returns (uint256)
    {
        if (tier == TIER_PLATINUM) {
            return TIER_PLATINUM_MULTIPLIER;
        }

        if (tier == TIER_GOLD) {
            return TIER_GOLD_MULTIPLIER;
        }

        if (tier == TIER_SILVER) {
            return TIER_SILVER_MULTIPLIER;
        }

        return TIER_BRONZE_MULTIPLIER;
    }

    // ========== Earning Points ==========

    function earnPoints(address user, uint256 amount)
        external
        override
        whenNotPaused
        onlyMinterOrOwner
    {
        require(
            user != address(0),
            "RewardPoints: invalid user"
        );

        require(
            amount > 0,
            "RewardPoints: amount must be greater than 0"
        );

        uint8 oldTier = userTier[user];

        uint256 tierMult = _getTierMultiplier(oldTier);

        uint256 totalMultiplier =
            (multiplier * tierMult) / 10_000;

        uint256 earnedAmount =
            (amount * totalMultiplier) / 10_000;

        totalPointsEarned[user] += earnedAmount;
        balanceOf[user] += earnedAmount;

        uint8 newTier =
            _getTierFromPoints(totalPointsEarned[user]);

        if (newTier != oldTier) {
            userTier[user] = newTier;

            emit TierChanged(user, oldTier, newTier);
        }

        emit PointsEarned(user, earnedAmount, newTier);
    }

    // ========== Redeeming Points ==========

    function redeemPoints(uint256 amount)
        external
        override
        whenNotPaused
        nonReentrant
    {
        require(
            amount > 0,
            "RewardPoints: amount must be greater than 0"
        );

        require(
            amount >= minRedemption,
            "RewardPoints: amount below minimum redemption"
        );

        require(
            balanceOf[msg.sender] >= amount,
            "RewardPoints: insufficient balance"
        );

        balanceOf[msg.sender] -= amount;

        emit PointsRedeemed(msg.sender, amount);
    }

    // ========== Administrator Functions ==========

    function setMultiplier(uint256 newMultiplier)
        external
        override
        onlyOwner
    {
        require(
            newMultiplier > 0,
            "RewardPoints: multiplier must be greater than 0"
        );

        require(
            newMultiplier <= 100_000,
            "RewardPoints: multiplier too high (max 10x)"
        );

        multiplier = newMultiplier;

        emit MultiplierUpdated(newMultiplier);
    }

    function setMinRedemption(uint256 amount)
        external
        override
        onlyOwner
    {
        require(
            amount > 0,
            "RewardPoints: minimum must be greater than 0"
        );

        minRedemption = amount;
    }

    // ========== Emergency Pause Functions ==========

    function pause()
        external
        override
        onlyOwner
    {
        _pause();
    }

    function unpause()
        external
        override
        onlyOwner
    {
        _unpause();
    }
}
