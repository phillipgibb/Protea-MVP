pragma solidity ^0.4.10;

import "./ERC223/SafeMath.sol";
import "./ERC223/ERC223.sol";
import "./ERC223/ERC20.sol";
import "./ERC223/ERC223Receiver.sol";

contract ERC223StandardToken is ERC20, ERC223 {
    using SafeMath for uint;
    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;
    uint256 internal _totalSupply;

    uint16 internal _issuingAmount;

    mapping (address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    // Tracks all earned tokens, not transfered
    mapping(address => uint) internal issued;

    event TokensIssued(address account, uint amount);

    function ERC223StandardToken(string name, string symbol, uint8 decimals, uint256 totalSupply, uint8 tokenIssuingAmount) public {
        uint init = _issuingAmount * 20;
        balances[msg.sender] = init;               
        issued[msg.sender] = init;               
        _symbol = symbol;
        _name = name;
        _decimals = decimals;
        _totalSupply = totalSupply;
        balances[msg.sender] = totalSupply;      
        _issuingAmount = tokenIssuingAmount;              
    }
    function name()
        public
        view
        returns (string) {
        return _name;
    }

    function symbol()
        public
        view
        returns (string) {
        return _symbol;
    }

    function decimals()
        public
        view
        returns (uint8) {
        return _decimals;
    }

    function totalSupply()
        public
        view
        returns (uint256) {
        return _totalSupply;
    }

    function checkIssued(address _account)
        public 
        view
        returns (uint256){
        return issued[_account];
    }

    function faucet() public{
        require(issued[msg.sender] == 0);
        balances[msg.sender] += _issuingAmount;
        issued[msg.sender] += _issuingAmount;
        emit TokensIssued(msg.sender, _issuingAmount);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value);
        balances[_to] = SafeMath.add(balances[_to], _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = SafeMath.sub(balances[_from], _value);
        balances[_to] = SafeMath.add(balances[_to], _value);
        allowed[_from][msg.sender] = SafeMath.sub(allowed[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = SafeMath.add(allowed[msg.sender][_spender], _addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = SafeMath.sub(oldValue, _subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
   
    function transfer(address _to, uint _value, bytes _data) public {
        require(_value > 0);
        if(isContract(_to)) {
            ERC223Receiver receiver = ERC223Receiver(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value, _data);
    }
    
    function isContract(address _addr) private view returns (bool is_contract) {
        uint length;
        assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
        }
        return (length>0);
    }
}