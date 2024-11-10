// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "remix_tests.sol"; // Importing Remix tests
import "../contracts/Commitments.sol"; // Import your contract file here

contract TestCommitmentScheme {
    CommitmentScheme public commitmentScheme;
    address public user1;
    address public user2;
    
    function beforeAll() public {
        commitmentScheme = new CommitmentScheme();
        user1 = address(0x123); // Random address for user1
        user2 = address(0x456); // Random address for user2
    }

    // Test for creating and making a commitment
    function testMakeCommitment() public {
        string memory value = "user1_commitment";
        uint256 nonce = 12345;

        // Generate the commitment hash directly in the test
        bytes32 commitmentHash = keccak256(abi.encodePacked(value, nonce));
        
        // Make the commitment for user1
        commitmentScheme.makeCommitment(commitmentHash);

        // Verify that the commitment has been made
        bool isRevealed = commitmentScheme.isRevealed(user1);
        Assert.equal(isRevealed, false, "User's commitment should not be revealed yet");
    }

    // Test for revealing a commitment with correct values
    function testRevealCommitment() public {
        string memory value = "user1_commitment";
        uint256 nonce = 12345;

        // Generate the commitment hash directly in the test
        bytes32 commitmentHash = keccak256(abi.encodePacked(value, nonce));

        // Make the commitment for user1
        commitmentScheme.makeCommitment(commitmentHash);

        // Reveal the commitment with correct value and nonce
        commitmentScheme.revealCommitment(value, nonce);

        // Verify that the commitment has been revealed
        bool isRevealed = commitmentScheme.isRevealed(user1);
        Assert.equal(isRevealed, true, "User's commitment should be revealed after revealing");
    }

    // Test for failing reveal with incorrect value or nonce
    function testRevealCommitmentFail() public {
        string memory value = "user1_commitment";
        uint256 nonce = 12345;

        // Generate the commitment hash directly in the test
        bytes32 commitmentHash = keccak256(abi.encodePacked(value, nonce));

        // Make the commitment for user1
        commitmentScheme.makeCommitment(commitmentHash);

        // Try to reveal with an incorrect nonce
        string memory incorrectValue = "wrong_value";
        uint256 incorrectNonce = 67890;

        bool success = false;
        try commitmentScheme.revealCommitment(incorrectValue, incorrectNonce) {
            success = true;
        } catch {}

        // Ensure that the reveal fails due to incorrect data
        Assert.equal(success, false, "Revealing with incorrect value or nonce should fail");
    }

    // Test for revealing a commitment twice (should fail)
    function testRevealCommitmentTwice() public {
        string memory value = "user1_commitment";
        uint256 nonce = 12345;

        // Generate the commitment hash directly in the test
        bytes32 commitmentHash = keccak256(abi.encodePacked(value, nonce));

        // Make the commitment for user1
        commitmentScheme.makeCommitment(commitmentHash);

        // Reveal the commitment with correct value and nonce
        commitmentScheme.revealCommitment(value, nonce);

        // Try to reveal the commitment again (should fail)
        bool success = false;
        try commitmentScheme.revealCommitment(value, nonce) {
            success = true;
        } catch {}

        // Ensure that revealing the commitment twice fails
        Assert.equal(success, false, "Revealing the same commitment twice should fail");
    }

    // Test for checking revealed commitment status
    function testIsRevealed() public {
        string memory value = "user2_commitment";
        uint256 nonce = 54321;

        // Generate the commitment hash directly in the test
        bytes32 commitmentHash = keccak256(abi.encodePacked(value, nonce));

        // Make the commitment for user2
        commitmentScheme.makeCommitment(commitmentHash);

        // Verify that the commitment has not been revealed yet
        bool isRevealedBefore = commitmentScheme.isRevealed(user2);
        Assert.equal(isRevealedBefore, false, "User2's commitment should not be revealed initially");

        // Reveal the commitment with correct value and nonce
        commitmentScheme.revealCommitment(value, nonce);

        // Verify that the commitment has been revealed
        bool isRevealedAfter = commitmentScheme.isRevealed(user2);
        Assert.equal(isRevealedAfter, true, "User2's commitment should be revealed after revealing");
    }

    // Test for failing to make a new commitment after revealing
    function testMakeCommitmentAfterReveal() public {
        string memory value = "user2_commitment";
        uint256 nonce = 54321;

        // Generate the commitment hash directly in the test
        bytes32 commitmentHash = keccak256(abi.encodePacked(value, nonce));

        // Make the commitment for user2
        commitmentScheme.makeCommitment(commitmentHash);

        // Reveal the commitment
        commitmentScheme.revealCommitment(value, nonce);

        // Try to make another commitment after revealing (should fail)
        bool success = false;
        try commitmentScheme.makeCommitment(commitmentHash) {
            success = true;
        } catch {}

        // Ensure that making a new commitment after revealing fails
        Assert.equal(success, false, "Cannot make a new commitment after revealing");
    }
}
