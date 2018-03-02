pragma solidity ^0.4.10;

import "./ContinuousToken.sol";

/*
DO NOT USE. This is a still a WIP.

Code is MIT licensed.ER
*/

/*
Implements a continuous token that can be bonded to curators and subtopic for curation.
*/
contract CurationToken is ContinuousToken {

    //token holder -> curator -> sub-topic -> amount
    mapping (address => mapping (address => mapping(string => uint256)))  bonds;
    mapping (address => mapping(string => uint256)) totalBondsPerCuratorPerSubtopic;

    uint256 public totalBonded = 0;

    //main topic. eg #truffle. Hardcoded.
    //sub topics examples = #truffle.features or #truffle.pullrequests
    string topic;

    function CurationToken(uint8 _decimals, string _symbol, string _name, string _topic) ContinuousToken(_decimals, _symbol, _name) {
        topic = _topic;
    }

    function bond(address _curator, string _subtopic, uint256 _amount) returns (bool) {
        if(balances[msg.sender] >= _amount) {
            bonds[msg.sender][_curator][_subtopic] += _amount;
            balances[msg.sender] -= _amount;
            totalBonded += _amount;
            totalBondsPerCuratorPerSubtopic[_curator][_subtopic] += _amount;
            LogBond(msg.sender, _curator, _subtopic, _amount);
            return true;
        } else {
            return false;
        }
    }

    function withdrawBond(address _curator, string _subtopic, uint256 _amount) returns (bool) {
        if(bonds[msg.sender][_curator][_subtopic] >= _amount) {
            bonds[msg.sender][_curator][_subtopic] -= _amount;
            balances[msg.sender] += _amount;
            totalBonded -= _amount;
            totalBondsPerCuratorPerSubtopic[_curator][_subtopic] -= _amount;
            LogWithdrawBond(msg.sender, _curator, _subtopic, _amount);
            return true;
        } else {
            return false;
        }
    }

  function getTotalBondsPerCuratorPerSubtopic(address _curator, string _subtopic) returns(uint256){
      return totalBondsPerCuratorPerSubtopic[_curator][_subtopic];
    }

    event LogBond(address indexed holder, address curator, string subtopic, uint256 amount);
    event LogWithdrawBond(address indexed holder, address curator, string subtopic, uint256 amount);

}
