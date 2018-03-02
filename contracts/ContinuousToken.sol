pragma solidity ^0.4.10;

import "./ERC20Token.sol";

/*
DO NOT USE. This is a still a WIP.

Code is MIT licensed.
*/

/*
Continuous Token is about the minting/withdrawing of the curation market.
It allows tokens to be minted, the ETH kept in a pool, and then withdrawn from supply.
This can be re-used without the bonding functionality.
*/
contract ContinuousToken is ERC20Token {

    uint public constant MAX_UINT = (2**256) - 1;

    uint256 baseCost = 100000000000000; //100000000000000 wei 0.0001 ether
    uint256 public costPerToken = 0;

    uint256 public totalEverMinted;
    uint256 public totalEverWithdrawn;
    uint256 public poolBalance;

    uint8 decimals;
    string symbol;
    string name;

    function ContinuousToken(uint8 _decimals, string _symbol, string _name) {
        decimals = _decimals;
        symbol = _symbol;
        name = _name;
        // this make the deployment runs out of gas (investigation needed)
        // updateCostOfToken(0); //first pass
        // so following the formula:
        // costOfToken = (BaseCost + BaseCost*(1.000001618^AvailableSupply)+BaseCost*AvailableSupply/1000)
        // with initial AvailableSupply = 0 then:
        costPerToken = 2 * baseCost;
    }

    // via: http://ethereum.stackexchange.com/questions/10425/is-there-any-efficient-way-to-compute-the-exponentiation-of-a-fraction-and-an-in/10432#10432
    // Computes `k * (1+1/q) ^ N`, with precision `p`. The higher
    // the precision, the higher the gas cost. It should be
    // something around the log of `n`. When `p == n`, the
    // precision is absolute (sans possible integer overflows).
    // Much smaller values are sufficient to get a great approximation.
    function fracExp(uint k, uint q, uint n, uint p) internal returns (uint) {
      uint s = 0;
      uint N = 1;
      uint B = 1;
      for (uint i = 0; i < p; ++i){
        s += k * N / B / (q**i);
        N  = N * (n-i);
        B  = B * (i+1);
      }
      return s;
    }

    function updateCostOfToken(uint256 _supply) internal {
        //from protocol design:
        //costOfCoupon = (BaseCost + BaseCost*(1.000001618^AvailableSupply)+BaseCost*AvailableSupply/1000)
        //totalSupply == AvailableSupply
        costPerToken = baseCost+fracExp(baseCost, 618046, _supply, 2)+baseCost*_supply/1000;
        LogCostOfTokenUpdate(costPerToken);
    }

    //mint
    function mint(uint256 _amountToMint) payable returns (bool) {
        //balance of msg.sender increases if paid right amount according to protocol

        if(_amountToMint > 0 && (MAX_UINT - _amountToMint) >= totalSupply && msg.value > 0) {

            uint256 totalMinted = 0;
            uint256 totalCost = 0;
            //for loop to determine cost at each point.
            for(uint i = 0; i < _amountToMint; i+=1) {
                if(totalCost + costPerToken <= msg.value) {
                    totalCost += costPerToken;
                    totalMinted += 1;
                    updateCostOfToken((totalSupply+i));
                } else {
                    break;
                }
            }

            if(totalCost < msg.value) { //some funds left, not enough for one token. Send back funds
                msg.sender.transfer(msg.value - totalCost);
            }

            totalEverMinted += totalMinted;
            totalSupply += totalMinted;
            balances[msg.sender] += totalMinted;
            poolBalance += totalCost;

            LogMint(totalMinted, totalCost);

            return true;
        } else {
            throw;
        }
    }

    function withdraw(uint256 _amountToWithdraw) returns (bool) {
        if(_amountToWithdraw > 0 && balances[msg.sender] >= _amountToWithdraw) {
            //determine how much you can leave with.
            uint256 reward = _amountToWithdraw * poolBalance/totalSupply; //rounding?
            msg.sender.transfer(reward);
            balances[msg.sender] -= _amountToWithdraw;
            totalSupply -= _amountToWithdraw;
            updateCostOfToken(totalSupply);
            LogWithdraw(_amountToWithdraw, reward);
            return true;
        } else {
            throw;
        }
    }

    event LogMint(uint256 amountMinted, uint256 totalCost);
    event LogWithdraw(uint256 amountWithdrawn, uint256 reward);
    event LogCostOfTokenUpdate(uint256 newCost);
}
