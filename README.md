# 🏛️⚡️ Spark Gov Relay 🏛️⚡️
This repository contains infrastructure necessary to process cross-chain execution of governance proposals.

The codebase uses [Foundry](https://github.com/foundry-rs/foundry) as the development framework. In order to run tests, deploy contracts, or perform other operations, use standard [Foundry](https://github.com/foundry-rs/foundry) commands.

## ⚙️ Components
### 🚦 Executors
Executors serve as admins of the bridged domain instances of the protocol. <br>They are responsible for storying the queue of proposals passed from the host domain governance and their execution. <br> They manage bridged domain protocol instance using standard payload pattern.
## ✍️ Architecture Diagram
![Architecture Diagram](/diagram.png)
## 🤝 Contribution Guidelines
In order to add governance relay infrastructure for a new domain, perform the following steps:
1. Go to [XChain Helpers](https://github.com/marsfoundation/xchain-helpers) repository and complete the process for adding a new domain.
2. Add a new test file for your domain to the `/test` directory. Inherit `CrosschainTestBase` and add tests specific to your domain to the test suite. All of the tests have to pass. Follow linting and naming convention used in other test files.
3. Use proper labeling for your open PR (always set adequate priority and status)
4. Get an approving review from at least one of three designated reviewers - **@hexonaut**, **@lucas-manuel** or **@barrutko**
5. Enjoy governance messages being passed through the bridge to your domain! 🎉

## Audits

Audit reports are hosted on the auditors' public portfolio pages:

| Auditor | Report | Version | Date |
| --- | --- | --- | --- |
| ChainSecurity | [Sky Governance Relay](https://www.chainsecurity.com/security-audit/sky-governance-relay/) | - | 2026-08-21 |
| Cantina | [Sky: Stars LZ Governance](https://cantina.xyz/portfolio/3369b702-f6e2-4c17-b6e1-1ff34953e68a) | - | 2026-08-19 |
| Cantina | [xchain-helpers; spark-gov-relay](https://cantina.xyz/portfolio/854c4127-0cdc-4712-be6b-60d0c01f1a54) | v1.0.1 | 2024-08-20 |
| ChainSecurity | [SparkDAO Governance Relay](https://www.chainsecurity.com/security-audit/sparkdao-governance-relay/) | v1.0.0 | 2024-07-31 |

ChainSecurity reports are cumulative: each portfolio page hosts the latest version of the report, which covers all previously reviewed versions.
