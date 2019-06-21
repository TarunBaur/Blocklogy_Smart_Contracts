pragma solidity ^0.4.20;
import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";


library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


contract Owned {
    address public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0x0));
        emit OwnershipTransferred(owner,_newOwner);
        owner = _newOwner;
    }
    
}


contract ERC20Token {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


contract TokenExchange is Owned, usingOraclize {
    using SafeMath for uint;
    
    ERC20Token public BOA;
    ERC20Token public EST;
    
    
    uint256 public ETHUSD;
    uint256 public lastUpdateTime;
    uint256 public gasPrice = 4000000000;
    mapping(address => uint256) public BOABalance;
    
    event LogPriceUpdated(uint256 price);
    event LogEthReceived(address from, uint256 amount);
    event LogNewOraclizeQuery(string description);
    
    constructor (address _BOAAddress, address _ESTAddress) public {
        BOA = ERC20Token(_BOAAddress);
        EST = ERC20Token(_ESTAddress);
        oraclize_setCustomGasPrice(gasPrice);
        updatePrice();
    }
    
    function() public payable {
        emit LogEthReceived(msg.sender, msg.value);
    }
    
    function depositBOA(uint256 _boaAmount) public {
        BOA.transferFrom(msg.sender, this, _boaAmount);
        BOABalance[msg.sender] = BOABalance[msg.sender].add(_boaAmount);
    }
    
    function withdrawBOA(uint256 _boaAmount) public {
        require(BOABalance[msg.sender] >= _boaAmount);
        
        BOA.transfer(msg.sender, _boaAmount);
        BOABalance[msg.sender] = BOABalance[msg.sender].sub(_boaAmount);
    }
    
    function exchage(uint256 _boaAmount) public {
        require(BOABalance[msg.sender] >= _boaAmount, "Insufficient Balance");
        
        // update price 
        if(now - lastUpdateTime > 1 hours) {
            updatePrice();
        }
        
        uint256 BOAUSD = _boaAmount.mul(5).div(10); // 1 BOA = 0.5$
        uint256 totalEST = BOAUSD.mul(100000000).div(ETHUSD.mul(5804)); // 1 EST = 0.00005804 ETH
        
        BOABalance[msg.sender] = BOABalance[msg.sender].sub(_boaAmount);
        BOABalance[owner] = BOABalance[owner].add(_boaAmount);
        
        EST.transfer(msg.sender, totalEST);
    }
    
    function updatePrice() internal {
        if (oraclize_getPrice("URL") > address(this).balance) {
           emit LogNewOraclizeQuery("Oraclize query was NOT sent, please add some ETH to cover for the query fee");
       } 
       else {
            emit LogNewOraclizeQuery("Oraclize query was sent, standing by for the answer..");
            oraclize_query("URL", "json(https://min-api.cryptocompare.com/data/price?fsym=ETH&tsyms=USD).USD");
       }
    }
    
    function __callback(bytes32 _myid, string _result) public{
        require (msg.sender == oraclize_cbAddress());
        
        ETHUSD = parseInt(_result);
        lastUpdateTime = now;
        emit LogPriceUpdated(ETHUSD);
    }
    
    function withdrawToken(address _tokenAddress, uint256 _amount) onlyOwner public {
        require(_tokenAddress != 0x0);
        
        ERC20Token(_tokenAddress).transfer(owner, _amount);
    }
    
    function withdrawETH() onlyOwner public {
        owner.transfer(address(this).balance);
    }
    
    function changeGasPrice(uint256 _gasPriceInWei) public onlyOwner {
        require(_gasPriceInWei > 1000000000);
        gasPrice = _gasPriceInWei;
    }
    
}