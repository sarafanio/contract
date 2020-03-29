pragma solidity ^0.6.3;

import './Math.sol';
import { SarafanToken } from './SarafanToken.sol';


contract SarafanContent {
    using SafeMath for uint256;

    SarafanToken public sarafanContract;

    // map publication magnet to reward address
    mapping (bytes32 => address) private rewardAddresses;

    /* Publication event.

    Clients should read such events to discover new publications.

    Nodes uses such events to download matching paid content and verify direct uploads.

    - `replyTo` — magnet of parent publication or 0x0 if it is a root publication
    - `magnet` - publication magnet (content file keccak256 hash)
    - `source` — content publisher, sender address of post method invocation
    - `size` — reported size of the content
    - `retention` — number of initially paid months of storage
    */
    event Publication(bytes32 indexed replyTo, bytes32 indexed magnet, address source, uint256 size, uint32 retention);

    /* Award event.

    Users can award publication author and increase publication retention time.

    - `magnet` - magnet to award
    - `source` - awarder
    - `amount` - number of SRFN tokens to award
    */
    event Award(bytes32 indexed magnet, address source, uint256 amount);

    /* Abuse event.

    Any user owning more than 100k SRFN can abuse content for some reason.
    Clients may want to follow such abuses from certain or from all source
    by their choice.

    - `magnet` - abused publication magnet
    - `source` - abuse sender
    - `reason` - ascii encoded short reason
    */
    event Abuse(bytes32 indexed magnet, address source, bytes32 reason);

    /* Contract constructor.

    Sarafan token contract address required.
    */
    constructor(address payable parent) public {
        sarafanContract = SarafanToken(parent);
    }

    /** Send publication to registry.

    Sender should approve spending SRFN amounts to this contract before post.

    Publication fee is based on content size and also includes fixed 1SRFN developers fee.

    Params:
    - `replyTo` — magnet of parent publication or 0x0 if it is a root publication
    - `magnet` - current publication magnet (content file keccak256 hash)
    - `size` — reported size of the content (content will be rejected by nodes if size didn't match)
    - `author` — publication author address (will be used for awards)
    - `retention` — number of paid storage months
    */
    function post(bytes32 replyTo, bytes32 magnet, uint256 size, address author, uint32 retention) public {
        require(size <= 10000000, "Content size should be less than 10Mb");
        require(rewardAddresses[magnet] == address(0), "Such magnet already published");
        require(sarafanContract.peeringContract() != address(0), "Peering contract is not initialized yet");

        // storage fee is calculated as size / 1,000,000 * retention
        uint256 storageFee = size.mul(sarafanContract.megabyteMonthCost()).mul(retention).div(1000000);

        // minimal storage fee is 1 SRFN
        if (storageFee < 1) {
            storageFee = 1;
        }
        sarafanContract.transferFrom(msg.sender, sarafanContract.peeringContract(), storageFee);

        // 1 SRFN fixed owner fee
        sarafanContract.transferFrom(msg.sender, sarafanContract.contractOwner(), 1);

        emit Publication(replyTo, magnet, msg.sender, size, retention);
        rewardAddresses[magnet] = author;
    }

    /* Shortcut for posting new publication with retention of 12 months.
    */
    function post(bytes32 magnet, uint32 size) public {
        post(0x0, magnet, size, msg.sender, 12);
    }

    /* Shortcut for posting replies/updates/comments to original post with retention of 12 months.
    */
    function post(bytes32 replyTo, bytes32 magnet, uint32 size) public {
        post(replyTo, magnet, size, msg.sender, 12);
    }

    /* Award publication by magnet.

    Award amount is split between author and peering network as 1:1.

    Sender should approve SRFN spending for contract before award.

    - `magnet` — publication magnet to award
    - `amount` - number of SRFN tokens to award
    */
    function award(bytes32 magnet, uint256 amount) public {
        require(amount >= 2, "Like amount should be greater than 2");
        address rewardAddress = rewardAddresses[magnet];
        // revert if there is no reward address for magnet
        require(rewardAddress != address(0), "Magnet not registered");

        if (sarafanContract.peeringContract() != address(0)) {
            uint256 splitAmount = amount.div(2);
            uint256 reminder = amount - (splitAmount * 2);
            uint256 authorAmount = splitAmount + reminder;

            // Author reward
            sarafanContract.transferFrom(msg.sender, rewardAddress, authorAmount);
            // Peering network reward
            sarafanContract.transferFrom(msg.sender, sarafanContract.peeringContract(), splitAmount);
        } else {
            // Send all reward to author if there is not peering contract.
            sarafanContract.transferFrom(msg.sender, rewardAddress, amount);
        }

        emit Award(magnet, msg.sender, amount);
    }

    /* Send abuse for publication by magnet.

    Can be invoked for 50 SRFN by accounts owning more than 100k of SRFN tokens.

    - `magnet` — publication magnet to abuse
    - `reason` - ascii encoded abuse reason
    */
    function abuse(bytes32 magnet, bytes32 reason) public {
        require(sarafanContract.balanceOf(msg.sender) >= 100000, "100k tokens required for abuse");
        // system fee for abuse is 50 SRFN
        sarafanContract.transferFrom(msg.sender, sarafanContract.contractOwner(), 50);
        emit Abuse(magnet, msg.sender, reason);
    }
}
