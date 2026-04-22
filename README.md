# Web3-Security-Lab-AI-Assisted

Ethernaut Levels

. . . _______________________________________________ . . .

Level 01: Fallback
    Vulnerability Category: Broken Access Control / Logic Flaw |Severity: Critical | Likelihood: High
    
    Description: The contract contains a logic flaw in the receive() fallback function. It allows any user to claim ownership (owner = msg.sender) as long as they have a non-zero contribution. The contribute() function, while intended to gatekeep ownership, fails to protect the state against this implicit transition.
    
    Attack Vector: 1. Call contribute() with a small amount of ETH to satisfy the contributions[msg.sender] > 0 check.

    Trigger the receive() function by sending 1 wei directly to the contract.
    
    Execute withdraw() as the new owner to drain the contract balance.
    
    AI Insight (Claude 3.5): Used Claude to map the state transitions. The AI identified that the receive() function acts as a "backdoor" that bypasses the intended $1000$ ETH requirement for ownership change.

    Remediation: Remove ownership transfer logic from fallback functions. Implement a dedicated, highly secure administrative transition mechanism.

🛡️ Vulnerability: Logic Flaws in Fallback Functions
The vulnerability lies in the receive() function (or a fallback() function). In this contract, the logic to change the owner is hidden inside the function that handles direct Ether transfers.

How the attack works:

Contribution: The attacker first calls contribute() sending a tiny amount of ETH (e.g., 0.0001 ETH). This satisfies the requirement contributions[msg.sender] > 0.

Triggering the Fallback: The attacker sends ETH directly to the contract address (without calling any specific function). This triggers the receive() function.

Takeover: The receive() function checks if the sender has contributed before and if the sent value is > 0. Since both are true, it executes owner = msg.sender.

Drain: Once the attacker is the owner, they call withdraw() to steal all funds.

🛠️ Remediation: Secure Access Control
Explicit Ownership Transfer: Never allow ownership to be claimed through a fallback or receive function. Ownership changes should be handled by explicit, protected functions (e.g., transferOwnership).

Use OpenZeppelin Ownable: Use battle-tested libraries like OpenZeppelin's Ownable.sol.

Fallback Best Practices: Keep fallback and receive functions as simple as possible. They should generally only be used for logging or basic ETH reception, not for critical state changes.

. . . _______________________________________________ . . .

Level 02: Fallout
    Vulnerability Category: Deprecated Constructor Pattern / Access Control |
    Severity: Critical | Likelihood: High
    
    Description: This is a classic example of a "typo-based" vulnerability. The function intended to be the constructor (Fal1out) is misnamed (notice the '1' instead of 'l'), making it a public, callable function instead of a one-time initialization block.

    Attack Vector: 1. Call the public function Fal1out() directly.
    
    The contract assigns msg.sender as the owner.
    Unauthorized access to all onlyOwner functions is granted.

    AI Insight (Cursor): Cursor's symbol search immediately flagged that Fal1out was not being treated as a constructor by the compiler, but as a standard public function, highlighting the lack of access modifiers.

    Remediation: Use the constructor keyword (introduced in Solidity 0.4.22) instead of naming the function after the contract. Always use static analysis tools like Slither to detect naming mismatches.

    
🛡️ Vulnerability: Misnamed Constructor (Typos)
This is a classic "legacy" vulnerability. In older versions of Solidity (prior to 0.4.22), the constructor was a function with the exact same name as the contract.

In this level, the contract is named Fallout, but the function intended to be the constructor is named Fal1out (with a "1" instead of an "l").

How the attack works:

Public Function: Because of the typo, Fal1out() is treated as a regular public function instead of a constructor that runs only once at deployment.

Claiming Ownership: Anyone can call Fal1out() at any time.

Takeover: When the attacker calls contract.Fal1out(), the function executes owner = msg.sender, granting full control of the contract to the caller.

🛠️ Remediation: Modern Constructor Syntax
Use the constructor Keyword: Since Solidity 0.4.22, the language introduced the constructor keyword. This makes it impossible to accidentally create a public function instead of a constructor due to a typo.

Compiler Warnings: Modern compilers (and tools like Slither) will issue a warning if a public function has a name very similar to the contract name. Always pay attention to compiler warnings.

Static Analysis: Use tools like Slither or Aderyn in your CI/CD pipeline. They catch these "low-hanging fruit" vulnerabilities instantly.

