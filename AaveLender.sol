// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Library for Aave's data types
library DataTypes {
  struct ReserveConfigurationMap {
    uint256 data;
  }

  struct ReserveData {
    ReserveConfigurationMap configuration;
    uint128 liquidityIndex;
    uint128 currentLiquidityRate;
    uint128 variableBorrowIndex;
    uint128 currentVariableBorrowRate;
    uint128 currentStableBorrowRate;
    uint40 lastUpdateTimestamp;
    uint16 id;
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    address interestRateStrategyAddress;
    uint128 accruedToTreasury;
    uint128 unbacked;
    uint128 isolationModeTotalDebt;
  }
}

// AAVE Pool interface
interface IPool {
    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode) external;

    function withdraw(
        address asset,
        uint256 amount,
        address to) external returns (uint256);

    function getReserveData(
        address asset) external view returns (DataTypes.ReserveData memory);
}

// ERC20 interface for interacting with DAI and aDAI tokens
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// Aave Lender contract
contract AaveLender {
    address public immutable AAVE_POOL_ADDRESS = 0x48914C788295b5db23aF2b5F0B3BE775C4eA9440;
    address public immutable STAKED_TOKEN_ADDRESS = 0x7984E363c38b590bB4CA35aEd5133Ef2c6619C40;

    function stake(uint256 amount) public {
        require(amount > 0, "Amount must be greater than 0");

        // 1. Transfer DAI from the user to this contract
        IERC20(STAKED_TOKEN_ADDRESS).transferFrom(msg.sender, address(this), amount);

        // 2. Approve the AAVE pool to spend DAI on behalf of this contract
        IERC20(STAKED_TOKEN_ADDRESS).approve(AAVE_POOL_ADDRESS, amount);

        // 3. Supply DAI to the AAVE pool on behalf of the user
        IPool(AAVE_POOL_ADDRESS).supply(
            STAKED_TOKEN_ADDRESS,
            amount,
            msg.sender,
            0
        );
    }

    function unstake(uint256 amount) public {
        require(amount > 0, "Amount must be greater than 0");

        // 1. Get the aDAI token address
        address aTokenAddress = IPool(AAVE_POOL_ADDRESS).getReserveData(STAKED_TOKEN_ADDRESS).aTokenAddress;

        // 2. Approve the AAVE pool to spend the user's aDAI tokens
        IERC20(aTokenAddress).approve(AAVE_POOL_ADDRESS, amount);

        // 3. Withdraw DAI from AAVE back to the user
        IPool(AAVE_POOL_ADDRESS).withdraw(
            STAKED_TOKEN_ADDRESS,
            amount,
            msg.sender
        );
    }
}
