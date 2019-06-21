pragma solidity ^0.4.25;

contract Certs {
    address public certificateAuthority;
    string public certificateAuthorityName;
     address owner;
    mapping (bytes32 => bytes32) certificate; //keccak256(register-number) => keccak256(other info)
    
    event Issued(bytes32 key);

    constructor (string _certificateAuthorityName) public {
        certificateAuthority = msg.sender;
        certificateAuthorityName = _certificateAuthorityName;
    }
    modifier onlyOwner() {
    require(msg.sender == owner);
    _;
}
    //transactional functions
    function issue(bytes32 _regNo, bytes32 _name, uint _percentile) onlyOwner external {
        require(msg.sender == certificateAuthority); //check authority
        require(certificate[keccak256(_regNo)] == 0 ); //check if already exists
        bytes32 key = keccak256(_regNo);
        certificate[ key ] = keccak256(_regNo, _name, _percentile); //storage
     emit  Issued(key); //fire issued event
    }
    //constant functions
    function verify(bytes32 _regNo, bytes32 _name, uint _percentile) public  returns (bool)  {
        if( certificate[keccak256(_regNo)] == sha3(_regNo, _name, _percentile) ) {
            return true;
        }       
        return false;
    }
}