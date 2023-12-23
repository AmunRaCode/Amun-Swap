// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract AmunSwap {
    string public constant NAME = "Amun Swap";
    string public constant SYMBOL = "AMUN";
    uint8 public constant DECIMALS = 18;

    uint256 public totalSupply;
    address public immutable owner;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;
    uint256 public nextProposalId;
    mapping(uint256 => Proposal) public proposals;

    struct Proposal {
        address proposer;
        uint256 endTime;
        bool executed;
        mapping(address => bool) voted;
        uint256 voteCount;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event ProposalCreated(uint256 indexed proposalId, uint256 endTime);
    event Voted(uint256 indexed proposalId, bool vote);
    event ProposalExecuted(uint256 indexed proposalId);

    constructor() {
        owner = msg.sender;
        totalSupply = 10000000 * (10 ** uint256(DECIMALS));
        balances[owner] = totalSupply;
        emit Transfer(address(0), owner, totalSupply);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    function transfer(address recipient, uint256 amount) public {
        require(balances[msg.sender] >= amount, "Insufficient balance.");
        _transfer(msg.sender, recipient, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(recipient != address(0), "Transfer to the zero address");
        balances[sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approveInternal(msg.sender, spender, amount);
        return true;
    }

    function _approveInternal(address ownerAddr, address spender, uint256 amount) internal {
        require(spender != address(0), "Approve to the zero address");
        allowed[ownerAddr][spender] = amount;
        emit Approval(ownerAddr, spender, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(amount <= balances[from], "Insufficient balance");
        require(amount <= allowed[from][msg.sender], "Insufficient allowance");
        _transfer(from, to, amount);
        _approveInternal(from, msg.sender, allowed[from][msg.sender] - amount);
        return true;
    }

    function increaseSupply(uint256 amount) public onlyOwner {
        totalSupply += amount;
        balances[owner] += amount;
        emit Transfer(address(0), owner, amount);
    }

    function decreaseSupply(uint256 amount) public onlyOwner {
        require(balances[owner] >= amount, "Insufficient balance to decrease supply.");
        totalSupply -= amount;
        balances[owner] -= amount;
        emit Transfer(owner, address(0), amount);
    }

    function createProposal(uint256 duration) public {
        require(balances[msg.sender] > 0, "Only token holders can create proposals");
        Proposal storage newProposal = proposals[nextProposalId];
        newProposal.proposer = msg.sender;
        newProposal.endTime = block.timestamp + duration;
        newProposal.executed = false;
        newProposal.voteCount = 0;
        emit ProposalCreated(nextProposalId, newProposal.endTime);
        nextProposalId++;
    }

    function voteOnProposal(uint256 proposalId, bool userVote) public {
        require(balances[msg.sender] > 0, "Only token holders can vote");
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp <= proposal.endTime, "Voting period has ended");
        require(!proposal.voted[msg.sender], "Voter has already voted");
        proposal.voted[msg.sender] = true;
        if (userVote) {
            proposal.voteCount++;
        }
        emit Voted(proposalId, userVote);
    }

    function executeProposal(uint256 proposalId) public {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp > proposal.endTime, "Voting period has not yet ended");
        require(!proposal.executed, "Proposal already executed");
        require(proposal.voteCount > totalSupply / 2, "Majority vote has not reached");
        proposal.executed = true;
        emit ProposalExecuted(proposalId);
    }
}
