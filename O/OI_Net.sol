// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract NetOpenInterest {
    struct Market { string symbol; int256 netOI; bool exists; }
    uint256 public nextId=1;
    mapping(uint256=>Market) public mkt;
    mapping(bytes32=>uint256) public idBySym;

    event MarketCreated(uint256 id,string sym);
    event Position(address indexed t,uint256 id,int256 delta,int256 newNet);

    function addMarket(string calldata sym) external returns(uint256 id){
        bytes32 h=keccak256(bytes(sym)); require(idBySym[h]==0,"exists");
        id=nextId++; mkt[id]=Market(sym,0,true); idBySym[h]=id; emit MarketCreated(id,sym);
    }

    function update(int256 delta,uint256 id) external {
        Market storage m=mkt[id]; require(m.exists,"bad");
        m.netOI += delta;         // long = +, short = -
        emit Position(msg.sender,id,delta,m.netOI);
    }
}
