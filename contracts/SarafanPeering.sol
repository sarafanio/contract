pragma solidity ^0.6.3;

import './Math.sol';
import { SarafanToken } from './SarafanToken.sol';


contract SarafanPeering {
    using SafeMath for uint256;

    address private contractOwner;
    bool private waitPayout = true;
    mapping (address => mapping(bytes32 => bool)) hasVerify;

    struct HashInfo {
        // verifies measured in volume of tokens verifiers owns
        uint256 verifies;
        // rejects measured in volume of tokens rejectors owns
        uint256 rejects;
        // reported size of stored content in bytes
        uint256 size;
        // reward address
        address author;
        // last block timestamp at moment of commitment
        uint256 commitTime;
        // number of hours peer stored this content (as reported by peer)
        uint256 timeInterval;
        // average approved value (0 - 1000)
        // value is based on stored content stats like individual file rarity and distance between
        // content file hash and node hash (peers forced to store files as much as close to their hash)
        uint32 averageValue;
        // average verify amount (weight of validation peer)
        uint256 averageAmount;
        // number of values collected
        uint256 valueCount;
    }

    SarafanToken sarafanContract;

    mapping (bytes32 => HashInfo) public hashes;
    mapping (bytes32 => bool) public hashExists;

    /* New peer joined event.

    Used for peer discovering and for matching hostname with reward address.
    */
    event NewPeer(address addr, bytes32 hostname);
    // timeInterval — is a time in hours peer reported to store this data size
    event Commit(bytes32 dataHash, address from, uint256 size, uint32 timeInterval);
    // Verify dataHash validity
    event Verify(bytes32 dataHash, address from, uint256 amount, uint32 value);
    // Reject dataHash after verification
    event Reject(bytes32 dataHash, address from, uint256 amount);
    // Successful payout for dataHash to address
    event Payout(bytes32 dataHash, address to, uint256 amount);

    /* Peering contract constructor.

    Receive SarafanToken contract address for input.
    */
    constructor(address payable parent) public {
        sarafanContract = SarafanToken(parent);
        contractOwner = msg.sender;
    }

    /* Register new peer.

    Used for initial peer discovery.
    */
    function register(bytes32 hostname) public {
        emit NewPeer(msg.sender, hostname);
    }

    /* Commit for storage.

    Peer should provide root Merkle tree hash for validation. This tree and related content should
    be available and accessible for validators for 1 day after commitment or validation fails.

    First commit will never be payed. It stays to starting point for next billing period.

    There are should be less than 12 hours between commitments for validators to take last in count.

    - `dataHash` - root merkle tree hash of content stored by peer
    - `size` - reported content size
    - `timeInterval` - number of hours content stored
    */
    function commit(bytes32 dataHash, uint256 size, uint32 timeInterval) public {
        require(hashExists[dataHash] == false, "This data hash already committed");
        hashes[dataHash] = HashInfo({
            size: size,
            commitTime: block.timestamp,
            author: msg.sender,
            timeInterval: timeInterval,
            verifies: 0,
            rejects: 0,
            averageValue: 0,
            averageAmount: 0,
            valueCount: 0
        });
        hashExists[dataHash] = true;
        emit Commit(dataHash, msg.sender, size, timeInterval);
    }

    /* Verify validity of content hash provided by peer.

    Validation peer must perform multiple checks against storage peer content
    before invoke this method.

    Verify `value` is amount of data that should be payed and should be between 0 and 100000.

    - `dataHash` - root merkle tree hash of content stored by peer
    - `value` — amount of hash should be payed (0 - 100000)
    */
    function verify(bytes32 dataHash, uint32 value) public {
        require(value > 0, "Value should be greater than 0");
        require(value <= 100000, "Verify value should be between 1 and 100000");

        uint256 amount = sarafanContract.balanceOf(msg.sender);
        require(amount >= 10000000, "Only owners of 10M tokens can send verifications");

        require(hasVerify[msg.sender][dataHash] == false, "Already verified");

        HashInfo memory hash = hashes[dataHash];

        // add sender token balance to verified amount
        hash.verifies = hashes[dataHash].verifies.add(amount);

        // recalculate averageAmount (avg validation peer weight) for hash using sender amount
        if (hash.averageAmount == 0) {
            hash.averageAmount = amount;
        } else {
            hash.averageAmount = hash.averageAmount.mul(hash.valueCount).add(amount).div(hash.valueCount.add(1));
        }

        // recalculate average value using new value from sender and according to its weight (amount)
        if (hash.averageValue == 0) {
            hash.averageValue = value;
        } else {
            /* Recalculate average value.

            Take in count different validation peer weights.

                averageValue = (
                    averageValue * valueCount * averageAmount + (value * amount)
                ) / (valueCount + 1) * averageAmount
            */
            hash.averageValue = uint32(
                hash.valueCount.mul(
                    hash.averageValue
                ).mul(
                    hash.averageAmount
                ).add(
                    amount.mul(value)
                ).div(
                    hash.valueCount.add(1).mul(hash.averageAmount)
                )
            );
        }

        // increment value samples counter
        hash.valueCount = hash.valueCount.add(1);

        hashes[dataHash] = hash;
        hasVerify[msg.sender][dataHash] = true;

        // emit event
        emit Verify(dataHash, msg.sender, amount, value);
    }

    /* Reject content hash provided by peer.

    Rejection counted by tokens amount sender owns.
    */
    function reject(bytes32 dataHash) public {
        uint256 amount = sarafanContract.balanceOf(msg.sender);
        require(amount >= 10000000, "Only owners of 10M tokens can reject contentHash");
        require(hasVerify[msg.sender][dataHash] == false, "Already verified");
        hashes[dataHash].rejects = hashes[dataHash].rejects.add(amount);
        hasVerify[msg.sender][dataHash] = true;
        emit Reject(dataHash, msg.sender, amount);
    }

    /* Payout to peer for storage.

    Payout amount is calculated as:

    amount = (size / 1,000,000) * PRICE * (timeInterval / 30 / 24) * averageValue

    where:
     - PRICE is megabyte month cost of parent contract.
     - 1,000,000 — conversion from bytes to megabytes
     - 30 / 24 - number of hours in 30d month
    */
    function payout(bytes32 dataHash, address payoutAddress) public {
        HashInfo memory hashInfo = hashes[dataHash];

        // Check preconditions
        require(hashInfo.author == msg.sender, "Only hash creator can request payout");
        if (waitPayout) {
            require(block.timestamp >= hashInfo.commitTime + 7 days,
                    "Need to wait 7 days before payout");
        }
        require(hashInfo.verifies > hashInfo.rejects,
                "Amount of verifies should be greater than amount of rejects to payout.");

        // base amount is a month of storage of committed data
        uint256 amount = hashInfo.size.mul(sarafanContract.megabyteMonthCost()).div(1000000);
        // 720 is a number of hours in a 30 days long month.
        amount = amount.mul(hashInfo.timeInterval).div(720);
        // multiply by average verified value
        amount = amount.mul(hashInfo.averageValue);
        // divide to maximum possible value
        amount = amount.div(100000);

        sarafanContract.transfer(payoutAddress, amount);
        emit Payout(dataHash, payoutAddress, amount);
    }

    function setWaitPayout(bool value) public {
        require(msg.sender == contractOwner, "Only for testing");
        waitPayout = value;
    }
}
