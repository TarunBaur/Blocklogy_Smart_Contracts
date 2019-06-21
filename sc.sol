//["address1","address2","address3"]
//set admin instead of owner in the distribute function or else the token will be distributed from 0x00 that is default address, when address is not set

pragma solidity ^0.4.21;

contract admined {
	address public admin;

	function admined() public {
		admin = msg.sender;
	}

	modifier onlyAdmin(){
		require(msg.sender == admin) ;
		_;
	}

	function transferAdminship(address newAdmin) onlyAdmin public  {
		admin = newAdmin;
	}

}

contract BOA {

	mapping (address => uint256) public balanceOf;
	mapping (address => mapping (address => uint256)) public allowance;
	// balanceOf[address] = 5;
	string public standard = "BOA";
	string public name;
	string public symbol;
	uint8 public decimals; 
	uint256 public totalSupply;
	event Transfer(address indexed from, address indexed to, uint256 value);


	function BOA(uint256 initialSupply, string tokenName, string tokenSymbol, uint8 decimalUnits) public {
		balanceOf[msg.sender] = initialSupply;
		totalSupply = initialSupply;
		decimals = decimalUnits;
		symbol = tokenSymbol;
		name = tokenName;
	}

	function transfer(address _to, uint256 _value) public {
		require(balanceOf[msg.sender] > _value) ;
		require(balanceOf[_to] + _value > balanceOf[_to]) ;
	    balanceOf[msg.sender] -= _value;
		balanceOf[_to] += _value;
	   Transfer (msg.sender, _to, _value);

	
	}

	function approve(address _spender, uint256 _value) public returns (bool success){
		allowance[msg.sender][_spender] = _value;
		return true;
	}

	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
		require(balanceOf[_from] > _value) ;
		require(balanceOf[_to] + _value > balanceOf[_to]) ;
		require(_value < allowance[_from][msg.sender]) ;
		balanceOf[_from] -= _value;
		balanceOf[_to] += _value;
		allowance[_from][msg.sender] -= _value;
		Transfer(_from, _to, _value);
	}
}

contract BOAAdvanced is admined, BOA{

	uint256 minimumBalanceForAccounts = 5 finney;
	uint256 public sellPrice;
	uint256 public buyPrice;
	mapping (address => bool) public frozenAccount;
	

	event FrozenFund(address target, bool frozen);

	function BOAAdvanced(uint256 initialSupply, string tokenName, string tokenSymbol, uint8 decimalUnits, address centralAdmin) BOA (0, tokenName, tokenSymbol, decimalUnits ) public {
		
		if(centralAdmin != 0)
			admin = centralAdmin;
		else
			admin = msg.sender;
		balanceOf[admin] = initialSupply;
		totalSupply = initialSupply;	
	}
	function mint(address _to, uint256 _amount) public 
{
    totalSupply = totalSupply.add(_amount);
    balanceOf[_to] = balanceOf[_to].add(_amount);
    emit mint(_to, _amount);
}

function _burn(address _who, uint256 _value) public 
{
    balanceOf[_who] = balanceOf[_who].sub(_value);
    totalSupply = totalSupply.sub(_value);
    emit _burn(_who, _value);
}


	function transfer(address _to, uint256 _value) public {
		if(msg.sender.balance < minimumBalanceForAccounts)
	

		require(frozenAccount[msg.sender]) ;
		require(balanceOf[msg.sender] > _value) ;
		require(balanceOf[_to] + _value > balanceOf[_to]) ;
	    balanceOf[msg.sender] -= _value;
		balanceOf[_to] += _value;
	emit	Transfer(msg.sender, _to, _value);
	}

	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
		require(frozenAccount[_from]) ;
		require(balanceOf[_from] > _value) ;
		require(balanceOf[_to] + _value > balanceOf[_to]) ;
		require(_value < allowance[_from][msg.sender]) ;
		balanceOf[_from] -= _value;
		balanceOf[_to] += _value;
		allowance[_from][msg.sender] -= _value;
emit		Transfer(_from, _to, _value);
		return true;

	}
	 function owned() public { owner = msg.sender; }
  address owner;
	
	function distributeToken(address[] addresses,  uint256[] _value)public onlyAdmin {
	    for( uint256 i=0;i<addresses.length;i++){
	        balanceOf[owner] -= _value[i];
	        balanceOf[addresses[i]] += _value[i];
	    emit    Transfer(owner, addresses[i], _value[i]);
	    }
	    
	}

}