. . . _______________________________________________ . . .

Level 03: Coin Flip
    Vulnerability Category: Insecure Randomness / Deterministic Entropy | Severity: High | Likelihood: High

    Description: The contract attempts to generate randomness using on-chain data (blockhash and block.number). Since the Ethereum blockchain is deterministic, any attacker can calculate the "random" result in the same block and submit the correct guess with 100% certainty.

    Attack Vector: 1. Deploy a malicious "Attacker" contract.
    
    In the attack function, replicate the logic: uint256 blockValue = uint256(blockhash(block.number - 1)).
    
    Calculate the side (blockValue / FACTOR) and call flip() on the original contract with the pre-calculated answer.

    AI Insight (Claude 3.5): I tasked the AI with writing a Foundry PoC that simulates a 10-win streak. The AI correctly identified that blockhash for the current block is not available (returns 0), requiring the use of block.number - 1.

 🛡️ Vulnerability: Deterministic Randomness
The core vulnerability in this contract is the use of **on-chain data for randomness generation**. 

In Solidity, variables like `blockhash`, `block.timestamp`, and `block.number` are predictable. In the `CoinFlip` contract, the winning side is calculated using `blockhash(block.number - 1)`. Since this value is public and accessible to any other smart contract in the same block, the "random" result is actually **deterministic**.

**How the attack works:**
1. An attacker creates a malicious contract that replicates the exact same math as the target contract.
2. Because the attacker contract calls the target contract within the **same transaction**, they both share the same `block.number`.
3. The attacker calculates the winning side *before* making the call, ensuring a 100% success rate.

---

 🛠️ Remediation: Verifiable Randomness (VRF)
To fix this, developers should never rely on on-chain data for generating numbers that require high entropy or security.

**The Solution: Chainlink VRF**
The industry standard is to use an external oracle, such as **Chainlink VRF (Verifiable Random Function)**. 

1. **Request:** The contract requests a random number from the oracle.
2. **Off-chain Generation:** The oracle generates a random number and a cryptographic proof.
3. **Verification:** The oracle sends the number back to the smart contract via a callback function. The proof is verified on-chain to ensure the number was not tampered with by the oracle or the miners.


    . . . _______________________________________________ . . .

### Level 04: Telephone
**Vulnerability Category:** Authorization Bypass | **Severity:** Medium | **Likelihood:** High

**Description:** The contract uses `tx.origin` to validate the caller's identity. In Solidity, `tx.origin` refers to the original external account that started the transaction chain, whereas `msg.sender` is the immediate caller.

**Attack Vector:**
1. Create a malicious intermediary contract.
2. The attacker's contract calls the `changeOwner()` function of the victim contract.
3. The victim checks `tx.origin` (the attacker) instead of `msg.sender` (the malicious contract), allowing the ownership change.

**AI Insight:** AI models can quickly flag `tx.origin` as a deprecated security practice. The AI identifies that an intermediary contract acts as a "man-in-the-middle" that satisfies the origin check while hiding the actual logic execution.

**Remediation:** Use `msg.sender` for authorization checks. `tx.origin` should almost never be used for security-critical logic.

  . . . _______________________________________________ . . .

### Level 05: Token
**Vulnerability Category:** Arithmetic Error (Integer Underflow) | **Severity:** High | **Likelihood:** High

**Description:** In Solidity versions $< 0.8.0$, integers do not have built-in overflow/underflow protection. If a user with a balance of $0$ subtracts $1$, the balance "wraps around" to $2^{256} - 1$.

**Attack Vector:**
1. Call the `transfer()` function with a value greater than your current balance.
2. The check `require(balances[msg.sender] - _value >= 0)` passes because the underflow results in a massive positive number.
3. The attacker's balance becomes nearly infinite.

**AI Insight:** The AI detects the lack of `SafeMath` or the use of an old compiler version. It predicts the "wrap-around" effect by simulating a subtraction that exceeds the lower bound of `uint256`.

**Remediation:** Use Solidity $0.8.0$ or higher (which has built-in checks) or the OpenZeppelin `SafeMath` library for older versions.

  . . . _______________________________________________ . . .

### Level 06: Delegation
**Vulnerability Category:** Dangerous Delegatecall | **Severity:** Critical | **Likelihood:** Medium

**Description:** The contract uses `delegatecall` to execute functions from another contract. `delegatecall` runs the code of the target contract but uses the **storage and context** of the calling contract.

