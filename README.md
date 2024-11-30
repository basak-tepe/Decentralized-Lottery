# CMPE 483 - PROJECT 1 - LOTTERY

# OVERVIEW
The CommitmentScheme contract is designed to handle the process of making and revealing commitments in a secure and verifiable manner. It allows users to commit to a secret value by hashing it with a nonce, and later reveal the value to prove they were the original committers. The contract ensures that users cannot change their committed values once submitted, and that each user’s commitment can only be revealed once.

# FEATURES
	1.	Commitment Hashing: Users can create a hash of a value and nonce to commit to a secret without revealing it initially.
	2.	Commitment Creation: Users can submit their commitment hashes to the contract.
	3.	Commitment Reveal: Users can reveal their committed values and nonce, which are verified against the initial commitment hash.
	4.	Commitment Status: Users and others can check if a user’s commitment has been revealed.

# FUNCTIONS
# createCommitmentHash(string memory value, uint256 nonce) public pure returns (bytes32)

	•	Description: Generates a hash from a given value and nonce using keccak256.
	•	Parameters:
	•	value: The secret value to commit.
	•	nonce: A unique nonce used to generate the hash and ensure the commitment is unique.
	•	Returns: A bytes32 commitment hash generated using keccak256(abi.encodePacked(value, nonce)).

# makeCommitment(bytes32 _commitmentHash) public

	•	Description: Allows a user to submit their commitment hash to the contract. Once a commitment is made, it cannot be changed or revealed until the user explicitly reveals it.
	•	Parameters:
	•	_commitmentHash: The bytes32 hash representing the commitment that the user wants to make.
	•	Restrictions: A user can only make a commitment if they haven’t already revealed a commitment.

# revealCommitment(string memory _value, uint256 _nonce) public

	•	Description: Reveals a previously made commitment. The user provides the original value and nonce used to generate the commitment hash. The contract checks if the provided data matches the previously submitted commitment hash.
	•	Parameters:
	•	_value: The original value that was committed (before it was hashed).
	•	_nonce: The unique nonce used alongside the value to generate the commitment hash.
	•	Restrictions: The user can only reveal their commitment once, and only if the commitment hash matches the previously stored hash.

# isRevealed(address _user) public view returns (bool)

	•	Description: Checks if a user’s commitment has been revealed.
	•	Parameters:
	•	_user: The address of the user whose commitment reveal status is being checked.
	•	Returns: true if the user’s commitment has been revealed, false otherwise.

# USAGE

# 1. Creating a Commitment
First, the user creates a commitment hash by calling the createCommitmentHash function with a secret value and a nonce. The user then calls makeCommitment with the generated hash.

# 2. Revealing the Commitment
To reveal their commitment, the user calls revealCommitment with the original value and nonce.

# 3. Check if the Commitment is Revealed
Anyone can check if the commitment has been revealed by using isRevealed.

# LICENCE
This contract is licensed under the MIT License.
