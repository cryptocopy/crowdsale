pragma solidity ^0.4.6;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Owned {

    // The address of the account that is the current owner
    address public owner;

    // The publiser is the inital owner
    function Owned() {
        owner = msg.sender;
    }

    /**
     * Restricted access to the current owner
     */
    modifier onlyOwner() {
        if (msg.sender != owner) throw;
        _;
    }

    /**
     * Transfer ownership to `_newOwner`
     *
     * @param _newOwner The address of the account that will become the new owner
     */
    function transferOwnership(address _newOwner) onlyOwner {
        owner = _newOwner;
    }
}

// Abstract contract for the full ERC 20 Token standard
// https://github.com/ethereum/EIPs/issues/20
contract Token {
    /// total amount of tokens
    uint256 public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

/**
 * @title CryptoCopy token
 *
 * Implements ERC 20 Token standard: https://github.com/ethereum/EIPs/issues/20 with the addition
 * of ownership, a lock and issuing.
 *
 */
contract CryptoCopyToken is Owned, Token {

    using SafeMath for uint256;

    // Ethereum token standaard
    string public standard = "Token 0.2";

    // Full name
    string public name = "CryptoCopy token";

    // Symbol
    string public symbol = "CCOPY";

    // No decimal points
    uint8 public decimals = 8;
    
    // No decimal points
    uint256 public maxTotalSupply = 1000000 * 10 ** 8; // 1 million

    // Token starts if the locked state restricting transfers
    bool public locked;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    /**
     * Get balance of `_owner`
     *
     * @param _owner The address from which the balance will be retrieved
     * @return The balance
     */
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    /**
     * Send `_value` token to `_to` from `msg.sender`
     *
     * @param _to The address of the recipient
     * @param _value The amount of token to be transferred
     * @return Whether the transfer was successful or not
     */
    function transfer(address _to, uint256 _value) returns (bool success) {

        // Unable to transfer while still locked
        if (locked) {
            throw;
        }

        // Check if the sender has enough tokens
        if (balances[msg.sender] < _value) {
            throw;
        }

        // Check for overflows
        if (balances[_to] + _value < balances[_to])  {
            throw;
        }

        // Transfer tokens
        balances[msg.sender] -= _value;
        balances[_to] += _value;

        // Notify listners
        Transfer(msg.sender, _to, _value);

        return true;
    }

    /**
     * Send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value The amount of token to be transferred
     * @return Whether the transfer was successful or not
     */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {

         // Unable to transfer while still locked
        if (locked) {
            throw;
        }

        // Check if the sender has enough
        if (balances[_from] < _value) {
            throw;
        }

        // Check for overflows
        if (balances[_to] + _value < balances[_to]) {
            throw;
        }

        // Check allowance
        if (_value > allowed[_from][msg.sender]) {
            throw;
        }

        // Transfer tokens
        balances[_to] += _value;
        balances[_from] -= _value;

        // Update allowance
        allowed[_from][msg.sender] -= _value;

        // Notify listners
        Transfer(_from, _to, _value);
        
        return true;
    }

    /**
     * `msg.sender` approves `_spender` to spend `_value` tokens
     *
     * @param _spender The address of the account able to transfer the tokens
     * @param _value The amount of tokens to be approved for transfer
     * @return Whether the approval was successful or not
     */
    function approve(address _spender, uint256 _value) returns (bool success) {

        // Unable to approve while still locked
        if (locked) {
            throw;
        }

        // Update allowance
        allowed[msg.sender][_spender] = _value;

        // Notify listners
        Approval(msg.sender, _spender, _value);
        return true;
    }


    /**
     * Get the amount of remaining tokens that `_spender` is allowed to spend from `_owner`
     *
     * @param _owner The address of the account owning tokens
     * @param _spender The address of the account able to transfer the tokens
     * @return Amount of remaining tokens allowed to spent
     */
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    /**
     * Starts with a total supply of zero and the creator starts with
     * zero tokens (just like everyone else)
     */
    function CryptoCopyToken() {
        balances[msg.sender] = 0;
        totalSupply = 0;
        locked = false;
    }


    /**
     * Unlocks the token irreversibly so that the transfering of value is enabled
     *
     * @return Whether the unlocking was successful or not
     */
    function unlock() onlyOwner returns (bool success)  {
        locked = false;
        return true;
    }

    /**
     * Locks the token irreversibly so that the transfering of value is not enabled
     *
     * @return Whether the locking was successful or not
     */
    function lock() onlyOwner returns (bool success)  {
        locked = true;
        return true;
    }
    
    /**
     * Restricted access to the current owner
     */
    modifier onlyOwner() {
        if (msg.sender != owner) throw;
        _;
    }

    /**
     * Issues `_value` new tokens to `_recipient`
     *
     * @param _recipient The address to which the tokens will be issued
     * @param _value The amount of new tokens to issue
     * @return Whether the approval was successful or not
     */
    function issue(address _recipient, uint256 _value) onlyOwner returns (bool success) {

        if (totalSupply + _value > maxTotalSupply) {
            return;
        }
        
        // Create tokens
        balances[_recipient] += _value;
        totalSupply += _value;

        return true;
    }

    event Burn(address indexed burner, uint indexed value);

    /**
     * Prevents accidental sending of ether
     */
    function () {
        throw;
    }
}


contract CryptoCopyCrowdsale {

    using SafeMath for uint256;

    // Crowdsale addresses
    address public creator;
    address public buyBackFund;
    address public bountyPool;
    address public advisoryPool;

    uint256 public minAcceptedEthAmount = 100 finney; // 0.1 ether

    // ICOs specification
    uint256 public maxTotalSupply = 1000000 * 10**8; // 1 mil. tokens
    uint256 public tokensForInvestors = 900000 * 10**8; // 900.000 tokens
    uint256 public tokensForBounty = 50000 * 10**8; // 50.000 tokens
    uint256 public tokensForAdvisory = 50000 * 10**8; // 50.000 tokens

    uint256 public totalTokenIssued; // Total of issued tokens

    uint256 public bonusFirstTwoDaysPeriod = 2 days;
    uint256 public bonusFirstWeekPeriod = 9 days;
    uint256 public bonusSecondWeekPeriod = 16 days;
    uint256 public bonusThirdWeekPeriod = 23 days;
    uint256 public bonusFourthWeekPeriod = 30 days;
    
    uint256 public bonusFirstTwoDays = 20;
    uint256 public bonusFirstWeek = 15;
    uint256 public bonusSecondWeek = 10;
    uint256 public bonusThirdWeek = 5;
    uint256 public bonusFourthWeek = 5;
    uint256 public bonusSubscription = 5;
    
    uint256 public bonusOver3ETH = 10;
    uint256 public bonusOver10ETH = 20;
    uint256 public bonusOver30ETH = 30;
    uint256 public bonusOver100ETH = 40;

    // Balances
    mapping (address => uint256) balancesETH;
    mapping (address => uint256) balancesETHWithBonuses;
    mapping (address => uint256) balancesETHForSubscriptionBonus;
    mapping (address => uint256) tokenBalances;
    
    uint256 public totalInvested;
    uint256 public totalInvestedWithBonuses;

    uint256 public hardCap = 100000 ether; // 100k ethers
    uint256 public softCap = 175 ether; // 175 ethers
    
    enum Stages {
        Countdown,
        Ico,
        Ended
    }

    Stages public stage = Stages.Countdown;

    // Crowdsale times
    uint public start;
    uint public end;

    // CryptoCopy token
    Token public CryptoCopyToken;

    
    function setToken(address newToken) public onlyCreator {
        CryptoCopyToken = Token(newToken);
    }
    
    function returnOwnershipOfToken() public onlyCreator {
        CryptoCopyToken.transferOwnership(creator);
    }

    /**
     * Throw if at stage other than current stage
     *
     * @param _stage expected stage to test for
     */
    modifier atStage(Stages _stage) {
        updateState();

        if (stage != _stage) {
            throw;
        }
        _;
    }


    /**
     * Throw if sender is not creator
     */
    modifier onlyCreator() {
        if (creator != msg.sender) {
            throw;
        }
        _;
    }

    /**
     * Get ethereum balance of `_investor`
     *
     * @param _investor The address from which the balance will be retrieved
     * @return The balance
     */
    function balanceOf(address _investor) constant returns (uint256 balance) {
        return balancesETH[_investor];
    }

    /**
     * Construct
     *
     * @param _tokenAddress Address of the token
     * @param _start Start of ICO
     * @param _end End of ICO
     */
    function CryptoCopyCrowdsale(address _tokenAddress, uint256 _start, uint256 _end) {
        CryptoCopyToken = Token(_tokenAddress);
        creator = msg.sender;
        start = _start;
        end = _end;
    }
    
    /**
     * Withdraw for bounty and advisory pools
     */
    function withdrawBountyAndAdvisory() onlyCreator {
        if (!CryptoCopyToken.issue(bountyPool, tokensForBounty)) {
            throw;
        }
        
        if (!CryptoCopyToken.issue(advisoryPool, tokensForAdvisory)) {
            throw;
        }
    }
    
    /**
     * Set up end date
     */
    function setEnd(uint256 _end) onlyCreator {
        end = _end;
    }
    
    /**
     * Set up bounty pool
     *
     * @param _bountyPool Bounty pool address
     */
    function setBountyPool(address _bountyPool) onlyCreator {
        bountyPool = _bountyPool;
    }
    
    /**
     * Set up advisory pool
     *
     * @param _advisoryPool Bounty pool address
     */
    function setAdvisoryPool(address _advisoryPool) onlyCreator {
        advisoryPool = _advisoryPool;
    }
    
    /**
     * Set buy back fund address
     *
     * @param _buyBackFund Bay back fund address
     */
    function setBuyBackFund(address _buyBackFund) onlyCreator {
        buyBackFund = _buyBackFund;
    }

    /**
     * Update crowd sale stage based on current time
     */
    function updateState() {
        uint256 timeBehind = now - start;

        if (totalInvested >= hardCap || now > end) {
            stage = Stages.Ended;
            return;
        }
        
        if (now < start) {
            stage = Stages.Countdown;
            return;
        }

        stage = Stages.Ico;
    }

    /**
     * Release tokens after the ICO
     */
    function releaseTokens(address investorAddress) onlyCreator {
        if (stage != Stages.Ended) {
            return;
        }
        
        uint256 tokensToBeReleased = tokensForInvestors * balancesETHWithBonuses[investorAddress] / totalInvestedWithBonuses;

        if (tokenBalances[investorAddress] == tokensToBeReleased) {
            return;
        }
        
        if (!CryptoCopyToken.issue(investorAddress, tokensToBeReleased - tokenBalances[investorAddress])) {
            throw;
        }
        
        tokenBalances[investorAddress] = tokensToBeReleased;
    }

    /**
     * Transfer raised amount to the company address
     */
    function withdraw() onlyCreator {
        uint256 ethBalance = this.balance;
        
        if (stage != Stages.Ended) {
            throw;
        }
        
        if (!creator.send(ethBalance)) {
            throw;
        }
    }
    

    /**
     * Add additional bonus for subscribed investors
     *
     * @param investorAddress Address of investor
     */
    function addSubscriptionBonus(address investorAddress) onlyCreator {
        uint256 alreadyIncludedSubscriptionBonus = balancesETHForSubscriptionBonus[investorAddress];
        
        uint256 subscriptionBonus = balancesETH[investorAddress] * bonusSubscription / 100;
        
        balancesETHForSubscriptionBonus[investorAddress] = subscriptionBonus;
        
        totalInvestedWithBonuses = totalInvestedWithBonuses.add(subscriptionBonus - alreadyIncludedSubscriptionBonus);
        balancesETHWithBonuses[investorAddress] = balancesETHWithBonuses[investorAddress].add(subscriptionBonus - alreadyIncludedSubscriptionBonus);
    }

    /**
     * Receives Eth
     */
    function () payable atStage(Stages.Ico) {
        uint256 receivedEth = msg.value;
        uint256 totalBonuses = 0;

        if (receivedEth < minAcceptedEthAmount) {
            throw;
        }
        
        if (now < start + bonusFirstTwoDaysPeriod) {
            totalBonuses += bonusFirstTwoDays;
        } else if (now < start + bonusFirstWeekPeriod) {
            totalBonuses += bonusFirstWeek;
        } else if (now < start + bonusSecondWeekPeriod) {
            totalBonuses += bonusSecondWeek;
        } else if (now < start + bonusThirdWeekPeriod) {
            totalBonuses += bonusThirdWeek;
        } else if (now < start + bonusFourthWeekPeriod) {
            totalBonuses += bonusFourthWeek;
        }
        
        if (receivedEth >= 100 ether) {
            totalBonuses += bonusOver100ETH;
        } else if (receivedEth >= 30 ether) {
            totalBonuses += bonusOver30ETH;
        } else if (receivedEth >= 10 ether) {
            totalBonuses += bonusOver10ETH;
        } else if (receivedEth >= 3 ether) {
            totalBonuses += bonusOver3ETH;
        }
        
        uint256 receivedEthWithBonuses = receivedEth + (receivedEth * totalBonuses / 100);
        
        totalInvested = totalInvested.add(receivedEth);
        totalInvestedWithBonuses = totalInvestedWithBonuses.add(receivedEthWithBonuses);
        balancesETH[msg.sender] = balancesETH[msg.sender].add(receivedEth);
        balancesETHWithBonuses[msg.sender] = balancesETHWithBonuses[msg.sender].add(receivedEthWithBonuses);
    }
}