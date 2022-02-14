// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Request {
    string private constant idle = "idle";
    string private constant pending = "pending";
    string private constant received = "received";
    address private constant _VRFCoordinator = 0xF32797118032CDB735Ce31678bA1Cd8A0fd7cc42; // Use it for Baobab Network
    address private constant _VRFCoordinator = 0x4d50eD3668fa645d7182D2bD55658E76d5331376; // Use it for Cypress Network
    
    mapping(address => bytes32) private _userAnswers;
    mapping(address => uint256) private _concatedAnswers;
    mapping(address => string) private _userStates;
    mapping(address => string) private _serverStates;

    function getFee() public view returns (uint256) {
        (bool sent1, bytes memory received_data) = _VRFCoordinator.staticcall(abi.encodeWithSignature("getFee()"));
        require(sent1, "Call Error");
        return abi.decode(received_data, (uint256)); // Currently, fee is 1 KLAY.
    }

    function submitUserAnswer() public payable { // If you want to get your random number, do this.
        require(getFee() == msg.value, "KLAY sent incorrect");
        require(keccak256(abi.encodePacked(_userStates[msg.sender])) != keccak256(abi.encodePacked(pending)), "Already Submitted");

        // Change it however you want.
        bytes32 requestedID = keccak256(
            abi.encodePacked(
                blockhash(block.number - 1),
                block.timestamp,
                msg.sender
            )
        );

        _userAnswers[msg.sender] = requestedID;
        _serverStates[msg.sender] = pending;
        _userStates[msg.sender] = pending;
        (bool sent2, ) = _VRFCoordinator.call{value: msg.value}(abi.encodeWithSignature("payFee(address,bytes32)", msg.sender, requestedID));
        require(sent2, "Send Error");
    }

    function submitUserAnswerAgain() public { // If you cannot get random number, do this.
        require(keccak256(abi.encodePacked(_userStates[msg.sender])) == keccak256(abi.encodePacked(pending)), "Never Submitted");
        require(keccak256(abi.encodePacked(_serverStates[msg.sender])) != keccak256(abi.encodePacked(received)), "Already Received");
        (bool sent2, ) = _VRFCoordinator.call(abi.encodeWithSignature("feePaid(address,bytes32)", msg.sender, _userAnswers[msg.sender]));
        require(sent2, "Send Error");
    }

    function getServerAnswer(address addr, bytes32 rand) public { // Don't change function's name & parameter. Never
        require(msg.sender == _VRFCoordinator, "Caller does not have permission");
        require(keccak256(abi.encodePacked(_serverStates[msg.sender])) != keccak256(abi.encodePacked(received)), "Already Received");
        bytes32 useranswer = _userAnswers[msg.sender];

        // It is your random number. Change it however you want.
        _concatedAnswers[addr] = uint256(
            keccak256(
                abi.encodePacked(
                    rand,
                    useranswer
                )
            )
        ) % 10000;

        _userStates[addr] = idle;
        _serverStates[addr] = received;
    }

    function getConcatedAnswer() public view returns (uint256) { // Example function. You can get your random number.
        return _concatedAnswers[msg.sender];
    }
}
