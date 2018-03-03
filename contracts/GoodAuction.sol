pragma solidity 0.4.19;

import "./AuctionInterface.sol";
import "./SafeMath.sol";

/** @title GoodAuction */
contract GoodAuction is AuctionInterface {
	using SafeMath for uint256;

	event Transfer(uint256 amount, address from, address to);
	event Bid(string msg, address lastBidder, uint256 amount, uint256 prevHighestBid, address prevHighestBidder);
	event Log(address highestBidder, address calling);

	/* New data structure, keeps track of refunds owed */
	mapping(address => uint) refunds;

	/* 	Bid function, now shifted to pull paradigm
		Must return true on successful send and/or bid, bidder
		reassignment. Must return false on failure and
		allow people to retrieve their funds  */
	function bid() payable external returns(bool) {
		if (msg.value > highestBid) {
			if (highestBid != 0) {
			  /* highestBidder.transfer(highestBid); */
				refunds[highestBidder] += highestBid;
				Transfer(highestBid, this, highestBidder);
			}

			Bid('New Highest Bidder', msg.sender, msg.value, highestBid, highestBidder);
			highestBid = msg.value;
			highestBidder = msg.sender;

			return true;
		} else {
			/* require(msg.sender.send(msg.value)); */
			refunds[msg.sender] += msg.value;

			Bid('Bid was too low', msg.sender, msg.value, highestBid, highestBidder);
			return false;
		}
	}

	/*  Implement withdraw function to complete new
	    pull paradigm. Returns true on successful
	    return of owed funds and false on failure
	    or no funds owed.  */
	function withdrawRefund() external returns(bool) {
		if (!msg.sender.send(refunds[msg.sender]) || refunds[msg.sender] == 0) {
			return false;
		}
		msg.sender.transfer(refunds[msg.sender]);
		return true;
	}

	/*  Allow users to check the amount they are owed
		before calling withdrawRefund(). Function returns
		amount owed.  */
	function getMyBalance() constant external returns(uint) {
		return refunds[msg.sender];
	}


	/* 	Consider implementing this modifier
		and applying it to the reduceBid function
		you fill in below. */
	modifier canReduce {
		/* require(msg.sender == highestBidder); */
		_;
	}


	/*  Rewrite reduceBid from BadAuction to fix
		the security vulnerabilities. Should allow the
		current highest bidder only to reduce their bid amount */
	function reduceBid() external {
		Log(highestBidder, msg.sender);

		if (highestBid > 0 && msg.sender == highestBidder) {
				highestBid = highestBid.sub(1);
				highestBidder.transfer(1);
		}
	}


	/* 	Remember this fallback function
		gets invoked if somebody calls a
		function that does not exist in this
		contract. But we're good people so we don't
		want to profit on people's mistakes.
		How do we send people their money back?  */

	function () payable {
		refunds[msg.sender] += msg.value;
	}

}
