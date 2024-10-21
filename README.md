# P2P Escrow Exchange Smart Contract

This project implements a peer-to-peer escrow exchange system using a Clarity smart
contract. It allows users to create escrows, release funds, and process refunds in a
decentralized manner.

## Table of Contents
- [Setup](#setup)
- [Usage](#usage)
- [Testing](#testing)
- [Contributing](#contributing)
- [License](#license)

## Setup

1. Install Clarinet:
   Follow the instructions at https://github.com/hirosystems/clarinet to install
   Clarinet on your system.

2. Clone the repository:
   ```
   git clone https://github.com/yourusername/p2p-escrow-project.git
   cd p2p-escrow-project
   ```

3. Initialize the Clarinet project:
   ```
   clarinet initialize
   ```

## Usage

The smart contract provides the following main functions:

1. `create-escrow`: Create a new escrow between a seller and a buyer.
2. `release-escrow`: Release funds to the seller, completing the transaction.
3. `refund-escrow`: Refund the buyer, canceling the transaction.
4. `get-escrow`: Retrieve details of a specific escrow.

To interact with the contract using Clarinet:

1. Start a Clarinet console:
   ```
   clarinet console
   ```

2. Use the contract functions. For example:
   ```clarity
   (contract-call? .p2p-escrow-exchange create-escrow 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM u1000)
   ```

## Testing

To run the built-in tests:

1. Ensure you're in the project directory.
2. Run the Clarinet test command:
   ```
   clarinet test
   ```

This will execute all the test functions defined in the contract.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License.