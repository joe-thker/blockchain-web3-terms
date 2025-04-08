// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Middleman-Free Smart Contracts
/// @notice Replaces different middlemen with decentralized Solidity-based alternatives

/// 1. Payment Processor Replacement
contract PeerPayment {
    event PaymentSent(address indexed from, address indexed to, uint256 amount);

    function sendPayment(address payable recipient) external payable {
        require(msg.value > 0, "No ETH sent");
        recipient.transfer(msg.value);
        emit PaymentSent(msg.sender, recipient, msg.value);
    }
}

/// 2. Escrow Agent Replacement
contract EscrowMiddlemanFree {
    address public buyer;
    address public seller;
    uint256 public amount;
    bool public buyerApproved;
    bool public sellerApproved;

    enum State { AWAITING_PAYMENT, AWAITING_APPROVAL, COMPLETE }
    State public currentState;

    constructor(address _seller) {
        buyer = msg.sender;
        seller = _seller;
        currentState = State.AWAITING_PAYMENT;
    }

    function deposit() external payable {
        require(msg.sender == buyer, "Only buyer");
        require(currentState == State.AWAITING_PAYMENT, "Invalid state");
        amount = msg.value;
        currentState = State.AWAITING_APPROVAL;
    }

    function approve() external {
        require(currentState == State.AWAITING_APPROVAL, "Invalid state");
        if (msg.sender == buyer) buyerApproved = true;
        else if (msg.sender == seller) sellerApproved = true;
        else revert("Unauthorized");

        if (buyerApproved && sellerApproved) {
            currentState = State.COMPLETE;
            payable(seller).transfer(amount);
        }
    }

    function cancel() external {
        require(msg.sender == buyer, "Only buyer");
        require(!buyerApproved || !sellerApproved, "Already approved");
        payable(buyer).transfer(address(this).balance);
        currentState = State.AWAITING_PAYMENT;
        buyerApproved = false;
        sellerApproved = false;
        amount = 0;
    }
}

/// 3. Notary Replacement (Document Timestamp)
contract DocumentNotary {
    mapping(bytes32 => uint256) public notarizedDocs;

    event DocumentNotarized(bytes32 indexed hash, uint256 timestamp);

    function notarize(string calldata document) external {
        bytes32 hash = keccak256(abi.encodePacked(document));
        require(notarizedDocs[hash] == 0, "Already notarized");
        notarizedDocs[hash] = block.timestamp;
        emit DocumentNotarized(hash, block.timestamp);
    }
}

/// 4. Bank Replacement (Simple Lending)
contract DecentralizedLoan {
    address public lender;
    address public borrower;
    uint256 public loanAmount;
    bool public loanRepaid;

    constructor(address _borrower) payable {
        require(msg.value > 0, "Must fund loan");
        lender = msg.sender;
        borrower = _borrower;
        loanAmount = msg.value;
        loanRepaid = false;
    }

    function acceptLoan() external {
        require(msg.sender == borrower, "Only borrower");
        payable(borrower).transfer(loanAmount);
    }

    function repayLoan() external payable {
        require(msg.sender == borrower, "Only borrower");
        require(msg.value >= loanAmount, "Repay full amount");
        loanRepaid = true;
        payable(lender).transfer(msg.value);
    }
}

/// 5. Exchange/Broker Replacement (Atomic Swap Simulation)
contract AtomicSwap {
    address public partyA;
    address public partyB;
    bytes32 public hashLock;
    uint256 public expiration;

    constructor(address _partyB, bytes32 _hashLock, uint256 _duration) payable {
        require(msg.value > 0, "Must send ETH");
        partyA = msg.sender;
        partyB = _partyB;
        hashLock = _hashLock;
        expiration = block.timestamp + _duration;
    }

    function claim(string calldata secret) external {
        require(keccak256(abi.encodePacked(secret)) == hashLock, "Invalid secret");
        require(msg.sender == partyB, "Only recipient");
        payable(partyB).transfer(address(this).balance);
    }

    function refund() external {
        require(msg.sender == partyA, "Only sender");
        require(block.timestamp >= expiration, "Too early");
        payable(partyA).transfer(address(this).balance);
    }
}
