// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CommitmentScheme {
    struct Commitment {
        bytes32 commitmentHash; // The hash of the committed value
        bool revealed;          // Has the commitment been revealed
    }
    
    mapping(address => Commitment) public commitments; // Tracks each user's commitment

    // Creates a hash from given value and nonce
    // @param value: ...
    // @param nonce: ...
    // @returns hash value calculated with the given parameters
    function createCommitmentHash(string memory value, uint256 nonce) private pure returns (bytes32) {
        // Use keccak256 with abi.encodePacked to generate the commitment hash
        return keccak256(abi.encodePacked(value, nonce));
    }

    /*
    Allows a user to make a commitment by submitting a hashed value.
    The user must not have already committed and revealed a value.
    This commitment is recorded and can be revealed later to validate the user's initial choice.
    @param _commitmentHash A bytes32 hash representing the user's commitment.
    @return None
    */
    function makeCommitment(bytes32 _commitmentHash) public {
        require(!commitments[msg.sender].revealed, "Already committed and revealed.");
        commitments[msg.sender] = Commitment({
            commitmentHash: _commitmentHash,
            revealed: false
        });
    }

    // Function to reveal the committed value
    /*
    Reveals a previously committed value by verifying it against the stored commitment hash.
    The user must provide the original value and nonce used to create the commitment hash.
    Function ensures that the revealed value and nonce match the original commitment hash.
    @param _value The original value that was committed (before hashing).
    @param _nonce A unique nonce used alongside the value in the commitment hash.
    */
    function revealCommitment(string memory _value, uint256 _nonce) public {
        Commitment storage commitment = commitments[msg.sender];
        require(!commitment.revealed, "Commitment already revealed.");
        require(commitment.commitmentHash != bytes32(0), "No commitment made.");

        // Hash the revealed value with the nonce
        bytes32 hash = keccak256(abi.encodePacked(_value, _nonce));
        require(hash == commitment.commitmentHash, "Commitment does not match.");

        // Mark as revealed
        commitment.revealed = true;
    }

    /*
    Checks if a given user's commitment has been revealed.
    * @param _user The address of the user whose commitment reveal status is being checked.
    * @return bool Returns `true` if the user's commitment has been revealed, `false` otherwise.
    */
    function isRevealed(address _user) public view returns (bool) {
        return commitments[_user].revealed;
    }
}
