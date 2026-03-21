# Web3-Security-Lab-AI-Assisted

Ethernaut Levels

. . . _______________________________________________ . . .

Level 01: Fallback
    Vulnerability Category: Broken Access Control / Logic Flaw
    Severity: Critical | Likelihood: High
    
    Description: The contract contains a logic flaw in the receive() fallback function. It allows any user to claim ownership (owner = msg.sender) as long as they have a non-zero contribution. The contribute() function, while intended to gatekeep ownership, fails to protect the state against this implicit transition.
    
    Attack Vector: 1. Call contribute() with a small amount of ETH to satisfy the contributions[msg.sender] > 0 check.

    Trigger the receive() function by sending 1 wei directly to the contract.
    
    Execute withdraw() as the new owner to drain the contract balance.
    
    AI Insight (Claude 3.5): Used Claude to map the state transitions. The AI identified that the receive() function acts as a "backdoor" that bypasses the intended $1000$ ETH requirement for ownership change.

    Remediation: Remove ownership transfer logic from fallback functions. Implement a dedicated, highly secure administrative transition mechanism.

. . . _______________________________________________ . . .

Level 02: Fallout
    Vulnerability Category: Deprecated Constructor Pattern / Access Control
    Severity: Critical | Likelihood: High
    
    Description: This is a classic example of a "typo-based" vulnerability. The function intended to be the constructor (Fal1out) is misnamed (notice the '1' instead of 'l'), making it a public, callable function instead of a one-time initialization block.

    Attack Vector: 1. Call the public function Fal1out() directly.
    
    The contract assigns msg.sender as the owner.
    Unauthorized access to all onlyOwner functions is granted.

    AI Insight (Cursor): Cursor's symbol search immediately flagged that Fal1out was not being treated as a constructor by the compiler, but as a standard public function, highlighting the lack of access modifiers.

    Remediation: Use the constructor keyword (introduced in Solidity 0.4.22) instead of naming the function after the contract. Always use static analysis tools like Slither to detect naming mismatches.

. . . _______________________________________________ . . .

Level 03: Coin Flip
    Vulnerability Category: Insecure Randomness / Deterministic Entropy

    Severity: High | Likelihood: High

    Description: The contract attempts to generate randomness using on-chain data (blockhash and block.number). Since the Ethereum blockchain is deterministic, any attacker can calculate the "random" result in the same block and submit the correct guess with 100% certainty.

    Attack Vector: 1. Deploy a malicious "Attacker" contract.
    
    In the attack function, replicate the logic: uint256 blockValue = uint256(blockhash(block.number - 1)).
    
    Calculate the side (blockValue / FACTOR) and call flip() on the original contract with the pre-calculated answer.

    AI Insight (Claude 3.5): I tasked the AI with writing a Foundry PoC that simulates a 10-win streak. The AI correctly identified that blockhash for the current block is not available (returns 0), requiring the use of block.number - 1.

    Remediation: Never use on-chain variables for randomness. Integrate a Chainlink VRF (Verifiable Random Function) or other off-chain oracle solutions to ensure cryptographically secure entropy.

    . . . _______________________________________________ . . .