// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.3;

contract ERC_20 {
    event Transfer(address from, address to, uint256 value);
    event Approval(address owner, address spender, uint256 value);

    string tokenName;
    string tokenSymbol;
    uint256 tokenTotalSupply;
    uint8 tokenDecimals;
    mapping(address => uint256) balance;
    mapping(address => mapping(address => uint256)) approvalLimit;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _tokenTotalSupply
    ) {
        tokenName = _tokenName;
        tokenSymbol = _tokenSymbol;
        tokenDecimals = 18;
        tokenTotalSupply = _tokenTotalSupply * 10**tokenDecimals;
        balance[msg.sender] = tokenTotalSupply;
    }

    function name() public view returns (string memory) {
        return tokenName;
    }

    function symbol() public view returns (string memory) {
        return tokenSymbol;
    }

    function totalSupply() public view returns (uint256) {
        return tokenTotalSupply;
    }

    function decimals() public view returns (uint8) {
        return tokenDecimals;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balance[_owner];
    }

    function transfer(address _to, uint256 _value)
        public
        virtual
        returns (bool success)
    {
        require(_to != address(0), "Address should not be 0!");
        require(_to != msg.sender, "Cannot Transfer to tokens itself");
        require(
            balance[msg.sender] >= _value,
            "You don't have requsted number of tokens"
        );

        balance[msg.sender] -= _value;
        balance[_to] += _value;
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public virtual returns (bool success) {
        require(_to != address(0), "Address should not be 0!");
        require(_from != address(0), "Address should not be 0!");
        require(
            approvalLimit[_from][msg.sender] >= _value &&
                balance[_from] >= _value,
            "Amount not Approved"
        );
        // if (approvalLimit[msg.sender][_from]>=_value){
        // msg.sender = omar
        //              usama=>omar=>10;
        if (approvalLimit[_from][msg.sender] >= _value) {
            balance[_from] -= _value;
            balance[_to] += _value;
            approvalLimit[_from][msg.sender] -= _value;
            return true;
        } else {
            return false;
        }
    }

    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        require(
            msg.sender != _spender,
            "Sender is Already approve to spend his spendings!"
        );
        // require(msg.sender]>=_value,"You don't have requsted number of tokens");
        // if (balance[msg.sender] >= _value) {
        // msg.sender = usama
        //              usama=>omar=>10;
        approvalLimit[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
        // } else {
        //     return false;
        // }
    }

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining)
    {
        require(_owner != address(0), "Address should not be 0!");
        require(_spender != address(0), "Address should not be 0!");
        return approvalLimit[_owner][_spender];
    }
}