**Attack Vector:**
1. The attacker sends a transaction to the `Delegation` contract with `msg.data` set to the function signature of `pwn()`.
2. The `fallback()` function triggers `delegatecall` to the `Delegate` contract.
3. The `pwn()` function executes, but since it's a `delegatecall`, it modifies the `owner` slot of the `Delegation` contract instead of the `Delegate` contract.

**AI Insight:** The AI maps the storage slots of both contracts. It realizes that `delegatecall` is a "double-edged sword" that allows a caller to manipulate the caller's state if the target contract has functions that modify sensitive slots (like slot 0 for `owner`).

**Remediation:** Avoid using `delegatecall` with user-supplied data. Use fixed function calls or strict whitelists for delegate targets.

  . . . _______________________________________________ . . .

### Level 07: Force
**Vulnerability Category:** Logic Flaw / Forced Ether | **Severity:** Medium | **Likelihood:** Low

**Description:** The contract has no `receive()` or `fallback()` functions, making it appear impossible to receive Ether. However, Ether can be forced into any contract.

**Attack Vector:**
1. Create a "suicide" contract with some ETH.
2. Call `selfdestruct(victim_address)`.
3. The EVM forcefully sends the ETH to the victim, bypassing all logic and function checks.

**AI Insight:** The AI highlights that `address(this).balance` is an unreliable state variable for logic, as it can be altered without the contract's "permission" via `selfdestruct` or coinbase rewards.

**Remediation:** Do not rely on `address(this).balance` for critical logic. Use an internal `uint256` state variable to track deposited funds.

  . . . _______________________________________________ . . .

### Level 08: Vault
**Vulnerability Category:** Information Disclosure (Privacy Breach) | **Severity:** High | **Likelihood:** High

**Description:** The contract stores a password in a `private` variable. In blockchain, `private` only means other contracts cannot read it; however, all data is public on the ledger.

**Attack Vector:**
1. Use a web3 provider (like Ethers.js) to call `getStorageAt(contract_address, slot_index)`.
2. Read the hex value directly from the contract's storage slot.
3. Use the retrieved password to call `unlock()`.

**AI Insight:** The AI identifies that "Private != Secret". It flags that the storage layout of the EVM is transparent and that any off-chain entity can inspect the state of any variable.

**Remediation:** Never store sensitive plaintext data (passwords, keys) on-chain. Use hashes (Keccak256) or Zero-Knowledge Proofs if data verification is needed without disclosure.

  . . . _______________________________________________ . . .

### Level 09: King
**Vulnerability Category:** Denial of Service (DoS) | **Severity:** High | **Likelihood:** Medium

**Description:** A contract acts as a "King of the Hill". To become the new king, you send more ETH than the current one. The contract then sends the previous king's ETH back to them.

**Attack Vector:**
1. The attacker becomes the king using a contract that **refuses to receive ETH** (no `receive()` function or a `revert()` in the fallback).
2. When a new person tries to become king, the victim contract tries to pay the attacker.
3. The transfer fails, the transaction reverts, and the attacker remains king forever, breaking the game.

**AI Insight:** The AI recognizes a "Pull-over-Push" violation. It flags that external calls to untrusted addresses can fail and halt the entire execution flow of the contract.



**Remediation:** Implement a "Withdrawal Pattern" (Pull). Instead of sending ETH automatically, let users claim their funds in a separate transaction.

  . . . _______________________________________________ . . .

### Level 10: Reentrancy
**Vulnerability Category:** Reentrancy | **Severity:** Critical | **Likelihood:** Medium

**Description:** The contract follows a "Check-Interact-Update" pattern instead of "Check-Update-Interact". It sends ETH before updating the user's balance.

**Attack Vector:**
1. The attacker contract calls `withdraw()`.
2. The victim contract sends ETH to the attacker.
3. The attacker's `receive()` function calls `withdraw()` again **before** the victim updates the balance to zero.
4. This loop continues until the victim contract is drained.

**AI Insight:** The AI detects the recursive call potential. It identifies that the state change (balance update) happens after the external call, creating a window of inconsistency that can be exploited by a malicious receiver.

**Remediation:** 1. Use the **Checks-Effects-Interactions** pattern (update state before calling). 
2. Use a `ReentrancyGuard` modifier (mutex) from OpenZeppelin.
