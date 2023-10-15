// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.3;

interface IstakingToken {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function balanceOf(address _owner) external view returns (uint256);

    function transfer(address _to, uint256 _value)
        external
        returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function approve(address _spender, uint256 _value)
        external
        returns (bool success);

    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint256 tokens
    );
}

interface IrewardingToken {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function balanceOf(address _owner) external view returns (uint256);

    function transfer(address _to, uint256 _value)
        external
        returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function approve(address _spender, uint256 _value)
        external
        returns (bool success);

    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint256 tokens
    );
}

contract TokenStakingContract {
    /*============================ EVENTS============================*/
    event Staked(address indexed from, uint256 amount);
    event UnStaked(address indexed to, uint256 amount);
    event Claimed(address indexed from, address indexed to, uint256 amount);
    // lock: Reentrancy Attack
    /*============================ STATE VARIABLES============================*/
    bool private locked;
    address payable public owner;
    // Seprate Wallett to transfer amount 0.5% staking fee, 1.5% unstaking fee
    address separateWallet;
    // StakingToken & RewardToken
    // Address for Staking Token & Rewarding Token
    address StakingTokenAddr;
    address RewardingTokenAddr;

    // Structure to Store Information Related to a User Staking Their thier token
    struct StakeInfo {
        uint256 startTS;
        uint256 amount;
        uint256 claimed;
        // this unClaimedReward is Reward that is added only when a User UnStaked thier Token without Claiming Thier Reward
        uint256 unClaimedReward;
        // bool addressStaked;
    }
    // Mapping to store information related to a User Staking their token
    // Address -> Stake Information
    mapping(address => StakeInfo) stakeInfos;
    // Address -> Staked or Not?
    mapping(address => bool) addressStaked;

    /*============================ Modifiers============================*/
    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Message sender must be the contract's owner."
        );
        _;
    }
    // Checks if a user has allowed this contract to transfer its Tokens?
    modifier TokensApprovedSkating(uint256 amount) {
        require(
            IstakingToken(StakingTokenAddr).allowance(
                msg.sender,
                address(this)
            ) >= amount,
            "Staking Tokens Not Approved by this User/ Insufficient funds"
        );
        _;
    }
    // check if This contract is allowed to transfer Tokens to a user?
    modifier TokensApprovedforReward(uint256 amount) {
        require(
            IrewardingToken(RewardingTokenAddr).allowance(
                owner,
                address(this)
            ) > amount,
            "Reward Tokens Not Approved by this Owner/ Insufficient funds"
        );
        _;
    }

    constructor(
        address _StakingTokenAddress,
        address _RewardingTokenAddress,
        address _separateWallet
    ) {
        require(
            address(_StakingTokenAddress) != address(0) &&
                address(_RewardingTokenAddress) != address(0),
            "Token Address cannot be address 0"
        );
        owner = payable(msg.sender);
        locked = false;
        separateWallet = _separateWallet;
        StakingTokenAddr = _StakingTokenAddress;
        RewardingTokenAddr = _RewardingTokenAddress;
    }

    // Approval of Staking Tokens By user to this Contract
    function approvalOfStakingTokensUser() public view returns (uint256) {
        return
            IstakingToken(StakingTokenAddr).allowance(
                msg.sender,
                address(this)
            );
    }

    // Approval of transfering Rewarding Tokens to this contract for users
    function approvalOfRewardingTokensUser() public view returns (uint256) {
        return
            IrewardingToken(RewardingTokenAddr).allowance(
                msg.sender,
                address(this)
            );
    }

    // To get the StakingToken Balance of a user
    function balanceofStakingTokens_user() public view returns (uint256) {
        return IstakingToken(StakingTokenAddr).balanceOf(msg.sender);
    }

    // To get the RewardingToken Balance of a user
    function balanceofRewardingTokens_user() public view returns (uint256) {
        return IrewardingToken(RewardingTokenAddr).balanceOf(msg.sender);
    }

    function StakeTokens(uint256 stakeAmount) public returns (bool) {
        require(addressStaked[msg.sender] == false, "You already participated");
        require(
            IstakingToken(StakingTokenAddr).balanceOf(msg.sender) >=
                stakeAmount,
            "Insufficient Tokens Balance"
        );

        require(
            stakeAmount >= 0,
            "Stake Amount is too low. Should be Greater Than 0"
        );
        addressStaked[msg.sender] = true;
        // 0.5 STAKING FEE DUDUCTED HERE
        uint256 amountAdded = ((stakeAmount * 1000) - (stakeAmount * 5)) / 1000;

        // Getting The Previous Unclaimed Reward if any.
        uint256 unclaimedRewardtoAdd = stakeInfos[msg.sender].unClaimedReward;

        require(
            IstakingToken(StakingTokenAddr).transferFrom(
                msg.sender,
                address(this),
                stakeAmount
            ),
            "Tokens Not Staked ERROR returned"
        );
        // Staking fee Transfered to a Seperate Wallet
        require(
            IstakingToken(StakingTokenAddr).transfer(
                separateWallet,
                (stakeAmount) - (amountAdded)
            ),
            "STAKING FEE Not Transfered"
        );

        stakeInfos[msg.sender] = StakeInfo({
            startTS: block.timestamp,
            amount: amountAdded,
            claimed: 0,
            unClaimedReward: unclaimedRewardtoAdd
        });

        emit Staked(msg.sender, stakeInfos[msg.sender].amount);
        return true;
    }

    function unStakeTokens() public returns (bool isUnstaked) {
        require(addressStaked[msg.sender] == true, "You have not staked");
        require(
            IrewardingToken(RewardingTokenAddr).allowance(
                owner,
                address(this)
            ) > 0,
            "Reward Tokens Not Availabl Right Now"
        );
        // returning the Claimed Reward
        StakeInfo memory Data = stakeInfos[msg.sender];

        uint256 percentage = 7;

        // FIXME: this is a temp Daypassed , Change for Final
        uint256 dayPassed = 3;
        // Use the above statement in final Deployment
        // dayPassed= (block.timestamp -  Data.startTS)/86400;
        uint256 decimals = 10**(IrewardingToken(RewardingTokenAddr).decimals());
        uint256 point = (dayPassed) * decimals;
        uint256 CurrentRewardCreated = ((((percentage * point) / 10000) *
            Data.amount) / decimals) -
            // Subtract Already claimed Reward
            Data.claimed;

        // Setting unclaimed Reward
        stakeInfos[msg.sender].unClaimedReward = CurrentRewardCreated;

        addressStaked[msg.sender] = false;

        // OriginalEQ:
        // uint256 amountBack = Data.amount - ((Data.amount * 15) / 1000);
        uint256 amountBack = ((Data.amount * 1000) - (Data.amount * 15)) / 1000;
        require(amountBack > 0, "No amount to Return ");
        require(
            IstakingToken(StakingTokenAddr).transfer(msg.sender, amountBack),
            "Error On unstaking Token Transfer"
        );
        // Transfering unstaking Fee to Seperate Wallet
        require(
            IstakingToken(StakingTokenAddr).transfer(
                separateWallet,
                Data.amount - amountBack
            ),
            "Error On unstaking Token Transfer"
        );
        emit UnStaked(msg.sender, amountBack);
        return true;
    }

    function ClaimDailyRewards() public returns (bool) {
        // require(addressStaked[msg.sender] == true, "You have not staked");
        require(
            IrewardingToken(RewardingTokenAddr).allowance(
                owner,
                address(this)
            ) > 0,
            "Reward Tokens Not Availabl Right Now"
        );

        StakeInfo memory Data = stakeInfos[msg.sender];
        uint256 percentage = 7;

        // FIXME: this is a temp Daypassed , Change for Final
        uint256 dayPassed = 3;
        // Use the above statement in final Deployment
        // dayPassed= (block.timestamp -  Data.startTS)/86400;

        uint256 decimals = 10**(IrewardingToken(RewardingTokenAddr).decimals());
        uint256 point = (dayPassed) * decimals;
        uint256 CurrentRewardCreated = ((((percentage * point) / 10000) *
            Data.amount) / decimals) -
            // Subtract Already claimed Reward
            Data.claimed;

        require((CurrentRewardCreated > 0), "Current daily Reward is 0");

        stakeInfos[msg.sender].claimed =
            stakeInfos[msg.sender].claimed +
            CurrentRewardCreated;

        require(
            IrewardingToken(RewardingTokenAddr).transferFrom(
                owner,
                msg.sender,
                CurrentRewardCreated
            ),
            "Error in Transfering Reward"
        );
        emit Claimed(owner, msg.sender, CurrentRewardCreated);
        return true;
    }

    function viewStakeValue()
        public
        view
        returns (
            uint256 StartTime,
            uint256 amountStaked,
            uint256 amountClaimed,
            uint256 RewardCreated,
            uint256 dayPassed
        )
    {
        require(
            addressStaked[msg.sender] == true,
            "You not participated in staking"
        );
        StakeInfo memory Data = stakeInfos[msg.sender];
        StartTime = Data.startTS;
        amountStaked = Data.amount;
        amountClaimed = Data.claimed;
        uint256 percentage = 7;

        // FIXME: this is a temp Daypassed , Change for Final
        dayPassed = 3;
        // Use the above statement in final Deployment
        // dayPassed= (block.timestamp -  Data.startTS)/86400;
        uint256 decimals = 10**(IrewardingToken(RewardingTokenAddr).decimals());
        uint256 point = (dayPassed) * decimals;
        RewardCreated =
            (((percentage * point) / 10000) * Data.amount) /
            decimals;
    }
}

// FIXED:
// 1. handle Reward in such a way that if a user unstakes and doesn't Claims its rewards then its reward should not be Counted.
// 2. handle Deciamls so values can be handled in a better way.
// 3. Interface of Other Contracts are Added.
