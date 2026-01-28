// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract ReferralSimple {

    mapping(address => address) public referrerOf;
    
    mapping(address => uint256) public inviteeCount;
    
    mapping(address => mapping(uint256 => address)) private inviteeByIndex;
    
    mapping(address => mapping(address => bool)) private hasInvitee;
    
    uint256 public constant MAX_CHAIN_DEPTH = 6;

    event ReferralBound(address indexed invitee, address indexed referrer, uint256 timestamp);

    function bindReferrer(address referrer) external {
        require(referrer != address(0), "invalid referrer");
        require(referrer != msg.sender, "self not allowed");
        require(referrerOf[msg.sender] == address(0), "already bound");
        
        // Check for circular reference by traversing up the chain
        require(!_wouldCreateCircle(referrer, msg.sender), "circular referral not allowed");
        
        referrerOf[msg.sender] = referrer;
        
        if (!hasInvitee[referrer][msg.sender]) {
            inviteeByIndex[referrer][inviteeCount[referrer]] = msg.sender;
            inviteeCount[referrer]++;
            hasInvitee[referrer][msg.sender] = true;
        }
        
        emit ReferralBound(msg.sender, referrer, block.timestamp);
    }
    
    function _wouldCreateCircle(address referrer, address invitee) private view returns (bool) {
        address current = referrer;
        
        for (uint256 i = 0; i < MAX_CHAIN_DEPTH; i++) {
            if (current == address(0)) {
                return false;
            }
            if (current == invitee) {
                return true;
            }
            current = referrerOf[current];
        }
        
        return false;
    }

    function getInviteeAt(address referrer, uint256 index) external view returns (address) {
        require(index < inviteeCount[referrer], "index out of range");
        return inviteeByIndex[referrer][index];
    }

    function getInvitees(address referrer, uint256 start, uint256 limit) 
        external 
        view 
        returns (address[] memory invitees, uint256 total) 
    {
        total = inviteeCount[referrer];
        
        if (start >= total) {
            return (new address[](0), total);
        }
        
        uint256 end = start + limit;
        if (end > total) {
            end = total;
        }
        
        uint256 resultLength = end - start;
        invitees = new address[](resultLength);
        
        for (uint256 i = 0; i < resultLength; i++) {
            invitees[i] = inviteeByIndex[referrer][start + i];
        }
    }
    
    function hasReferrer(address user) external view returns (bool) {
        return referrerOf[user] != address(0);
    }
    
    function batchGetReferrers(address[] calldata users) 
        external 
        view 
        returns (address[] memory referrers) 
    {
        referrers = new address[](users.length);
        for (uint256 i = 0; i < users.length; i++) {
            referrers[i] = referrerOf[users[i]];
        }
    }
    
    function getReferralChain(address user, uint256 maxDepth) 
        external 
        view 
        returns (address[] memory chain) 
    {
        address[] memory tempChain = new address[](maxDepth);
        uint256 count = 0;
        address current = referrerOf[user];
        
        while (current != address(0) && count < maxDepth) {
            tempChain[count] = current;
            count++;
            current = referrerOf[current];
        }
        
        chain = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            chain[i] = tempChain[i];
        }
    }
    
    function getReferralStats(address user) 
        external 
        view 
        returns (
            bool hasRef,
            address referrer,
            uint256 invitees
        ) 
    {
        hasRef = referrerOf[user] != address(0);
        referrer = referrerOf[user];
        invitees = inviteeCount[user];
    }
    
    function version() external pure returns (string memory) {
        return "1.0.2";
    }
}
